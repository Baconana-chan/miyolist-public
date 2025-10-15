import 'package:flutter/material.dart';
import 'package:miyolist/core/theme/app_theme.dart';
import 'package:miyolist/features/social/data/models/social_user.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';
import 'package:miyolist/features/social/presentation/pages/public_profile_page.dart';
import 'package:miyolist/features/social/presentation/widgets/donator_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Page for searching users
class UserSearchPage extends StatefulWidget {
  final SocialService socialService;
  final int? currentUserId;

  const UserSearchPage({
    super.key,
    required this.socialService,
    this.currentUserId,
  });

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SocialUser> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.socialService.searchUsers(query.trim());
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        backgroundColor: AppTheme.cardGray,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.cardGray,
              ),
              onSubmitted: _searchUsers,
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    _searchResults = [];
                    _error = null;
                  });
                }
              },
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(_error!, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No users found', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : _searchResults.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_search, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Search for users by username', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) => _buildUserTile(_searchResults[index]),
                              ),
          ),
        ],
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
              child: Text(
                'Following',
                style: TextStyle(color: AppTheme.accentBlue, fontSize: 10),
              ),
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
