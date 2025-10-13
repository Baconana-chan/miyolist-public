import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/theme/app_theme.dart';
import 'custom_lists_dialog.dart';

class EditEntryDialog extends StatefulWidget {
  final MediaListEntry entry;
  final bool isAnime;
  final Function(MediaListEntry) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToFavorites;
  final String? mediaStatus; // FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED

  const EditEntryDialog({
    super.key,
    required this.entry,
    required this.isAnime,
    required this.onSave,
    this.onDelete,
    this.onAddToFavorites,
    this.mediaStatus,
  });

  @override
  State<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  late String _status;
  late double _score;
  late int _progress;
  late int _progressVolumes;
  late int _repeat;
  late TextEditingController _notesController;
  DateTime? _startDate;
  DateTime? _completedDate;
  late List<String> _customLists;

  final List<String> _animeStatuses = [
    'CURRENT',      // Watching
    'PLANNING',     // Plan to Watch
    'COMPLETED',    // Completed
    'PAUSED',       // Paused
    'DROPPED',      // Dropped
    'REPEATING',    // Rewatching
  ];

  final List<String> _mangaStatuses = [
    'CURRENT',      // Reading
    'PLANNING',     // Plan to Read
    'COMPLETED',    // Completed
    'PAUSED',       // Paused
    'DROPPED',      // Dropped
    'REPEATING',    // Rereading
  ];

  /// Get available statuses based on media release status
  List<String> _getAvailableStatuses() {
    final baseStatuses = widget.isAnime ? _animeStatuses : _mangaStatuses;
    final mediaStatus = widget.mediaStatus;

    // If no media status provided, return all statuses
    if (mediaStatus == null) return baseStatuses;

    switch (mediaStatus) {
      case 'NOT_YET_RELEASED': // Анонсировано - только запланировать
        return ['PLANNING'];
      
      case 'RELEASING': // Онгоинг - запланировать, смотрю/читаю, пауза, дроп
        return [
          'PLANNING',
          'CURRENT',
          'PAUSED',
          'DROPPED',
        ];
      
      case 'FINISHED': // Завершено - все статусы доступны
        return baseStatuses;
      
      case 'CANCELLED': // Отменено - только запланировать и дроп
        return ['PLANNING', 'DROPPED'];
      
      default:
        return baseStatuses;
    }
  }

  /// Get hint text based on media status
  String _getStatusHint() {
    final mediaStatus = widget.mediaStatus;
    if (mediaStatus == null) return '';

    switch (mediaStatus) {
      case 'NOT_YET_RELEASED':
        return 'This title hasn\'t been released yet. You can only plan to watch it.';
      case 'RELEASING':
        return 'This title is currently airing. Completed and Rewatching are unavailable.';
      case 'CANCELLED':
        return 'This title was cancelled. Limited statuses available.';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _status = widget.entry.status;
    
    // Validate status against available statuses
    final availableStatuses = _getAvailableStatuses();
    if (!availableStatuses.contains(_status)) {
      // If current status is not available, default to PLANNING
      _status = 'PLANNING';
    }
    
    _score = widget.entry.score ?? 0;
    _progress = widget.entry.progress;
    _progressVolumes = widget.entry.progressVolumes ?? 0;
    _repeat = widget.entry.repeat ?? 0;
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _startDate = widget.entry.startedAt;
    _completedDate = widget.entry.completedAt;
    _customLists = List.from(widget.entry.customLists ?? []);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatStatus(String status) {
    if (widget.isAnime) {
      switch (status) {
        case 'CURRENT':
          return 'Watching';
        case 'PLANNING':
          return 'Plan to Watch';
        case 'COMPLETED':
          return 'Completed';
        case 'PAUSED':
          return 'Paused';
        case 'DROPPED':
          return 'Dropped';
        case 'REPEATING':
          return 'Rewatching';
        default:
          return status;
      }
    } else {
      switch (status) {
        case 'CURRENT':
          return 'Reading';
        case 'PLANNING':
          return 'Plan to Read';
        case 'COMPLETED':
          return 'Completed';
        case 'PAUSED':
          return 'Paused';
        case 'DROPPED':
          return 'Dropped';
        case 'REPEATING':
          return 'Rereading';
        default:
          return status;
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_completedDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentRed,
              onPrimary: AppTheme.textWhite,
              surface: AppTheme.cardGray,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _completedDate = picked;
        }
      });
    }
  }

  void _saveEntry() {
    final updatedEntry = widget.entry.copyWith(
      status: _status,
      score: _score > 0 ? _score : null,
      progress: _progress,
      progressVolumes: !widget.isAnime ? _progressVolumes : null,
      repeat: _repeat,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      startedAt: _startDate,
      completedAt: _completedDate,
      updatedAt: DateTime.now(),
      customLists: _customLists.isNotEmpty ? _customLists : null,
    );

    widget.onSave(updatedEntry);
    Navigator.of(context).pop();
  }

