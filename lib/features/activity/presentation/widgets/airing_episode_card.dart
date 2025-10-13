import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/airing_episode.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class AiringEpisodeCard extends StatelessWidget {
  final AiringEpisode episode;
  
  const AiringEpisodeCard({
    super.key,
    required this.episode,
  });
  
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
        decoration: AppTheme.mangaPanelDecoration,
        child: Row(
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: episode.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: episode.coverImageUrl!,
                      width: 90,
                      height: 130,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 90,
                        height: 130,
                        color: AppTheme.secondaryBlack,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 90,
                        height: 130,
                        color: AppTheme.secondaryBlack,
                        child: const Icon(
                          Icons.broken_image,
                          color: AppTheme.textGray,
                        ),
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 130,
                      color: AppTheme.secondaryBlack,
                      child: const Icon(
                        Icons.movie,
                        color: AppTheme.textGray,
                        size: 40,
                      ),
                    ),
            ),
            
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      episode.title,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Episode Number
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: AppTheme.accentBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Episode ${episode.episode}',
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (episode.totalEpisodes != null) ...[
                          Text(
                            ' / ${episode.totalEpisodes}',
                            style: const TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Airing Time
                    Row(
                      children: [
                        Icon(
                          episode.isToday 
                              ? Icons.today 
                              : Icons.calendar_today,
                          color: episode.isToday 
                              ? AppTheme.accentRed 
                              : AppTheme.textGray,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatAiringTime(),
                          style: TextStyle(
                            color: episode.isToday 
                                ? AppTheme.accentRed 
                                : AppTheme.textGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Time Until
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppTheme.accentBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'in ${episode.getTimeUntilText()}',
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatAiringTime() {
    final now = DateTime.now();
    final diff = episode.airingAt.difference(now);
    
    if (episode.isToday) {
      // Показываем время
      final hour = episode.airingAt.hour.toString().padLeft(2, '0');
      final minute = episode.airingAt.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays < 7) {
      // Показываем день недели
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[episode.airingAt.weekday - 1];
    } else {
      // Показываем дату
      final month = episode.airingAt.month.toString().padLeft(2, '0');
      final day = episode.airingAt.day.toString().padLeft(2, '0');
      return '$day.$month';
    }
  }
}
