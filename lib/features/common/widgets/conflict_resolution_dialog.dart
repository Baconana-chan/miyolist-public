import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/sync_conflict.dart';
import '../../../core/models/media_list_entry.dart';

/// Dialog for manually resolving sync conflicts
class ConflictResolutionDialog extends StatefulWidget {
  final List<SyncConflict> conflicts;
  final Function(List<MediaListEntry> resolvedEntries) onResolve;
  final VoidCallback onCancel;

  const ConflictResolutionDialog({
    super.key,
    required this.conflicts,
    required this.onResolve,
    required this.onCancel,
  });

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  late PageController _pageController;
  int _currentConflictIndex = 0;
  final Map<int, MediaListEntry> _resolutions = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextConflict() {
    if (_currentConflictIndex < widget.conflicts.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentConflictIndex++);
    }
  }

  void _previousConflict() {
    if (_currentConflictIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentConflictIndex--);
    }
  }

  void _selectVersion(MediaListEntry entry) {
    setState(() {
      _resolutions[widget.conflicts[_currentConflictIndex].entryId] = entry;
    });
    
    // Auto-advance to next conflict
    if (_currentConflictIndex < widget.conflicts.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), _nextConflict);
    }
  }

  void _finishResolution() {
    if (_resolutions.length < widget.conflicts.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please resolve all conflicts before continuing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final resolvedList = widget.conflicts
        .map((c) => _resolutions[c.entryId]!)
        .toList();
    
    widget.onResolve(resolvedList);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sync Conflicts Detected',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Conflict ${_currentConflictIndex + 1} of ${widget.conflicts.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Progress indicator
            LinearProgressIndicator(
              value: (_resolutions.length) / widget.conflicts.length,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),

            // Conflict content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.conflicts.length,
                onPageChanged: (index) {
                  setState(() => _currentConflictIndex = index);
                },
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  return _buildConflictView(conflict);
                },
              ),
            ),

            // Navigation buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _currentConflictIndex > 0 ? _previousConflict : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton(
                  onPressed: _resolutions.length == widget.conflicts.length 
                      ? _finishResolution 
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    _resolutions.length == widget.conflicts.length
                        ? 'Apply Changes'
                        : 'Resolve All (${_resolutions.length}/${widget.conflicts.length})',
                  ),
                ),
                TextButton.icon(
                  onPressed: _currentConflictIndex < widget.conflicts.length - 1 
                      ? _nextConflict 
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictView(SyncConflict conflict) {
    final isResolved = _resolutions.containsKey(conflict.entryId);
    final selectedVersion = _resolutions[conflict.entryId];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media info
          Row(
            children: [
              if (conflict.mediaCoverImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    conflict.mediaCoverImage!,
                    width: 60,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 85,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conflict.mediaTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (isResolved)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Resolved',
                            style: TextStyle(color: Colors.green[300]),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${conflict.getConflictingFields().length} conflicting fields',
                        style: const TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Version comparison
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Local version
              Expanded(
                child: _buildVersionCard(
                  title: 'This Device',
                  subtitle: _formatTimestamp(conflict.localMetadata.lastModified),
                  entry: conflict.localVersion,
                  metadata: conflict.localMetadata,
                  isSelected: selectedVersion == conflict.localVersion,
                  onSelect: () => _selectVersion(conflict.localVersion),
                ),
              ),
              const SizedBox(width: 12),
              
              // Cloud version
              Expanded(
                child: _buildVersionCard(
                  title: 'Other Device',
                  subtitle: _formatTimestamp(conflict.cloudMetadata.lastModified),
                  entry: conflict.cloudVersion,
                  metadata: conflict.cloudMetadata,
                  isSelected: selectedVersion == conflict.cloudVersion,
                  onSelect: () => _selectVersion(conflict.cloudVersion),
                ),
              ),
              
              // AniList version (if available)
              if (conflict.isThreeWayConflict) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVersionCard(
                    title: 'AniList',
                    subtitle: _formatTimestamp(conflict.anilistMetadata!.lastModified),
                    entry: conflict.anilistVersion!,
                    metadata: conflict.anilistMetadata!,
                    isSelected: selectedVersion == conflict.anilistVersion,
                    onSelect: () => _selectVersion(conflict.anilistVersion!),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Conflicting fields details
          if (conflict.getConflictingFields().isNotEmpty) ...[
            const Text(
              'Conflicting Fields:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _buildConflictingFieldsTable(conflict),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionCard({
    required String title,
    required String subtitle,
    required MediaListEntry entry,
    required SyncMetadata metadata,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[900],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[800]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSourceIcon(metadata.source),
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.white,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const Divider(height: 16, color: Colors.grey),
            _buildEntryPreview(entry),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryPreview(MediaListEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreviewField('Status', entry.status),
        _buildPreviewField('Score', entry.score?.toString() ?? 'Not set'),
        _buildPreviewField('Progress', '${entry.progress} eps/ch'),
        if (entry.notes != null && entry.notes!.isNotEmpty)
          _buildPreviewField('Notes', entry.notes!, maxLines: 2),
      ],
    );
  }

  Widget _buildPreviewField(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.white),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConflictingFieldsTable(SyncConflict conflict) {
    final fields = conflict.getConflictingFields();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: conflict.isThreeWayConflict
            ? const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(3),
                3: FlexColumnWidth(3),
              }
            : const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(4),
                2: FlexColumnWidth(4),
              },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[850]),
            children: [
              _buildTableCell('Field', isHeader: true),
              _buildTableCell('This Device', isHeader: true),
              _buildTableCell('Other Device', isHeader: true),
              if (conflict.isThreeWayConflict)
                _buildTableCell('AniList', isHeader: true),
            ],
          ),
          // Rows
          ...fields.entries.map((e) {
            final field = e.value;
            return TableRow(
              children: [
                _buildTableCell(field.fieldName),
                _buildTableCell(field.localValue),
                _buildTableCell(field.cloudValue),
                if (conflict.isThreeWayConflict)
                  _buildTableCell(field.anilistValue ?? '-'),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.blue : Colors.white,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  IconData _getSourceIcon(SyncSource source) {
    switch (source) {
      case SyncSource.app:
        return Icons.phone_android;
      case SyncSource.anilist:
        return Icons.language;
      case SyncSource.cloud:
        return Icons.cloud;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
