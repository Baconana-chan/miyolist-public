import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miyolist/features/social/data/models/following_media_entry.dart';
import 'package:miyolist/features/social/presentation/pages/public_profile_page.dart';
import 'package:miyolist/features/social/presentation/widgets/donator_badge.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';

/// Widget to display following users who have this media in their list
class FollowingMediaSection extends StatefulWidget {
  final int mediaId;
  final String mediaType; // ANIME or MANGA
  final int? currentUserId;
  final SocialService socialService;

  const FollowingMediaSection({
    super.key,
    required this.mediaId,
    required this.mediaType,
    this.currentUserId,
    required this.socialService,
  });

  @override
  State<FollowingMediaSection> createState() => _FollowingMediaSectionState();
}

class _FollowingMediaSectionState extends State<FollowingMediaSection> {
  List<FollowingMediaEntry> _followingList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowingWithMedia();
  }

  Future<void> _loadFollowingWithMedia() async {
    if (widget.currentUserId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.socialService.getFollowingWithMedia(
        widget.currentUserId!,
        widget.mediaId,
        widget.mediaType,
      );

      final entries = results
          .map((map) => FollowingMediaEntry.fromMap(map))
          .toList();

      setState(() {
        _followingList = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load following users';
        _isLoading = false;
      });
      print('Load following with media error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_followingList.isEmpty) {
      return const SizedBox.shrink(); // Hide section if no following users
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Following (${_followingList.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Showing first 20 followers who have this in their list',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ..._followingList.map((entry) => _buildFollowingTile(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowingTile(FollowingMediaEntry entry) {
    final statusColor = Color(FollowingMediaEntry.getStatusColor(entry.status));

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfilePage(
              userId: entry.user.id,
              socialService: widget.socialService,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: entry.user.avatarMedium != null
                  ? CachedNetworkImageProvider(entry.user.avatarMedium!)
                  : null,
              child: entry.user.avatarMedium == null
                  ? Text(entry.user.name[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),

            // Name and donator badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.user.donatorTier > 0) ...[
                        const SizedBox(width: 6),
                        DonatorBadge(
                          donatorTier: entry.user.donatorTier,
                          customBadgeText: entry.user.donatorBadge,
                          fontSize: 9,
                          showIcon: false,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Status and progress
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (entry.progress != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Ep. ${entry.progress}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (entry.score != null && entry.score! > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              entry.score!.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
