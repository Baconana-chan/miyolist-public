import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/media_details.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class TrendingMediaSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MediaDetails> media;
  final Color accentColor;

  const TrendingMediaSection({
    super.key,
    required this.title,
    required this.icon,
    required this.media,
    this.accentColor = AppTheme.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: media.length,
            itemBuilder: (context, index) {
              final item = media[index];
              return _TrendingMediaCard(
                media: item,
                accentColor: accentColor,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingMediaCard extends StatelessWidget {
  final MediaDetails media;
  final Color accentColor;

  const _TrendingMediaCard({
    required this.media,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsPage(
              mediaId: media.id!,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 245, // Увеличенная высота для 2 строк текста
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 180,
                    width: 140,
                    color: AppTheme.cardGray,
                    child: media.coverImage != null
                        ? CachedNetworkImage(
                            imageUrl: media.coverImage!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.cardGray,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentBlue,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.cardGray,
                              child: const Icon(
                                Icons.broken_image,
                                color: AppTheme.textGray,
                                size: 32,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppTheme.textGray,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                // Score Badge
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
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${media.averageScore}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Expanded(
              child: Text(
                media.titleEnglish ?? media.titleRomaji ?? 'Unknown',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
