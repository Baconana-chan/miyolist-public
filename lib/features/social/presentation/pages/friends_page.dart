import 'package:flutter/material.dart';
import 'package:miyolist/core/theme/app_theme.dart';
import 'package:miyolist/features/social/data/models/social_user.dart';
import 'package:miyolist/features/social/domain/services/friends_service.dart';
import 'package:miyolist/features/social/presentation/pages/public_profile_page.dart';
import 'package:miyolist/features/social/presentation/widgets/donator_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';

/// Page to display Friends, Friend Requests, and Suggested Friends
class FriendsPage extends StatefulWidget {
  final int userId;
  final FriendsService friendsService;
  final SocialService socialService;
  final int? currentUserId;

  const FriendsPage({
    super.key,
    required this.userId,
    required this.friendsService,
    required this.socialService,
    this.currentUserId,
  });

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<SocialUser> _friends = [];
  List<SocialUser> _friendRequests = [];
  List<SocialUser> _suggestedFriends = [];
  
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  bool _isLoadingSuggested = false;
  
  String? _errorFriends;
  String? _errorRequests;
  String? _errorSuggested;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Load data for the selected tab
        switch (_tabController.index) {
          case 0:
            if (_friends.isEmpty) _loadFriends();
            break;
          case 1:
            if (_friendRequests.isEmpty) _loadFriendRequests();
            break;
          case 2:
            if (_suggestedFriends.isEmpty) _loadSuggestedFriends();
            break;
        }
      }
    });
    
    // Load friends initially
    _loadFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    if (_isLoadingFriends) return;
    
    setState(() {
      _isLoadingFriends = true;
      _errorFriends = null;
    });

    try {
      final friends = await widget.friendsService.getFriends(widget.userId);
      setState(() {
        _friends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() {
        _errorFriends = 'Failed to load friends: $e';
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _loadFriendRequests() async {
    if (_isLoadingRequests) return;
    
    setState(() {
      _isLoadingRequests = true;
      _errorRequests = null;
    });

    try {
      final requests = await widget.friendsService.getFriendRequests(widget.userId);
      setState(() {
        _friendRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() {
        _errorRequests = 'Failed to load friend requests: $e';
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _loadSuggestedFriends() async {
    if (_isLoadingSuggested) return;
    
    setState(() {
      _isLoadingSuggested = true;
      _errorSuggested = null;
    });

    try {
      final suggested = await widget.friendsService.getSuggestedFriends(widget.userId);
      setState(() {
        _suggestedFriends = suggested;
        _isLoadingSuggested = false;
      });
    } catch (e) {
      setState(() {
        _errorSuggested = 'Failed to load suggested friends: $e';
        _isLoadingSuggested = false;
      });
    }
  }

  Future<void> _acceptFriendRequest(SocialUser user) async {
    final success = await widget.friendsService.acceptFriendRequest(user.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are now friends with ${user.name}! 🎉'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      
      // Move user from requests to friends
      setState(() {
        _friendRequests.remove(user);
        _friends.add(user.copyWith(isFollowing: true));
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept friend request from ${user.name}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFriend(SocialUser user) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardGray,
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${user.name} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await widget.friendsService.removeFriend(user.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${user.name} from friends'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      
      // Remove from friends list
      setState(() {
        _friends.remove(user);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove ${user.name}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: AppTheme.cardGray,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Friends'),
                  if (_friends.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_friends.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_friendRequests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_friendRequests.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_suggestedFriends.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_suggestedFriends.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildFriendRequestsList(),
          _buildSuggestedFriendsList(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorFriends != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorFriends!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFriends,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: AppTheme.textGray),
            const SizedBox(height: 16),
            const Text(
              'No friends yet',
              style: TextStyle(fontSize: 18, color: AppTheme.textGray),
            ),
            const SizedBox(height: 8),
            const Text(
              'Follow users and they follow back to become friends!',
              style: TextStyle(fontSize: 14, color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      color: AppTheme.accentBlue,
      child: ListView.builder(
        itemCount: _friends.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final user = _friends[index];
          return _buildUserTile(
            user,
            subtitle: _buildUserStats(user),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textGray),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _removeFriend(user),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Remove Friend', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people, size: 14, color: AppTheme.accentGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Friend',
                    style: TextStyle(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendRequestsList() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorRequests != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorRequests!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFriendRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 64, color: AppTheme.textGray),
            const SizedBox(height: 16),
            const Text(
              'No friend requests',
              style: TextStyle(fontSize: 18, color: AppTheme.textGray),
            ),
            const SizedBox(height: 8),
            const Text(
              'Users who follow you will appear here',
              style: TextStyle(fontSize: 14, color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      color: AppTheme.accentBlue,
      child: ListView.builder(
        itemCount: _friendRequests.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final user = _friendRequests[index];
          return _buildUserTile(
            user,
            subtitle: _buildUserStats(user),
            trailing: ElevatedButton.icon(
              onPressed: () => _acceptFriendRequest(user),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Request',
                    style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestedFriendsList() {
    if (_isLoadingSuggested) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorSuggested != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorSuggested!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSuggestedFriends,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_suggestedFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 64, color: AppTheme.textGray),
            const SizedBox(height: 16),
            const Text(
              'No pending requests',
              style: TextStyle(fontSize: 18, color: AppTheme.textGray),
            ),
            const SizedBox(height: 8),
            const Text(
              'Users you follow who haven\'t followed back',
              style: TextStyle(fontSize: 14, color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestedFriends,
      color: AppTheme.accentBlue,
      child: ListView.builder(
        itemCount: _suggestedFriends.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final user = _suggestedFriends[index];
          return _buildUserTile(
            user,
            subtitle: _buildUserStats(user),
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14, color: AppTheme.accentBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Pending',
                    style: TextStyle(color: AppTheme.accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserTile(SocialUser user, {Widget? subtitle, Widget? trailing, Widget? badge}) {
    return Card(
      color: AppTheme.cardGray,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: user.avatarLarge != null
              ? CachedNetworkImageProvider(user.avatarLarge!)
              : null,
          child: user.avatarLarge == null
              ? Text(user.name[0].toUpperCase())
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (user.donatorTier > 0)
              DonatorBadge(
                donatorTier: user.donatorTier,
                customBadgeText: user.donatorBadge,
                fontSize: 10,
                showIcon: false,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) subtitle,
            if (badge != null) ...[
              const SizedBox(height: 4),
              badge,
            ],
          ],
        ),
        trailing: trailing,
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
      ),
    );
  }

  Widget _buildUserStats(SocialUser user) {
    if (user.statistics == null) return const SizedBox.shrink();

    return Text(
      'Anime: ${user.statistics!.anime?.count ?? 0} • '
      'Manga: ${user.statistics!.manga?.count ?? 0}',
      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
    );
  }
}
