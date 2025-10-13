import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/media_preview.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

/// Inline media card for displaying anime/manga previews in profile descriptions
class InlineMediaCard extends StatelessWidget {
  final MediaPreview media;
  final VoidCallback? onTap;

  const InlineMediaCard({
    super.key,
    required this.media,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsPage(mediaId: media.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.colors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.colors.divider,
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: media.coverImage ?? '',
                  width: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    color: AppTheme.colors.divider,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    color: AppTheme.colors.divider,
                    child: Icon(
                      Icons.broken_image,
                      color: AppTheme.colors.secondaryText,
                      size: 24,
                    ),
                  ),
                ),
              ),
              
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        media.displayTitle,
                        style: TextStyle(
                          color: AppTheme.colors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Format + Status
                      Row(
                        children: [
                          // Format badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getFormatColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getFormatColor(),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _formatType(),
                              style: TextStyle(
                                color: _getFormatColor(),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          
                          // Status
                          Expanded(
                            child: Text(
                              _formatStatus(),
                              style: TextStyle(
                                color: AppTheme.colors.secondaryText,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Score (if available)
                      if (media.averageScore != null && media.averageScore! > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: AppTheme.colors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${media.averageScore!.toInt()}%',
                              style: TextStyle(
                                color: AppTheme.colors.primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Arrow icon
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.colors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatType() {
    if (media.format == null) return media.mediaType.toUpperCase();
    
    switch (media.format!.toUpperCase()) {
      case 'TV':
        return 'TV';
      case 'TV_SHORT':
        return 'TV SHORT';
      case 'MOVIE':
        return 'MOVIE';
      case 'SPECIAL':
        return 'SPECIAL';
      case 'OVA':
        return 'OVA';
      case 'ONA':
        return 'ONA';
      case 'MUSIC':
        return 'MUSIC';
      case 'MANGA':
        return 'MANGA';
      case 'NOVEL':
        return 'NOVEL';
      case 'ONE_SHOT':
        return 'ONE SHOT';
      default:
        return media.format!.toUpperCase();
    }
  }

  String _formatStatus() {
    if (media.status == null) return '';
    
    switch (media.status!.toUpperCase()) {
      case 'FINISHED':
        return 'Finished';
      case 'RELEASING':
        return 'Releasing';
      case 'NOT_YET_RELEASED':
        return 'Not Yet Released';
      case 'CANCELLED':
        return 'Cancelled';
      case 'HIATUS':
        return 'Hiatus';
      default:
        return media.status!;
    }
  }

  Color _getFormatColor() {
    final type = media.mediaType.toUpperCase();
    
    if (type == 'MANGA') {
      return AppTheme.colors.info;
    } else {
      return AppTheme.colors.primaryAccent;
    }
  }
}
