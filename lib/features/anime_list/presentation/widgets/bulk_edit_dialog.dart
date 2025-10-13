import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum BulkAction {
  changeStatus,
  changeScore,
  delete,
}

class BulkEditDialog extends StatefulWidget {
  final int selectedCount;
  final bool isAnime;

  const BulkEditDialog({
    super.key,
    required this.selectedCount,
    required this.isAnime,
  });

  @override
  State<BulkEditDialog> createState() => _BulkEditDialogState();
}

class _BulkEditDialogState extends State<BulkEditDialog> {
  BulkAction? _selectedAction;
  String? _newStatus;
  double? _newScore;

  final List<String> _statuses = [
    'CURRENT',
    'PLANNING',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'REPEATING',
  ];

  String _formatStatus(String status) {
    switch (status) {
      case 'CURRENT':
        return widget.isAnime ? 'Watching' : 'Reading';
      case 'PLANNING':
        return widget.isAnime ? 'Plan to Watch' : 'Plan to Read';
      case 'COMPLETED':
        return 'Completed';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      case 'REPEATING':
        return widget.isAnime ? 'Rewatching' : 'Rereading';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardGray,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  color: AppTheme.accentBlue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bulk Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.selectedCount} items selected',
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textGray),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action selection
            const Text(
              'Select Action',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // Change Status
            _buildActionCard(
              icon: Icons.autorenew,
              title: 'Change Status',
              description: 'Update status for all selected items',
              isSelected: _selectedAction == BulkAction.changeStatus,
              onTap: () {
                setState(() {
                  _selectedAction = BulkAction.changeStatus;
                  _newScore = null;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Change Score
            _buildActionCard(
              icon: Icons.star,
              title: 'Change Score',
              description: 'Set score for all selected items',
              isSelected: _selectedAction == BulkAction.changeScore,
              onTap: () {
                setState(() {
                  _selectedAction = BulkAction.changeScore;
                  _newStatus = null;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Delete
            _buildActionCard(
              icon: Icons.delete,
              title: 'Delete',
              description: 'Remove all selected items from list',
              isSelected: _selectedAction == BulkAction.delete,
              color: AppTheme.accentRed,
              onTap: () {
                setState(() {
                  _selectedAction = BulkAction.delete;
                  _newStatus = null;
                  _newScore = null;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Action-specific options
            if (_selectedAction == BulkAction.changeStatus) ...[
              const Text(
                'New Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _newStatus,
                    hint: const Text(
                      'Select status',
                      style: TextStyle(color: AppTheme.textGray),
                    ),
                    isExpanded: true,
                    dropdownColor: AppTheme.secondaryBlack,
                    style: const TextStyle(color: Colors.white),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_formatStatus(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _newStatus = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_selectedAction == BulkAction.changeScore) ...[
              const Text(
                'New Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _newScore ?? 0,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      activeColor: AppTheme.accentBlue,
                      label: _newScore == 0 || _newScore == null
                          ? 'No score'
                          : _newScore!.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _newScore = value;
                        });
                      },
                    ),
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      _newScore == 0 || _newScore == null
                          ? '-'
                          : _newScore!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            if (_selectedAction == BulkAction.delete) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: AppTheme.accentRed,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This will permanently delete ${widget.selectedCount} items from your list.',
                        style: TextStyle(
                          color: AppTheme.accentRed,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textGray),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _canApply() ? _apply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAction == BulkAction.delete
                        ? AppTheme.accentRed
                        : AppTheme.accentBlue,
                    disabledBackgroundColor: AppTheme.textGray.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedAction == BulkAction.delete ? 'Delete' : 'Apply',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.accentBlue).withOpacity(0.1)
              : AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.accentBlue)
                : const Color(0xFF3A3A3A),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? (color ?? AppTheme.accentBlue) : AppTheme.textGray,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color ?? AppTheme.accentBlue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  bool _canApply() {
    if (_selectedAction == null) return false;
    
    switch (_selectedAction!) {
      case BulkAction.changeStatus:
        return _newStatus != null;
      case BulkAction.changeScore:
        return _newScore != null;
      case BulkAction.delete:
        return true;
    }
  }

  void _apply() {
    final result = {
      'action': _selectedAction,
      'status': _newStatus,
      'score': _newScore,
    };
    
    Navigator.pop(context, result);
  }
}
