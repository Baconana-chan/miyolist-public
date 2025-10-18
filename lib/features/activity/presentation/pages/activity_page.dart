import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/models/airing_episode.dart';
import '../../../../core/models/media_details.dart';
import '../../../../core/services/airing_schedule_service.dart';
import '../../../../core/services/trending_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/kaomoji_state.dart';
import '../widgets/airing_episode_card.dart';
import '../widgets/today_releases_section.dart';
import '../widgets/trending_media_section.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../social/domain/services/social_service.dart';
import '../../../social/presentation/widgets/following_activity_feed.dart';
import '../../../social/presentation/pages/create_activity_page.dart';

class ActivityPage extends StatefulWidget {
  final AuthService authService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;
  
  const ActivityPage({
    super.key,
    required this.authService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  late final AiringScheduleService _airingService;
  late final TrendingService _trendingService;
  late final AniListService _anilistService;
  SocialService? _socialService;
  late final TabController _tabController;
  
  List<AiringEpisode> _todayEpisodes = [];
  List<AiringEpisode> _upcomingEpisodes = [];
  List<MediaDetails> _trendingAnime = [];
  List<MediaDetails> _trendingManga = [];
  List<MediaDetails> _newlyAddedAnime = [];
  List<MediaDetails> _newlyAddedManga = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  int? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Changed from 3 to 4
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to show/hide create activity button
      }
    });
    _airingService = AiringScheduleService(widget.authService, widget.localStorageService);
    _trendingService = TrendingService(widget.authService);
    _anilistService = AniListService(widget.authService);
    _loadSchedule();
    _loadTrending();
    _initializeSocialService();
    
    // Обновляем каждую минуту для точного отображения таймера
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {}); // Обновляем UI для таймеров
      }
    });
    
    // Слушаем изменения настройки взрослого контента и перезагружаем данные
    LocalStorageService.adultContentFilterNotifier.addListener(_onAdultContentFilterChanged);
  }
  
  Future<void> _initializeSocialService() async {
    try {
      // Get current user to initialize client
      final user = await _anilistService.fetchCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?['id'] as int?;
          _socialService = SocialService(_anilistService.client);
        });
      }
    } catch (e) {
      print('Failed to initialize social service: $e');
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    LocalStorageService.adultContentFilterNotifier.removeListener(_onAdultContentFilterChanged);
    super.dispose();
  }
  
  void _onAdultContentFilterChanged() {
    if (mounted) {
      // Перезагружаем данные при изменении настройки фильтрации
      _loadSchedule();
      _loadTrending();
    }
  }
  
  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final today = await _airingService.getTodayEpisodes();
      final upcoming = await _airingService.getUpcomingEpisodes(count: 20);
      
      // 🔔 Синхронизируем push-уведомления с расписанием
      final allEpisodes = [...today, ...upcoming];
      final pushService = PushNotificationService();
      await pushService.syncWithAiringSchedule(allEpisodes);
      
      setState(() {
        _todayEpisodes = today;
        _upcomingEpisodes = upcoming;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load schedule: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrending() async {
    try {
      final trendingAnime = await _trendingService.getTrendingAnime(count: 10);
      final trendingManga = await _trendingService.getTrendingManga(count: 10);
      final newAnime = await _trendingService.getNewlyAddedAnime(count: 10);
      final newManga = await _trendingService.getNewlyAddedManga(count: 10);
      
      setState(() {
        _trendingAnime = trendingAnime;
        _trendingManga = trendingManga;
        _newlyAddedAnime = newAnime;
        _newlyAddedManga = newManga;
      });
    } catch (e) {
      // Игнорируем ошибки трендов, это не критично
      print('Failed to load trending: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text(
          'Activity',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        actions: [
          // Create activity button (only on Following tab)
          if (_tabController.index == 3 && _socialService != null && _currentUserId != null)
            IconButton(
              icon: const Icon(Icons.add_comment),
              color: AppTheme.textWhite,
              tooltip: 'Create Activity',
              onPressed: () => _createActivity(),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppTheme.textWhite,
            tooltip: 'Notifications',
            onPressed: () {
              final anilistService = AniListService(widget.authService);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(
                    anilistService: anilistService,
                    localStorageService: widget.localStorageService,
                    supabaseService: widget.supabaseService,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: AppTheme.textGray,
          tabs: const [
            Tab(text: 'Airing Schedule'),
            Tab(text: 'Trending'),
            Tab(text: 'Newly Added'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAiringTab(),
          _buildTrendingTab(),
          _buildNewlyAddedTab(),
          _buildFollowingTab(),
        ],
      ),
    );
  }

  Widget _buildAiringTab() {
    return RefreshIndicator(
      onRefresh: _loadSchedule,
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.cardGray,
      child: _buildAiringContent(),
    );
  }

  Widget _buildTrendingTab() {
    return RefreshIndicator(
      onRefresh: _loadTrending,
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.cardGray,
      child: _buildTrendingContent(),
    );
  }

  Widget _buildNewlyAddedTab() {
    return RefreshIndicator(
      onRefresh: _loadTrending,
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.cardGray,
      child: _buildNewlyAddedContent(),
    );
  }

  Widget _buildFollowingTab() {
    if (_socialService == null || _currentUserId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Sign in to see activity from following',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FollowingActivityFeed(
      currentUserId: _currentUserId,
      socialService: _socialService!,
    );
  }
  
  Widget _buildAiringContent() {
    if (_isLoading && _todayEpisodes.isEmpty && _upcomingEpisodes.isEmpty) {
      return const KaomojiLoader(
        message: 'Loading airing schedule...',
      );
    }
    
    if (_error != null) {
      return KaomojiState(
        type: KaomojiType.error,
        message: 'Failed to load schedule',
        subtitle: _error,
        action: ElevatedButton.icon(
          onPressed: _loadSchedule,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
    
    if (_todayEpisodes.isEmpty && _upcomingEpisodes.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: KaomojiState(
              type: KaomojiType.empty,
              message: 'No airing episodes',
              subtitle: 'Add anime to your "Watching" list to see their airing schedule here.\n\n'
                  'Tip: Planned anime will appear 5 days before their first episode airs! 📅',
              action: ElevatedButton.icon(
                onPressed: _loadSchedule,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Today's Releases
        if (_todayEpisodes.isNotEmpty)
          SliverToBoxAdapter(
            child: TodayReleasesSection(episodes: _todayEpisodes),
          ),
        
        // Upcoming Episodes Header
        if (_upcomingEpisodes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: AppTheme.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Episodes',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Upcoming Episodes List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = _upcomingEpisodes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AiringEpisodeCard(
                      episode: episode,
                      authService: widget.authService,
                      onEpisodeAdded: _loadSchedule,
                    ),
                  );
                },
                childCount: _upcomingEpisodes.length,
              ),
            ),
          ),
        ],
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildTrendingContent() {
    if (_trendingAnime.isEmpty && _trendingManga.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: KaomojiState(
              type: KaomojiType.empty,
              message: 'No trending data',
              subtitle: 'Unable to load trending anime and manga.',
              action: ElevatedButton.icon(
                onPressed: _loadTrending,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Trending Anime
        if (_trendingAnime.isNotEmpty)
          SliverToBoxAdapter(
            child: TrendingMediaSection(
              title: 'Trending Anime',
              icon: Icons.trending_up,
              media: _trendingAnime,
              accentColor: AppTheme.accentBlue,
            ),
          ),
        
        // Trending Manga
        if (_trendingManga.isNotEmpty)
          SliverToBoxAdapter(
            child: TrendingMediaSection(
              title: 'Trending Manga',
              icon: Icons.trending_up,
              media: _trendingManga,
              accentColor: AppTheme.accentRed,
            ),
          ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildNewlyAddedContent() {
    if (_newlyAddedAnime.isEmpty && _newlyAddedManga.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: KaomojiState(
              type: KaomojiType.empty,
              message: 'No newly added data',
              subtitle: 'Unable to load newly added anime and manga.',
              action: ElevatedButton.icon(
                onPressed: _loadTrending,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Newly Added Anime
        if (_newlyAddedAnime.isNotEmpty)
          SliverToBoxAdapter(
            child: TrendingMediaSection(
              title: 'Newly Added Anime',
              icon: Icons.new_releases,
              media: _newlyAddedAnime,
              accentColor: Colors.purple,
            ),
          ),
        
        // Newly Added Manga
        if (_newlyAddedManga.isNotEmpty)
          SliverToBoxAdapter(
            child: TrendingMediaSection(
              title: 'Newly Added Manga',
              icon: Icons.new_releases,
              media: _newlyAddedManga,
              accentColor: Colors.orange,
            ),
          ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Future<void> _createActivity() async {
    if (_socialService == null || _currentUserId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateActivityPage(
          socialService: _socialService!,
          currentUserId: _currentUserId,
        ),
      ),
    );

    // If activity was posted, refresh the feed
    if (result == true && mounted) {
      setState(() {
        // This will trigger a rebuild of the Following tab
      });
    }
  }
}
