import 'package:flutter/material.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_cover_image.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class MediaListCard extends StatelessWidget {
  final MediaListEntry entry;
  final VoidCallback onTap;
  final bool showStatusIndicator;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const MediaListCard({
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

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image with offline caching
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        CachedCoverImage(
                          imageUrl: media.coverImage,
                          mediaId: media.id,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          enableOfflineCache: true,
                        ),
                    
                        // Info button (opens public page)
                        Positioned(
                          top: 8,
                          left: 8,
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    
                        // Score badge
                        if (media.averageScore != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${media.averageScore!.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                    
                        // Progress badge
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.progress}/${_getTotalCount() ?? '?'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            
                // Title and info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.titleEnglish ?? media.titleRomaji,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (entry.score != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppTheme.accentRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.score!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
        
            // Status indicator (colored strip on the left)
            if (showStatusIndicator)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            
            // Selection indicator
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
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
