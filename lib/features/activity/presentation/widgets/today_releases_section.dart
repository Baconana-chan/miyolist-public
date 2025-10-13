import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/airing_episode.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class TodayReleasesSection extends StatelessWidget {
  final List<AiringEpisode> episodes;
  
  const TodayReleasesSection({
    super.key,
    required this.episodes,
  });
  
  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentRed, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AIRING TODAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${episodes.length} episode${episodes.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal Scroll
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < episodes.length - 1 ? 16 : 0,
                ),
                child: _TodayEpisodeCard(episode: episode),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TodayEpisodeCard extends StatelessWidget {
  final AiringEpisode episode;
  
  const _TodayEpisodeCard({required this.episode});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsPage(mediaId: episode.mediaId),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: AppTheme.mangaPanelDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Episode Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: episode.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: episode.coverImageUrl!,
                          width: 160,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 160,
                            height: 200,
                            color: AppTheme.secondaryBlack,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 160,
                            height: 200,
                            color: AppTheme.secondaryBlack,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppTheme.textGray,
                            ),
                          ),
                        )
                      : Container(
                          width: 160,
                          height: 200,
                          color: AppTheme.secondaryBlack,
                          child: const Icon(
                            Icons.movie,
                            color: AppTheme.textGray,
                            size: 48,
                          ),
                        ),
                ),
                
                // Episode Number Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'EP ${episode.episode}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Time Until Badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          episode.getTimeUntilText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                episode.title,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
