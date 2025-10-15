import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/airing_episode.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class AiringEpisodeCard extends StatefulWidget {
  final AiringEpisode episode;
  final AuthService authService;
  final VoidCallback? onEpisodeAdded;
  
  const AiringEpisodeCard({
    super.key,
    required this.episode,
    required this.authService,
    this.onEpisodeAdded,
  });

  @override
  State<AiringEpisodeCard> createState() => _AiringEpisodeCardState();
}

class _AiringEpisodeCardState extends State<AiringEpisodeCard> {
  bool _isUpdating = false;
  late AniListService _anilistService;

  @override
  void initState() {
    super.initState();
    _anilistService = AniListService(widget.authService);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsPage(mediaId: widget.episode.mediaId),
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
              child: widget.episode.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.episode.coverImageUrl!,
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
                      widget.episode.title,
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
                          'Episode ${widget.episode.episode}',
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.episode.totalEpisodes != null) ...[
                          Text(
                            ' / ${widget.episode.totalEpisodes}',
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
                          widget.episode.isToday 
                              ? Icons.today 
                              : Icons.calendar_today,
                          color: widget.episode.isToday 
                              ? AppTheme.accentRed 
                              : AppTheme.textGray,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatAiringTime(),
                          style: TextStyle(
                            color: widget.episode.isToday 
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
                          'in ${widget.episode.getTimeUntilText()}',
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
            
            // Add Episode Button
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isUpdating ? null : _incrementEpisode,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentBlue,
                        width: 1,
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accentBlue,
                            ),
                          )
                        : const Icon(
                            Icons.add,
                            color: AppTheme.accentBlue,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _incrementEpisode() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await _anilistService.incrementEpisodeProgress(widget.episode.mediaId);
      
      if (success) {
        // Показываем snackbar об успехе
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Episode ${widget.episode.episode} marked as watched',
                style: const TextStyle(color: AppTheme.textWhite),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Вызываем callback для обновления родительского виджета
          widget.onEpisodeAdded?.call();
        }
      } else {
        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to update progress',
                style: TextStyle(color: AppTheme.textWhite),
              ),
              backgroundColor: AppTheme.accentRed,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error incrementing episode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error updating progress',
              style: TextStyle(color: AppTheme.textWhite),
            ),
            backgroundColor: AppTheme.accentRed,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
  
  String _formatAiringTime() {
    final now = DateTime.now();
    final diff = widget.episode.airingAt.difference(now);
    
    if (widget.episode.isToday) {
      // Показываем время
      final hour = widget.episode.airingAt.hour.toString().padLeft(2, '0');
      final minute = widget.episode.airingAt.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays < 7) {
      // Показываем день недели
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[widget.episode.airingAt.weekday - 1];
    } else {
      // Показываем дату
      final month = widget.episode.airingAt.month.toString().padLeft(2, '0');
      final day = widget.episode.airingAt.day.toString().padLeft(2, '0');
      return '$day.$month';
    }
  }
}
