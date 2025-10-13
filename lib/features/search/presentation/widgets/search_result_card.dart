import 'package:flutter/material.dart';
import '../../../../core/models/media_details.dart';
import '../../../../core/theme/app_theme.dart';

class SearchResultCard extends StatelessWidget {
  final MediaDetails media;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.media,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardGray,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: media.coverImage != null
                    ? Image.network(
                        media.coverImage!,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              
              const SizedBox(width: 12),
              
              // Media Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      media.displayTitle,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Type & Format
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: media.isAnime
                                ? AppTheme.accentRed.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            media.type,
                            style: TextStyle(
                              color: media.isAnime ? AppTheme.accentRed : Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (media.format != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            media.formatText,
                            style: const TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Episodes/Chapters & Status
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (media.isAnime && media.episodes != null)
                          _buildInfoChip(
                            Icons.tv,
                            '${media.episodes} eps',
                          ),
                        if (media.isManga && media.chapters != null)
                          _buildInfoChip(
                            Icons.book,
                            '${media.chapters} ch',
                          ),
                        if (media.isManga && media.volumes != null)
                          _buildInfoChip(
                            Icons.collections_bookmark,
                            '${media.volumes} vol',
                          ),
                        if (media.status != null)
                          _buildInfoChip(
                            Icons.info_outline,
                            media.statusText,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Score & Popularity
                    Row(
                      children: [
                        if (media.averageScore != null) ...[
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(media.averageScore! / 10).toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (media.popularity != null) ...[
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatNumber(media.popularity!),
                            style: const TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Genres
                    if (media.genres != null && media.genres!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: media.genres!.take(3).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryBlack,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.textGray.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              genre,
                              style: const TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow Icon
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 120,
      color: AppTheme.secondaryBlack,
      child: const Icon(
        Icons.image_not_supported,
        color: AppTheme.textGray,
        size: 32,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textGray,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
