import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';
import 'package:miyolist/features/social/presentation/pages/public_profile_page.dart';
import 'package:miyolist/features/media_details/presentation/pages/media_details_page.dart';

/// Widget to display activity feed from followed users
class FollowingActivityFeed extends StatefulWidget {
  final int? currentUserId;
  final SocialService socialService;

  const FollowingActivityFeed({
    super.key,
    this.currentUserId,
    required this.socialService,
  });

  @override
  State<FollowingActivityFeed> createState() => _FollowingActivityFeedState();
}

class _FollowingActivityFeedState extends State<FollowingActivityFeed> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities({bool loadMore = false}) async {
    if (widget.currentUserId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not logged in';
      });
      return;
    }

    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final activities = await widget.socialService.getFollowingActivity(
        widget.currentUserId!,
        page: page,
        perPage: 20,
      );

      setState(() {
        if (loadMore) {
          _activities.addAll(activities);
          _currentPage = page;
        } else {
          _activities = activities;
          _currentPage = 1;
        }
        _hasNextPage = activities.length >= 20; // Assume has more if we got full page
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load activity feed';
        _isLoading = false;
      });
      print('Load following activity error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadActivities(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rss_feed, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No activity from following users',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Follow users to see their activity here',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadActivities(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _activities.length + (_hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _activities.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ElevatedButton(
                  onPressed: () => _loadActivities(loadMore: true),
                  child: const Text('Load More'),
                ),
              ),
            );
          }

          return _buildActivityCard(_activities[index]);
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final type = activity['type'] as String?;
    final user = activity['user'] as Map<String, dynamic>?;
    final createdAt = activity['createdAt'] as int?;

    if (user == null) return const SizedBox.shrink();

    final userName = user['name'] as String? ?? 'Unknown';
    final userAvatar = user['avatar']?['large'] as String?;
    final userId = user['id'] as int?;

    final timeAgo = createdAt != null
        ? _formatTimeAgo(DateTime.fromMillisecondsSinceEpoch(createdAt * 1000))
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: userId != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicProfilePage(
                      userId: userId,
                      socialService: widget.socialService,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: userAvatar != null
                        ? CachedNetworkImageProvider(userAvatar)
                        : null,
                    child: userAvatar == null
                        ? Text(userName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Activity content based on type
              if (type == 'TEXT')
                _buildTextActivity(activity)
              else if (type == 'ANIME_LIST' || type == 'MANGA_LIST')
                _buildListActivity(activity)
              else
                Text('Unknown activity type: $type'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextActivity(Map<String, dynamic> activity) {
    final text = activity['text'] as String? ?? '';
    
    return Text(
      text,
      style: const TextStyle(fontSize: 14),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildListActivity(Map<String, dynamic> activity) {
    final status = activity['status'] as String?;
    final progress = activity['progress'] as String?;
    final media = activity['media'] as Map<String, dynamic>?;

    if (media == null) return const SizedBox.shrink();

    final mediaId = media['id'] as int?;
    final title = media['title']?['userPreferred'] as String? ?? 'Unknown';
    final coverImage = media['coverImage']?['large'] as String?;
    final format = media['format'] as String?;

    String activityText = '';
    if (status != null) {
      activityText = _getStatusText(status);
      if (progress != null) {
        activityText += ' $progress of';
      }
    }

    return InkWell(
      onTap: mediaId != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaDetailsPage(mediaId: mediaId),
                ),
              );
            }
          : null,
      child: Row(
        children: [
          if (coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: coverImage,
                width: 60,
                height: 85,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activityText.isNotEmpty)
                  Text(
                    activityText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (format != null)
                  Text(
                    format,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'CURRENT':
        return 'Watching';
      case 'PLANNING':
        return 'Plans to watch';
      case 'COMPLETED':
        return 'Completed';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      case 'REPEATING':
        return 'Rewatching';
      default:
        return status;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
