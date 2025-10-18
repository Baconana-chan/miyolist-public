import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/custom_themes_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/user_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';
import '../../../character/presentation/pages/character_details_page.dart';
import '../../../staff/presentation/pages/staff_details_page.dart';
import '../../../studio/presentation/pages/studio_details_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../themes/custom_themes_page.dart';
import '../../../settings/presentation/pages/push_notification_settings_page.dart';
import '../../../settings/presentation/pages/offline_content_settings_page.dart';
import '../widgets/privacy_settings_dialog.dart';
import '../widgets/about_dialog.dart';
import '../widgets/image_cache_settings_dialog.dart';
import '../widgets/update_settings_dialog.dart';
import '../widgets/session_logs_dialog.dart';
import '../widgets/rich_description_text.dart';
import '../widgets/export_settings_dialog.dart';
import '../../../image_gallery/presentation/image_gallery_page.dart';
import '../../../social/domain/services/social_service.dart';
import '../../../social/domain/services/friends_service.dart';
import '../../../social/presentation/pages/following_followers_page.dart';
import '../../../social/presentation/pages/friends_page.dart';


class ProfilePage extends StatefulWidget {
  final AuthService authService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const ProfilePage({
    super.key,
    required this.authService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  Map<String, dynamic>? _favorites;
  UserSettings? _settings;
  bool _isLoading = true;
  Map<String, dynamic>? _dbStats;
  SocialService? _socialService;
  AniListService? _anilistService;
  int _followingCount = 0;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeSocialService();
  }

  Future<void> _initializeSocialService() async {
    try {
      _anilistService = AniListService(widget.authService);
      final user = await _anilistService!.fetchCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _socialService = SocialService(_anilistService!.client);
        });
        _loadFollowingCounts(user['id'] as int);
      }
    } catch (e) {
      print('Failed to initialize social service: $e');
    }
  }

  Future<void> _loadFollowingCounts(int userId) async {
    if (_socialService == null) return;

    try {
      final following = await _socialService!.getFollowing(userId, perPage: 1);
      final followers = await _socialService!.getFollowers(userId, perPage: 1);
      
      if (mounted) {
        setState(() {
          _followingCount = following.length;
          _followersCount = followers.length;
        });
      }
    } catch (e) {
      print('Failed to load following counts: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = widget.localStorageService.getUser();
      final favorites = widget.localStorageService.getFavorites();
      final settings = widget.localStorageService.getUserSettings();
      final stats = await widget.localStorageService.getDatabaseStats();
      
      setState(() {
        _user = user;
        _favorites = favorites;
        _settings = settings;
        _dbStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.logout();
      await widget.localStorageService.clearAll();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              authService: widget.authService,
              localStorageService: widget.localStorageService,
              supabaseService: widget.supabaseService,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildProfileTypeBadge() {
    final isPublic = _settings?.isPublicProfile ?? false;
    final icon = isPublic ? Icons.public : Icons.lock;
    final label = isPublic ? 'Public Profile' : 'Private Profile';
    final color = isPublic ? AppTheme.accentRed : AppTheme.accentBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacySettings() async {
    if (_settings == null) return;

    final newSettings = await showDialog<UserSettings>(
      context: context,
      builder: (context) => PrivacySettingsDialog(
        currentSettings: _settings!,
        localStorageService: widget.localStorageService,
        supabaseService: widget.supabaseService,
      ),
    );

    if (newSettings != null) {
      setState(() => _settings = newSettings);
      
      // Reload database stats after settings change
      final stats = await widget.localStorageService.getDatabaseStats();
      setState(() => _dbStats = stats);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Privacy settings updated to ${newSettings.isPublicProfile ? "public" : "private"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showUpdateSettings() async {
    await showDialog(
      context: context,
      builder: (context) => const UpdateSettingsDialog(),
    );
  }

  Future<void> _showExportSettings() async {
    await showDialog(
      context: context,
      builder: (context) => const ExportSettingsDialog(),
    );
  }

  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsPage(
          localStorageService: widget.localStorageService,
          anilistService: AniListService(widget.authService),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPrivacySettings,
            tooltip: 'Privacy Settings',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'about':
                  showDialog(
                    context: context,
                    builder: (context) => const AboutAppDialog(),
                  );
                  break;
                case 'logs':
                  showDialog(
                    context: context,
                    builder: (context) => const SessionLogsDialog(),
                  );
                  break;
                case 'gallery':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImageGalleryPage(),
                    ),
                  );
                  break;
                case 'cache':
                  showDialog(
                    context: context,
                    builder: (context) => ImageCacheSettingsDialog(
                      localStorageService: widget.localStorageService,
                    ),
                  );
                  break;
                case 'offline_content':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OfflineContentSettingsPage(
                        localStorageService: widget.localStorageService,
                      ),
                    ),
                  );
                  break;
                case 'themes':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomThemesPage(
                        themesService: Provider.of<CustomThemesService>(context, listen: false),
                      ),
                    ),
                  );
                  break;
                case 'notifications':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PushNotificationSettingsPage(),
                    ),
                  );
                  break;
                case 'updates':
                  _showUpdateSettings();
                  break;
                case 'export':
                  _showExportSettings();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('About App'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logs',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('Session Logs'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'gallery',
                child: Row(
                  children: [
                    Icon(Icons.photo_library, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('Offline Gallery'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cache',
                child: Row(
                  children: [
                    Icon(Icons.image, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('Image Cache'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'offline_content',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('Offline Content'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'themes',
                child: Row(
                  children: [
                    Icon(Icons.palette, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('Custom Themes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('Push Notifications'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'updates',
                child: Row(
                  children: [
                    Icon(Icons.system_update_alt, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('App Updates'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.folder_open, color: AppTheme.textGray),
                    SizedBox(width: 12),
                    Text('Export Settings'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.accentRed),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: AppTheme.accentRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('No user data'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner
                      if (_user!.bannerImage != null)
                        CachedNetworkImage(
                          imageUrl: _user!.bannerImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: AppTheme.secondaryBlack,
                          ),
                        ),
                      
                      // Avatar and name
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.accentRed,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.secondaryBlack,
                                backgroundImage: _user!.avatar != null
                                    ? CachedNetworkImageProvider(_user!.avatar!)
                                    : null,
                                child: _user!.avatar == null
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Name and profile type
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user!.name,
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildProfileTypeBadge(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Following/Followers counts
                      if (_socialService != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Following button
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FollowingFollowersPage(
                                              userId: _user!.id,
                                              isFollowing: true,
                                              socialService: _socialService!,
                                              currentUserId: _user!.id,
                                            ),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$_followingCount',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.accentBlue,
                                            ),
                                          ),
                                          const Text(
                                            'Following',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Followers button
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FollowingFollowersPage(
                                              userId: _user!.id,
                                              isFollowing: false,
                                              socialService: _socialService!,
                                              currentUserId: _user!.id,
                                            ),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppTheme.accentGreen.withOpacity(0.5)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$_followersCount',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.accentGreen,
                                            ),
                                          ),
                                          const Text(
                                            'Followers',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Friends button (full width)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final friendsService = FriendsService(_socialService!);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FriendsPage(
                                          userId: _user!.id,
                                          friendsService: friendsService,
                                          socialService: _socialService!,
                                          currentUserId: _user!.id,
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppTheme.accentPurple.withOpacity(0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.people, color: AppTheme.accentPurple),
                                  label: const Text(
                                    'Friends (Mutual Follows)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.accentPurple,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // About
                      if (_user!.about != null && _user!.about!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              RichDescriptionText(
                                markdown: _convertAniListMarkdown(_user!.about!),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      
                      // Storage Info Card
                      if (_dbStats != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardGray,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.textGray.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.storage,
                                      color: AppTheme.accentRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Storage Usage',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Progress indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(_dbStats!['totalSizeMB'] as double).toStringAsFixed(2)} MB',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentRed,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'of ${_settings?.cacheSizeLimitMB ?? 200} MB',
                                      style: const TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (_dbStats!['totalSizeMB'] as double) / (_settings?.cacheSizeLimitMB ?? 200),
                                    minHeight: 8,
                                    backgroundColor: AppTheme.textGray.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      (_dbStats!['totalSizeMB'] as double) / (_settings?.cacheSizeLimitMB ?? 200) > 0.8
                                          ? Colors.orange
                                          : AppTheme.accentRed,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Quick stats
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildQuickStat(
                                      'Anime',
                                      _dbStats!['animeListEntries'].toString(),
                                      Icons.movie,
                                    ),
                                    _buildQuickStat(
                                      'Manga',
                                      _dbStats!['mangaListEntries'].toString(),
                                      Icons.book,
                                    ),
                                    _buildQuickStat(
                                      'Cache',
                                      _dbStats!['mediaCacheEntries'].toString(),
                                      Icons.cached,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Statistics button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _navigateToStatistics,
                                    icon: const Icon(Icons.bar_chart),
                                    label: const Text('View Detailed Statistics'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.colors.primaryAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Favorites
                      if (_favorites != null) ...[
                        _buildFavoriteSection('Anime', _favorites!['anime']),
                        _buildFavoriteSection('Manga', _favorites!['manga']),
                        _buildFavoriteSection('Characters', _favorites!['characters']),
                        _buildFavoriteSection('Staff', _favorites!['staff']),
                        _buildFavoriteSection('Studios', _favorites!['studios']),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.accentRed,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteSection(String title, dynamic data) {
    if (data == null) return const SizedBox();
    
    final nodes = data['nodes'] as List?;
    if (nodes == null || nodes.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorite $title',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (nodes.length > 12)
                TextButton(
                  onPressed: () => _showAllFavorites(title, nodes),
                  child: Text('View All (${nodes.length})'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: nodes.length.clamp(0, 12), // Показываем максимум 12
              itemBuilder: (context, index) {
                final item = nodes[index];
                // Safe cast from Map<dynamic, dynamic> to Map<String, dynamic>
                final itemData = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                return _buildFavoriteCard(itemData, title);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAllFavorites(String title, List nodes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardGray,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorite $title (${nodes.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    childAspectRatio: 0.67,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final item = nodes[index];
                    // Safe cast from Map<dynamic, dynamic> to Map<String, dynamic>
                    final itemData = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                    return _buildFavoriteCard(itemData, title);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> item, String type) {
    String? imageUrl;
    String name = '';
    int? mediaId;
    int? characterId;
    int? staffId;
    int? studioId;

    if (type == 'Anime' || type == 'Manga') {
      imageUrl = item['coverImage']?['large'];
      name = item['title']?['english'] ?? item['title']?['romaji'] ?? '';
      mediaId = item['id'] as int?;
    } else if (type == 'Characters') {
      imageUrl = item['image']?['large'];
      name = item['name']?['full'] ?? '';
      characterId = item['id'] as int?;
    } else if (type == 'Staff') {
      imageUrl = item['image']?['large'];
      name = item['name']?['full'] ?? '';
      staffId = item['id'] as int?;
    } else if (type == 'Studios') {
      name = item['name'] ?? '';
      studioId = item['id'] as int?;
    }

    return GestureDetector(
      onTap: () {
        if ((type == 'Anime' || type == 'Manga') && mediaId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaDetailsPage(mediaId: mediaId!),
            ),
          );
        } else if (type == 'Characters' && characterId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterDetailsPage(
                characterId: characterId!,
                anilistService: AniListService(AuthService()),
                localStorageService: widget.localStorageService,
                supabaseService: widget.supabaseService,
              ),
            ),
          );
        } else if (type == 'Staff' && staffId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffDetailsPage(
                staffId: staffId!,
                anilistService: AniListService(AuthService()),
                localStorageService: widget.localStorageService,
                supabaseService: widget.supabaseService,
              ),
            ),
          );
        } else if (type == 'Studios' && studioId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudioDetailsPage(
                studioId: studioId!,
                anilistService: AniListService(AuthService()),
                localStorageService: widget.localStorageService,
                supabaseService: widget.supabaseService,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: AppTheme.mangaPanelDecoration,
        child: Column(
          children: [
          if (imageUrl != null)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.secondaryBlack,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.secondaryBlack,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                color: AppTheme.secondaryBlack,
                child: const Center(
                  child: Icon(Icons.favorite, size: 48),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  /// Convert AniList markdown format to standard markdown
  String _convertAniListMarkdown(String text) {
    // Remove HTML tags but keep links
    text = text.replaceAllMapped(
      RegExp(r'<a href=["\x27]([^"\x27]+)["\x27]>([^<]+)</a>', caseSensitive: false),
      (match) => '[${match.group(2)}](${match.group(1)})',
    );
    
    // Remove other HTML tags
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Convert AniList spoilers to regular text (they use ~~~ syntax)
    text = text.replaceAll(RegExp(r'~~~(.+?)~~~', dotAll: true), r'||$1||');
    
    // Decode HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    
    return text;
  }
}