  // TODO: This should fetch custom lists from AniListService
  // For now, we'll allow creating new lists in the dialog
  List<String> _getAllCustomLists() {
    // Return empty list for now - user can create new lists in the dialog
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final mediaTitle = widget.entry.media?.titleRomaji ?? 'Unknown';
    final maxProgress = widget.isAnime
        ? (widget.entry.media?.episodes ?? 0)
        : (widget.entry.media?.chapters ?? 0);
    final maxVolumes = !widget.isAnime
        ? (widget.entry.media?.volumes ?? 0)
        : 0;

    return Dialog(
      backgroundColor: AppTheme.cardGray,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Entry',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mediaTitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textGray,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.secondaryBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: AppTheme.secondaryBlack,
                      items: _getAvailableStatuses()
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(_formatStatus(status)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),

                    // Status hint based on media status
                    if (widget.mediaStatus != null && widget.mediaStatus != 'FINISHED')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _getStatusHint(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade300,
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Score
                    Text(
                      'Score',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _score,
                            min: 0,
                            max: 10,
                            divisions: 20,
                            label: _score == 0 ? '-' : _score.toStringAsFixed(1),
                            activeColor: AppTheme.accentRed,
                            onChanged: (value) {
                              setState(() => _score = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            _score == 0 ? '-' : _score.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Progress
                    Text(
                      widget.isAnime ? 'Episode Progress' : 'Chapter Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _progress > 0
                              ? () => setState(() => _progress--)
                              : null,
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: _progress.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.secondaryBlack,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              suffixText: maxProgress > 0 ? '/ $maxProgress' : null,
                            ),
                            onChanged: (value) {
                              final progress = int.tryParse(value);
                              if (progress != null && progress >= 0) {
                                setState(() => _progress = progress);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _progress++),
                        ),
                        if (maxProgress > 0)
                          TextButton(
                            onPressed: () => setState(() => _progress = maxProgress),
                            child: const Text('Max'),
                          ),
                      ],
                    ),

                    // Volume Progress (только для манги и новелл)
                    if (!widget.isAnime) ...[
                      const SizedBox(height: 20),

                      Text(
                        'Volume Progress',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _progressVolumes > 0
                                ? () => setState(() => _progressVolumes--)
                                : null,
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: _progressVolumes.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.secondaryBlack,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                suffixText: maxVolumes > 0 ? '/ $maxVolumes' : null,
                              ),
                              onChanged: (value) {
                                final volumes = int.tryParse(value);
                                if (volumes != null && volumes >= 0) {
                                  setState(() => _progressVolumes = volumes);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _progressVolumes++),
                          ),
                          if (maxVolumes > 0)
                            TextButton(
                              onPressed: () => setState(() => _progressVolumes = maxVolumes),
                              child: const Text('Max'),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Dates
                    Text(
                      'Dates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _startDate != null
                                  ? DateFormat('MMM d, y').format(_startDate!)
                                  : 'Start Date',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        if (_startDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _startDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _completedDate != null
                                  ? DateFormat('MMM d, y').format(_completedDate!)
                                  : 'Finish Date',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                        if (_completedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _completedDate = null),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Repeat count
                    Text(
                      widget.isAnime ? 'Total Rewatches' : 'Total Rereads',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _repeat > 0
                              ? () => setState(() => _repeat--)
                              : null,
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: _repeat.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.secondaryBlack,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              final repeat = int.tryParse(value);
                              if (repeat != null && repeat >= 0) {
                                setState(() => _repeat = repeat);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _repeat++),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Notes
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add notes...',
                        filled: true,
                        fillColor: AppTheme.secondaryBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Custom Lists
                    Row(
                      children: [
                        Text(
                          'Custom Lists',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        if (_customLists.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_customLists.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<List<String>>(
                          context: context,
                          builder: (context) => CustomListsDialog(
                            initialLists: _customLists,
                            allAvailableLists: _getAllCustomLists(),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _customLists = result;
                          });
                        }
                      },
                      icon: const Icon(Icons.playlist_add),
                      label: Text(_customLists.isEmpty 
                          ? 'Add to Custom Lists' 
                          : 'Manage Custom Lists (${_customLists.join(', ')})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentBlue,
                        side: const BorderSide(color: AppTheme.accentBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.secondaryBlack),
                ),
              ),
              child: Row(
                children: [
                  // Add to Favorites
                  if (widget.onAddToFavorites != null)
                    TextButton.icon(
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Add to Favorites'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentRed,
                      ),
                      onPressed: () {
                        widget.onAddToFavorites!();
                        Navigator.of(context).pop();
                      },
                    ),

                  const Spacer(),

                  // Delete
                  if (widget.onDelete != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.cardGray,
                            title: const Text('Delete Entry'),
                            content: const Text(
                              'Are you sure you want to remove this from your list?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close confirmation
                                  widget.onDelete!();
                                  Navigator.pop(context); // Close edit dialog
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(width: 8),

                  // Cancel
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),

                  const SizedBox(width: 8),

                  // Save
                  ElevatedButton(
                    onPressed: _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: AppTheme.textWhite,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
