import 'package:flutter/material.dart';
import 'package:miyolist/core/theme/app_theme.dart';
import 'package:miyolist/features/social/data/models/social_user.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';
import 'package:miyolist/features/social/presentation/widgets/donator_badge.dart';
import 'package:miyolist/features/media_details/presentation/pages/media_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Public profile page for viewing other users' profiles
class PublicProfilePage extends StatefulWidget {
  final int? userId;
  final String? username;
  final SocialService socialService;
  final int? currentUserId; // For follow/unfollow functionality

  const PublicProfilePage({
    super.key,
    this.userId,
    this.username,
    required this.socialService,
    this.currentUserId,
  }) : assert(userId != null || username != null, 'Either userId or username must be provided');

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> with SingleTickerProviderStateMixin {
  PublicUserProfile? _profile;
  bool _isLoading = true;
  String? _error;
  bool _isFollowing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await widget.socialService.getUserProfile(
        userId: widget.userId,
        username: widget.username,
      );

      if (profile == null) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profile = profile;
        _isFollowing = profile.isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || widget.currentUserId == null) return;

    // Can't follow yourself
    if (_profile!.id == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot follow yourself')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newFollowingState = await widget.socialService.toggleFollow(_profile!.id);
      
      setState(() {
        _isFollowing = newFollowingState;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newFollowingState ? 'Now following ${_profile!.name}' : 'Unfollowed ${_profile!.name}'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );

      // Reload profile to update follower count
      await _loadProfile();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _profile == null
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
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_profile == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildProfileHeader()),
        SliverToBoxAdapter(child: _buildTabBar()),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStatisticsTab(),
              _buildFavoritesTab(),
              _buildAboutTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _profile!.bannerImage != null
            ? CachedNetworkImage(
                imageUrl: _profile!.bannerImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppTheme.backgroundGray),
                errorWidget: (context, url, error) => Container(color: AppTheme.backgroundGray),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundImage: _profile!.avatarLarge != null
                ? CachedNetworkImageProvider(_profile!.avatarLarge!)
                : null,
            child: _profile!.avatarLarge == null
                ? Text(
                    _profile!.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Username
          Text(
            _profile!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Donator badge
          if (_profile!.donatorTier > 0) ...[
            DonatorBadge(
              donatorTier: _profile!.donatorTier,
              customBadgeText: _profile!.donatorBadge,
              fontSize: 13,
            ),
            const SizedBox(height: 8),
          ],
          
          // Moderator roles (if any)
          if (_profile!.moderatorRoles != null && _profile!.moderatorRoles!.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _profile!.moderatorRoles!.map((role) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, size: 14, color: Color(0xFF2196F3)),
                      const SizedBox(width: 4),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          
          // Follow button (only if viewing someone else's profile)
          if (widget.currentUserId != null && _profile!.id != widget.currentUserId) ...[
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleFollow,
              icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
              label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey : AppTheme.accentBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Follow status badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_profile!.isFollower)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 16, color: AppTheme.accentGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Follows You',
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.accentBlue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.accentBlue,
        tabs: const [
          Tab(text: 'Statistics'),
          Tab(text: 'Favorites'),
          Tab(text: 'About'),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_profile?.statistics == null) {
      return const Center(child: Text('No statistics available'));
    }

    final stats = _profile!.statistics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.anime != null) ...[
            const Text(
              '📺 Anime Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatCard('Total Anime', stats.anime!.count.toString()),
            _buildStatCard('Episodes Watched', stats.anime!.episodesWatched?.toString() ?? 'N/A'),
            _buildStatCard(
              'Days Watched',
              stats.anime!.minutesWatched != null
                  ? (stats.anime!.minutesWatched! / 1440).toStringAsFixed(1)
                  : 'N/A',
            ),
            _buildStatCard(
              'Mean Score',
              stats.anime!.meanScore != null ? stats.anime!.meanScore!.toStringAsFixed(1) : 'N/A',
            ),
            const SizedBox(height: 24),
          ],
          if (stats.manga != null) ...[
            const Text(
              '📖 Manga Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatCard('Total Manga', stats.manga!.count.toString()),
            _buildStatCard('Chapters Read', stats.manga!.chaptersRead?.toString() ?? 'N/A'),
            _buildStatCard('Volumes Read', stats.manga!.volumesRead?.toString() ?? 'N/A'),
            _buildStatCard(
              'Mean Score',
              stats.manga!.meanScore != null ? stats.manga!.meanScore!.toStringAsFixed(1) : 'N/A',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_profile?.favourites == null) {
      return const Center(child: Text('No favorites available'));
    }

    final favs = _profile!.favourites!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (favs.anime.isNotEmpty) ...[
            _buildFavoriteSection('Anime', favs.anime.map((a) {
              return _buildMediaCard(a);
            }).toList()),
            const SizedBox(height: 24),
          ],
          if (favs.manga.isNotEmpty) ...[
            _buildFavoriteSection('Manga', favs.manga.map((m) {
              return _buildMediaCard(m);
            }).toList()),
            const SizedBox(height: 24),
          ],
          if (favs.characters.isNotEmpty) ...[
            _buildFavoriteSection('Characters', favs.characters.map((c) {
              return _buildCharacterCard(c);
            }).toList()),
            const SizedBox(height: 24),
          ],
          if (favs.staff.isNotEmpty) ...[
            _buildFavoriteSection('Staff', favs.staff.map((s) {
              return _buildStaffCard(s);
            }).toList()),
            const SizedBox(height: 24),
          ],
          if (favs.studios.isNotEmpty) ...[
            _buildFavoriteSection('Studios', favs.studios.map((s) {
              return _buildStudioCard(s);
            }).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoriteSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240, // Increased from 220 to 240 to prevent overflow
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(FavouriteMedia media) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsPage(mediaId: media.id),
          ),
        );
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: media.coverImageLarge ?? media.coverImageMedium ?? '',
                height: 180,
                width: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey),
                errorWidget: (context, url, error) => Container(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              media.titleUserPreferred ?? media.titleEnglish ?? media.titleRomaji ?? 'Unknown',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(FavouriteCharacter character) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to CharacterDetailsPage when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Character details page coming soon!')),
        );
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: character.imageLarge ?? character.imageMedium ?? '',
                height: 180,
                width: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey),
                errorWidget: (context, url, error) => Container(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              character.nameFull ?? 'Unknown',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(FavouriteStaff staff) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to StaffDetailsPage when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff details page coming soon!')),
        );
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: staff.imageLarge ?? staff.imageMedium ?? '',
                height: 180,
                width: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey),
                errorWidget: (context, url, error) => Container(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              staff.nameFull ?? 'Unknown',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudioCard(FavouriteStudio studio) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to StudioDetailsPage when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Studio details page coming soon!')),
        );
      },
      child: Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.cardGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              studio.name,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_profile!.about != null && _profile!.about!.isNotEmpty)
            _buildRichAboutText(_profile!.about!)
          else
            const Text(
              'No bio available',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  /// Parse and build rich text with image support (AniList format)
  /// Supports: img100(url), img50(url), img(url)
  Widget _buildRichAboutText(String text) {
    final List<Widget> widgets = [];
    final RegExp imgRegex = RegExp(r'img(\d*)?\(([^)]+)\)');
    
    int lastIndex = 0;
    for (final match in imgRegex.allMatches(text)) {
      // Add text before image
      if (match.start > lastIndex) {
        final textBefore = text.substring(lastIndex, match.start);
        if (textBefore.isNotEmpty) {
          widgets.add(
            Text(
              textBefore,
              style: const TextStyle(fontSize: 14),
            ),
          );
          widgets.add(const SizedBox(height: 8));
        }
      }
      
      // Parse image size (default 100)
      final sizeStr = match.group(1);
      final size = sizeStr != null && sizeStr.isNotEmpty 
          ? double.tryParse(sizeStr) ?? 100.0 
          : 100.0;
      final imageUrl = match.group(2) ?? '';
      
      // Add image
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: size,
                height: size,
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: size,
                height: size,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      
      lastIndex = match.end;
    }
    
    // Add remaining text after last image
    if (lastIndex < text.length) {
      final textAfter = text.substring(lastIndex);
      if (textAfter.isNotEmpty) {
        widgets.add(
          Text(
            textAfter,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }
    }
    
    // If no images found, return simple text
    if (widgets.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
