import 'package:flutter/material.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_cover_image.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

/// List view card - larger, more detailed horizontal layout
class MediaListViewCard extends StatelessWidget {
  final MediaListEntry entry;
  final VoidCallback onTap;
  final bool showStatusIndicator;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const MediaListViewCard({
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

  String _getStatusLabel() {
    switch (entry.status) {
      case 'CURRENT':
        return 'Current';
      case 'PLANNING':
        return 'Planning';
      case 'COMPLETED':
        return 'Completed';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      case 'REPEATING':
        return 'Repeating';
      default:
        return entry.status;
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentBlue,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              )
            : AppTheme.mangaPanelDecoration,
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator strip (if showing)
                if (showStatusIndicator)
                  Container(
                    width: 4,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                
                // Cover image
                ClipRRect(
                  borderRadius: showStatusIndicator
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                  child: Stack(
                    children: [
                      CachedCoverImage(
                        imageUrl: media.coverImage,
                        mediaId: media.id,
                        width: 100,
                        height: 140,
                        fit: BoxFit.cover,
                        enableOfflineCache: true,
                      ),
                      
                      // Info button
                      Positioned(
                        top: 6,
                        left: 6,
                        child: GestureDetector(
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
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          media.titleRomaji,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Format and year
                        Text(
                          '${media.format ?? 'Unknown'} • ${media.startYear ?? '?'}',
                          style: const TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Progress and score
                        Row(
                          children: [
                            // Progress
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Progress',
                                    style: TextStyle(
                                      color: AppTheme.textGray,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    progressText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Score
                            if (entry.score != null && entry.score! > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Score',
                                    style: TextStyle(
                                      color: AppTheme.textGray,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                        
                        // Status label (if showing indicator)
                        if (showStatusIndicator) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getStatusColor().withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Selection indicator
            if (isSelectionMode)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentBlue
                        : Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
