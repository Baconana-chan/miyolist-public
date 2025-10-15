import 'package:flutter/material.dart';
import 'package:miyolist/core/theme/app_theme.dart';
import 'package:miyolist/features/social/data/models/social_user.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';
import 'package:miyolist/features/social/presentation/pages/public_profile_page.dart';
import 'package:miyolist/features/social/presentation/widgets/donator_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Page to display Following or Followers list
class FollowingFollowersPage extends StatefulWidget {
  final int userId;
  final bool isFollowing; // true = Following, false = Followers
  final SocialService socialService;
  final int? currentUserId;

  const FollowingFollowersPage({
    super.key,
    required this.userId,
    required this.isFollowing,
    required this.socialService,
    this.currentUserId,
  });

  @override
  State<FollowingFollowersPage> createState() => _FollowingFollowersPageState();
}

class _FollowingFollowersPageState extends State<FollowingFollowersPage> {
  List<SocialUser> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = widget.isFollowing
          ? await widget.socialService.getFollowing(widget.userId)
          : await widget.socialService.getFollowers(widget.userId);

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowing ? 'Following' : 'Followers'),
        backgroundColor: AppTheme.cardGray,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            widget.isFollowing ? 'No following' : 'No followers',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) => _buildUserTile(_users[index]),
                    ),
    );
  }

  Widget _buildUserTile(SocialUser user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarMedium != null
            ? CachedNetworkImageProvider(user.avatarMedium!)
            : null,
        child: user.avatarMedium == null ? Text(user.name[0].toUpperCase()) : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (user.donatorTier > 0) ...[
            const SizedBox(width: 6),
            DonatorBadge(
              donatorTier: user.donatorTier,
              customBadgeText: user.donatorBadge,
              fontSize: 10,
              showIcon: false,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          ],
        ],
      ),
      subtitle: user.statistics != null
          ? Text(
              '${user.statistics!.anime?.count ?? 0} anime • ${user.statistics!.manga?.count ?? 0} manga',
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.isFollowing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Following', style: TextStyle(color: AppTheme.accentBlue, fontSize: 10)),
            ),
          if (user.isFollower)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Follows You', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10)),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfilePage(
              userId: user.id,
              socialService: widget.socialService,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      },
    );
  }
}
