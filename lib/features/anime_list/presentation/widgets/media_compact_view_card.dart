import 'package:flutter/material.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

/// Compact view card - minimal, text-focused layout
class MediaCompactViewCard extends StatelessWidget {
  final MediaListEntry entry;
  final VoidCallback onTap;
  final bool showStatusIndicator;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const MediaCompactViewCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.showStatusIndicator = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  /// Get the total count based on media type
  int? _getTotalCount() {
    final media = entry.media;
    if (media == null) return null;
    
    final format = media.format?.toUpperCase();
    
    // For manga and novels, use chapters
    if (format == 'MANGA' || format == 'NOVEL' || format == 'ONE_SHOT') {
      return media.chapters;
    }
    
    // For anime, use episodes
    return media.episodes;
  }

  /// Get color based on media status
  Color _getStatusColor() {
    switch (entry.status) {
      case 'CURRENT':
        return const Color(0xFF4CAF50); // Green
      case 'PLANNING':
        return const Color(0xFF2196F3); // Blue
      case 'COMPLETED':
        return const Color(0xFF9C27B0); // Purple
      case 'PAUSED':
        return const Color(0xFFFF9800); // Orange
      case 'DROPPED':
        return const Color(0xFFF44336); // Red
      case 'REPEATING':
        return const Color(0xFF00BCD4); // Cyan
      default:
        return AppTheme.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = entry.media;
    if (media == null) return const SizedBox();

    final total = _getTotalCount();
    final progressText = total != null
        ? '${entry.progress}/$total'
        : '${entry.progress}';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : const Color(0xFF3A3A3A),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Status indicator dot
            if (showStatusIndicator) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            // Title and info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.titleRomaji,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${media.format ?? 'Unknown'} • ${progressText}',
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Score
            if (entry.score != null && entry.score! > 0) ...[
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFC107),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.score!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            // Info button
            if (!isSelectionMode) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaDetailsPage(mediaId: media.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppTheme.textGray,
                    size: 18,
                  ),
                ),
              ),
            ],
            
            // Selection indicator
            if (isSelectionMode) ...[
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentBlue
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.accentBlue : AppTheme.textGray,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
