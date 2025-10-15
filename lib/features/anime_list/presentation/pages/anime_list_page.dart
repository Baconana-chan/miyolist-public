import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/services/crash_reporter.dart';
import '../../../../core/services/conflict_resolver.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/models/sync_conflict.dart';
import '../../../../core/models/view_mode.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/media_card_skeleton.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/media_list_card.dart';
import '../widgets/media_list_view_card.dart';
import '../widgets/media_compact_view_card.dart';
import '../widgets/edit_entry_dialog.dart';
import '../widgets/filter_sort_dialog.dart';
import '../widgets/bulk_edit_dialog.dart';
import '../../models/list_filters.dart';
import '../../../search/presentation/pages/global_search_page.dart';
import '../../../common/widgets/conflict_resolution_dialog.dart';
import '../../../../core/services/anilist_service.dart';

class AnimeListPage extends StatefulWidget {
  final AuthService authService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const AnimeListPage({
    super.key,
    required this.authService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<AnimeListPage> createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Static variable to track last fetch time across widget rebuilds
  static DateTime? _lastFetchTime;
  static const _fetchCooldown = Duration(minutes: 5);
  
  late TabController _tabController;
  late AniListService _anilist;
  late ConflictResolver _conflictResolver;
  List<MediaListEntry> _animeList = [];
  List<MediaListEntry> _mangaList = [];
  List<MediaListEntry> _novelList = [];
  bool _isLoading = true;
  bool _displayAdultContent = false;
  String _selectedAnimeStatus = 'ALL';
  String _selectedMangaStatus = 'ALL';
  String _selectedNovelStatus = 'ALL';

  // Filter and sort
  ListFilters _animeFilters = const ListFilters();
  ListFilters _mangaFilters = const ListFilters();
  ListFilters _novelFilters = const ListFilters();

  // Search management
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Sync management
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  DateTime? _lastModificationTime;
  Timer? _autoSyncTimer;
  final Set<int> _modifiedEntryIds = {}; // Track modified entries
  static const Duration _syncCooldown = Duration(minutes: 1);
  static const Duration _autoSyncDelay = Duration(minutes: 2);

  // Bulk operations
  bool _isSelectionMode = false;
  final Set<int> _selectedEntryIds = {};

  // Pagination
  static const int _pageSize = 50; // Load 50 items at a time
  int _animeLoadedCount = _pageSize;
  int _mangaLoadedCount = _pageSize;
  int _novelLoadedCount = _pageSize;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  final List<String> _statusList = [
    'ALL',
    'CURRENT',
    'PLANNING',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'REPEATING',
  ];

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _anilist = AniListService(widget.authService);
    _conflictResolver = ConflictResolver(
      widget.localStorageService,
      CrashReporter(),
    );
    _conflictResolver.loadSavedStrategy();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    
    // Setup pagination scroll listener
    _scrollController.addListener(_onScroll);
    
    // Only fetch from AniList if cooldown has passed
    final now = DateTime.now();
    if (_lastFetchTime == null || now.difference(_lastFetchTime!) > _fetchCooldown) {
      _fetchLatestFromAniList(); // Auto-fetch on app start
      _lastFetchTime = now;
    } else {
      final remaining = _fetchCooldown - now.difference(_lastFetchTime!);
      debugPrint('⏳ Skipping AniList fetch, cooldown active. ${remaining.inMinutes}m ${remaining.inSeconds % 60}s remaining');
    }
    
    // Слушаем изменения настройки взрослого контента и перезагружаем данные
    LocalStorageService.adultContentFilterNotifier.addListener(_onAdultContentFilterChanged);
  }

  void _initializeTabController() {
    final settings = widget.localStorageService.getUserSettings();
    int tabCount = 0;
    if (settings?.showAnimeTab ?? true) tabCount++;
    if (settings?.showMangaTab ?? true) tabCount++;
    if (settings?.showNovelTab ?? true) tabCount++;
    
    // Ensure at least one tab
    if (tabCount == 0) tabCount = 1;
    
    _tabController = TabController(length: tabCount, vsync: this);
  }

  List<Tab> _getVisibleTabs() {
    final settings = widget.localStorageService.getUserSettings();
    final tabs = <Tab>[];
    
    if (settings?.showAnimeTab ?? true) {
      tabs.add(const Tab(text: 'Anime'));
    }
    if (settings?.showMangaTab ?? true) {
      tabs.add(const Tab(text: 'Manga'));
    }
    if (settings?.showNovelTab ?? true) {
      tabs.add(const Tab(text: 'Light Novels'));
    }
    
    // Ensure at least one tab
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'Anime'));
    }
    
    return tabs;
  }

  List<Widget> _getVisibleTabViews() {
    final settings = widget.localStorageService.getUserSettings();
    final views = <Widget>[];
    
    if (settings?.showAnimeTab ?? true) {
      views.add(_buildListView(_animeList, _selectedAnimeStatus, true, 'anime', _animeFilters));
    }
    if (settings?.showMangaTab ?? true) {
      views.add(_buildListView(_mangaList, _selectedMangaStatus, false, 'manga', _mangaFilters));
    }
    if (settings?.showNovelTab ?? true) {
      views.add(_buildListView(_novelList, _selectedNovelStatus, false, 'novel', _novelFilters));
    }
    
    // Ensure at least one view
    if (views.isEmpty) {
      views.add(_buildListView(_animeList, _selectedAnimeStatus, true, 'anime', _animeFilters));
    }
    
    return views;
  }

  String _getCurrentMediaType() {
    final settings = widget.localStorageService.getUserSettings();
    final currentTab = _tabController.index;
    int tabIndex = 0;
    
    if (settings?.showAnimeTab ?? true) {
      if (currentTab == tabIndex) return 'anime';
      tabIndex++;
    }
    if (settings?.showMangaTab ?? true) {
      if (currentTab == tabIndex) return 'manga';
      tabIndex++;
    }
    if (settings?.showNovelTab ?? true) {
      if (currentTab == tabIndex) return 'novel';
      tabIndex++;
    }
    
    return 'anime'; // Default
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    LocalStorageService.adultContentFilterNotifier.removeListener(_onAdultContentFilterChanged);
    super.dispose();
  }
  
  void _onAdultContentFilterChanged() {
    if (mounted) {
      // Перезагружаем данные при изменении настройки фильтрации
      setState(() {
        _resetPagination('anime');
        _resetPagination('manga'); 
        _resetPagination('novel');
      });
      _loadData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Sync when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_lastModificationTime != null) {
        _syncWithAniList(isAutoSync: true);
      }
    }
  }

  void _markAsModified({int? entryId}) {
    _lastModificationTime = DateTime.now();
    if (entryId != null) {
      _modifiedEntryIds.add(entryId);
    }
    
    // Cancel existing timer
    _autoSyncTimer?.cancel();
    
    // Start new auto-sync timer (2 minutes)
    _autoSyncTimer = Timer(_autoSyncDelay, () {
      if (_lastModificationTime != null) {
        _syncWithAniList(isAutoSync: true);
      }
    });
  }

  bool _canSync() {
    if (_isSyncing) return false;
    if (_lastSyncTime == null) return true;
    
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceLastSync >= _syncCooldown;
  }

  /// Scroll listener for pagination
  void _onScroll() {
    if (_isLoadingMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = maxScroll - currentScroll;
    
    // Load more when 500px from bottom
    if (delta < 500) {
      _loadMoreItems();
    }
  }

  /// Load more items for current tab
  void _loadMoreItems() {
    if (_isLoadingMore) return;
    
    final mediaType = _getCurrentMediaType();
    final List<MediaListEntry> fullList;
    int currentCount;
    
    switch (mediaType) {
      case 'anime':
        fullList = _applyFiltersAndSort(_animeList, _selectedAnimeStatus, _animeFilters);
        currentCount = _animeLoadedCount;
        break;
      case 'manga':
        fullList = _applyFiltersAndSort(_mangaList, _selectedMangaStatus, _mangaFilters);
        currentCount = _mangaLoadedCount;
        break;
      case 'novel':
        fullList = _applyFiltersAndSort(_novelList, _selectedNovelStatus, _novelFilters);
        currentCount = _novelLoadedCount;
        break;
      default:
        return;
    }
    
    // Check if there are more items to load
    if (currentCount >= fullList.length) return;
    
    // Save current scroll position
    final currentScroll = _scrollController.hasClients 
        ? _scrollController.position.pixels 
        : 0.0;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // Simulate slight delay for smooth UX
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      setState(() {
        switch (mediaType) {
          case 'anime':
            _animeLoadedCount = (_animeLoadedCount + _pageSize).clamp(0, fullList.length);
            break;
          case 'manga':
            _mangaLoadedCount = (_mangaLoadedCount + _pageSize).clamp(0, fullList.length);
            break;
          case 'novel':
            _novelLoadedCount = (_novelLoadedCount + _pageSize).clamp(0, fullList.length);
            break;
        }
        _isLoadingMore = false;
      });
      
      // Restore scroll position after rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && currentScroll > 0) {
          _scrollController.jumpTo(currentScroll);
        }
      });
      
      debugPrint('📄 Loaded more items. Total visible: ${currentCount + _pageSize}/${fullList.length}');
    });
  }

  /// Reset pagination when filters/status change
  void _resetPagination(String mediaType) {
    switch (mediaType) {
      case 'anime':
        _animeLoadedCount = _pageSize;
        break;
      case 'manga':
        _mangaLoadedCount = _pageSize;
        break;
      case 'novel':
        _novelLoadedCount = _pageSize;
        break;
    }
    
    // Reset scroll position
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  int _getSecondsUntilNextSync() {
    if (_lastSyncTime == null) return 0;
    
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    final remaining = _syncCooldown - timeSinceLastSync;
    
    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }

  // View mode helpers
  ViewMode _getCurrentViewMode() {
    final settings = widget.localStorageService.getUserSettings();
    final mediaType = _getCurrentMediaType();
    
    switch (mediaType) {
      case 'anime':
        return ViewMode.fromHiveValue(settings?.animeViewMode ?? 'grid');
      case 'manga':
        return ViewMode.fromHiveValue(settings?.mangaViewMode ?? 'grid');
      case 'novel':
        return ViewMode.fromHiveValue(settings?.novelViewMode ?? 'grid');
      default:
        return ViewMode.grid;
    }
  }

  void _changeViewMode(ViewMode mode) async {
    final settings = widget.localStorageService.getUserSettings();
    if (settings == null) return;
    
    final mediaType = _getCurrentMediaType();
    
    // Update settings based on current tab
    final updatedSettings = settings.copyWith(
      animeViewMode: mediaType == 'anime' ? mode.toHiveValue() : null,
      mangaViewMode: mediaType == 'manga' ? mode.toHiveValue() : null,
      novelViewMode: mediaType == 'novel' ? mode.toHiveValue() : null,
    );
    
    await widget.localStorageService.saveUserSettings(updatedSettings);
    
    // Rebuild UI
    setState(() {});
  }

  // Bulk operations methods
  void _selectAll() {
    setState(() {
      final currentTab = _tabController.index;
      final entries = currentTab == 0
          ? _animeList
          : (currentTab == 1 ? _mangaList : _novelList);
      
      _selectedEntryIds.clear();
      _selectedEntryIds.addAll(entries.map((e) => e.id));
    });
  }

  void _toggleSelection(int entryId) {
    setState(() {
      if (_selectedEntryIds.contains(entryId)) {
        _selectedEntryIds.remove(entryId);
      } else {
        _selectedEntryIds.add(entryId);
      }
    });
  }

  Future<void> _showBulkEditDialog() async {
    final currentTab = _tabController.index;
    final isAnime = currentTab == 0;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BulkEditDialog(
        selectedCount: _selectedEntryIds.length,
        isAnime: isAnime,
      ),
    );
    
    if (result != null && mounted) {
      await _applyBulkAction(result);
    }
  }

  Future<void> _applyBulkAction(Map<String, dynamic> actionData) async {
    final action = actionData['action'] as BulkAction;
    final currentTab = _tabController.index;
    
    // Get the appropriate list
    final entries = currentTab == 0
        ? _animeList
        : (currentTab == 1 ? _mangaList : _novelList);
    
    // Filter selected entries
    final selectedEntries = entries.where((e) => _selectedEntryIds.contains(e.id)).toList();
    
    if (selectedEntries.isEmpty) return;
    
    try {
      switch (action) {
        case BulkAction.changeStatus:
          final newStatus = actionData['status'] as String;
          for (final entry in selectedEntries) {
            final updated = entry.copyWith(status: newStatus);
            // Save to appropriate box based on media type
            final format = updated.media?.format?.toUpperCase();
            if (format == 'NOVEL') {
              await widget.localStorageService.mangaListBox.put(updated.id, updated);
            } else if (currentTab == 0) {
              await widget.localStorageService.animeListBox.put(updated.id, updated);
            } else {
              await widget.localStorageService.mangaListBox.put(updated.id, updated);
            }
            _markAsModified(entryId: entry.id);
          }
          break;
          
        case BulkAction.changeScore:
          final newScore = actionData['score'] as double;
          for (final entry in selectedEntries) {
            final updated = entry.copyWith(score: newScore);
            // Save to appropriate box based on media type
            final format = updated.media?.format?.toUpperCase();
            if (format == 'NOVEL') {
              await widget.localStorageService.mangaListBox.put(updated.id, updated);
            } else if (currentTab == 0) {
              await widget.localStorageService.animeListBox.put(updated.id, updated);
            } else {
              await widget.localStorageService.mangaListBox.put(updated.id, updated);
            }
            _markAsModified(entryId: entry.id);
          }
          break;
          
        case BulkAction.delete:
          // Show confirmation
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardGray,
              title: const Text(
                'Confirm Deletion',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Are you sure you want to delete ${selectedEntries.length} items?',
                style: const TextStyle(color: AppTheme.textGray),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          
          if (confirm == true) {
            for (final entry in selectedEntries) {
              // Delete from appropriate box based on media type
              final format = entry.media?.format?.toUpperCase();
              
              if (format == 'NOVEL') {
                await widget.localStorageService.mangaListBox.delete(entry.id);
              } else if (currentTab == 0) {
                await widget.localStorageService.animeListBox.delete(entry.id);
              } else {
                await widget.localStorageService.mangaListBox.delete(entry.id);
              }
              
              _markAsModified(entryId: entry.id);
            }
          }
          break;
      }
      
      // Reload data
      await _loadData();
      
      // Exit selection mode
      setState(() {
        _isSelectionMode = false;
        _selectedEntryIds.clear();
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${selectedEntries.length} items'),
            backgroundColor: AppTheme.accentBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load from local storage first - create defensive copies
      final animeListRaw = widget.localStorageService.getAnimeList();
      final mangaListRaw = widget.localStorageService.getMangaList();
      
      // Create defensive copies to prevent mutations
      final animeList = List<MediaListEntry>.from(animeListRaw);
      
      // Separate manga and light novels by format
      final mangaList = <MediaListEntry>[];
      final novelList = <MediaListEntry>[];
      
      for (final entry in mangaListRaw) {
        final format = entry.media?.format?.toUpperCase();
        if (format == 'NOVEL') {
          novelList.add(entry);
        } else {
          mangaList.add(entry);
        }
      }
      
      // Get user's adult content setting (combines local settings with AniList)
      final shouldHideAdult = widget.localStorageService.shouldHideAdultContent();
      
      setState(() {
        _animeList = animeList;
        _mangaList = mangaList;
        _novelList = novelList;
        _displayAdultContent = !shouldHideAdult;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading data: $e');
      CrashReporter().log(
        'Failed to load data from local storage',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      setState(() => _isLoading = false);
    }
  }

  /// Fetch latest data from AniList in the background
  /// This ensures custom lists and other updates are loaded on app start
  Future<void> _fetchLatestFromAniList({bool showNotification = false}) async {
    try {
      // Update last fetch time when manually triggered
      if (showNotification) {
        _lastFetchTime = DateTime.now();
      }
      
      final user = widget.localStorageService.getUser();
      if (user == null) {
        debugPrint('⚠️ No user found, skipping AniList fetch');
        return;
      }

      debugPrint('🔄 Fetching latest data from AniList in background...');

      if (showNotification && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updating data from AniList...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Fetch all media lists in a single optimized query
      final allMediaLists = await _anilist.fetchAllMediaLists(user.id);
      
      // Process anime list
      final animeListData = allMediaLists['anime'];
      if (animeListData != null && animeListData.isNotEmpty) {
        final animeList = animeListData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return MediaListEntry.fromJson(e);
                } else {
                  debugPrint('⚠️ Unexpected anime entry type: ${e.runtimeType}');
                  debugPrint('⚠️ Entry data: $e');
                  return null;
                }
              } catch (err, stackTrace) {
                debugPrint('! Error parsing anime entry: $err');
                debugPrint('Stack trace: $stackTrace');
                return null;
              }
            })
            .whereType<MediaListEntry>()
            .toList();
        
        if (animeList.isNotEmpty) {
          await widget.localStorageService.saveAnimeList(animeList);
          debugPrint('✅ Anime list updated: ${animeList.length} entries');
        }
      } else {
        debugPrint('⚠️ No anime data fetched from AniList (will use local data)');
      }

      // Process manga list (includes novels)
      final mangaListData = allMediaLists['manga'];
      if (mangaListData != null && mangaListData.isNotEmpty) {
        final mangaList = mangaListData
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return MediaListEntry.fromJson(e);
                } else {
                  debugPrint('⚠️ Unexpected manga entry type: ${e.runtimeType}');
                  debugPrint('⚠️ Entry data: $e');
                  return null;
                }
              } catch (err, stackTrace) {
                debugPrint('! Error parsing manga entry: $err');
                debugPrint('Stack trace: $stackTrace');
                return null;
              }
            })
            .whereType<MediaListEntry>()
            .toList();
        
        if (mangaList.isNotEmpty) {
          await widget.localStorageService.saveMangaList(mangaList);
          debugPrint('✅ Manga/Novel list updated: ${mangaList.length} entries');
        }
      } else {
        debugPrint('⚠️ No manga data fetched from AniList (will use local data)');
      }

      // Reload data to UI
      await _loadData();
      
      // Download cover images in background
      _downloadCoverImagesInBackground();

      debugPrint('✅ Background fetch from AniList complete');

      if (showNotification && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Data updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Background fetch from AniList failed (non-critical): $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue execution - local data is still available
      
      if (showNotification && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle pull-to-refresh gesture
  Future<void> _handlePullToRefresh() async {
    debugPrint('🔄 Pull-to-refresh triggered');
    
    // Fetch latest data from AniList
    await _fetchLatestFromAniList(showNotification: false);
    
    // Reload local data
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ List refreshed'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<MediaListEntry> _filterByStatus(List<MediaListEntry> list, String status) {
    print('🔍 Filtering by status: $status');
    print('📊 Total entries before filter: ${list.length}');
    
    // Debug: Print status distribution
    final statusCounts = <String, int>{};
    for (final entry in list) {
      final entryStatus = entry.status;
      statusCounts[entryStatus] = (statusCounts[entryStatus] ?? 0) + 1;
    }
    print('📈 Status distribution: $statusCounts');
    
    // If "ALL" is selected, don't filter by status
    var filtered = status == 'ALL' 
        ? list 
        : list.where((entry) {
            final match = entry.status == status;
            if (!match && list.indexOf(entry) < 3) {
              print('❌ Entry "${entry.media?.titleRomaji}" has status "${entry.status}", not "$status"');
            }
            return match;
          }).toList();
    
    print('✅ Entries after status filter: ${filtered.length}');
    
    // Filter adult content if user has it disabled
    if (!_displayAdultContent) {
      filtered = filtered.where((entry) {
        return entry.media?.isAdult != true;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((entry) {
        final titleRomaji = entry.media?.titleRomaji.toLowerCase() ?? '';
        final titleEnglish = entry.media?.titleEnglish?.toLowerCase() ?? '';
        final titleNative = entry.media?.titleNative?.toLowerCase() ?? '';
        
        return titleRomaji.contains(query) ||
               titleEnglish.contains(query) ||
               titleNative.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  List<String> _getAllCustomLists(List<MediaListEntry> list) {
    final Set<String> allLists = {};
    
    for (final entry in list) {
      if (entry.customLists != null) {
        allLists.addAll(entry.customLists!);
      }
    }
    
    final sortedLists = allLists.toList()..sort();
    return sortedLists;
  }

  List<MediaListEntry> _applyFiltersAndSort(
    List<MediaListEntry> list,
    String status,
    ListFilters filters,
  ) {
    // First filter by status and search
    var filtered = _filterByStatus(list, status);

    // Apply format filter
    if (filters.formats.isNotEmpty) {
      filtered = filtered.where((entry) {
        final format = entry.media?.format?.toUpperCase();
        return format != null && filters.formats.contains(format);
      }).toList();
    }

    // Apply media status filter
    if (filters.mediaStatuses.isNotEmpty) {
      filtered = filtered.where((entry) {
        final mediaStatus = entry.media?.status?.toUpperCase();
        return mediaStatus != null && filters.mediaStatuses.contains(mediaStatus);
      }).toList();
    }

    // Apply genre filter
    if (filters.genres.isNotEmpty) {
      filtered = filtered.where((entry) {
        final genres = entry.media?.genres ?? [];
        return filters.genres.any((filterGenre) => 
          genres.contains(filterGenre));
      }).toList();
    }

    // Apply country filter
    if (filters.countries.isNotEmpty) {
      filtered = filtered.where((entry) {
        final country = entry.media?.countryOfOrigin;
        return country != null && filters.countries.contains(country);
      }).toList();
    }

    // Apply custom lists filter
    if (filters.customLists.isNotEmpty) {
      filtered = filtered.where((entry) {
        final entryCustomLists = entry.customLists ?? [];
        // Entry must be in at least one of the selected custom lists
        return filters.customLists.any((filterList) => 
          entryCustomLists.contains(filterList));
      }).toList();
    }

    // Apply year filter
    if (filters.startYear != null || filters.endYear != null) {
      filtered = filtered.where((entry) {
        final year = entry.media?.startDate?.year;
        if (year == null) return false;
        
        if (filters.startYear != null && year < filters.startYear!) {
          return false;
        }
        if (filters.endYear != null && year > filters.endYear!) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    filtered = _sortList(filtered, filters.sortOption, filters.ascending);

    return filtered;
  }

  List<MediaListEntry> _sortList(
    List<MediaListEntry> list,
    SortOption sortOption,
    bool ascending,
  ) {
    final sorted = List<MediaListEntry>.from(list);

    switch (sortOption) {
      case SortOption.title:
        sorted.sort((a, b) {
          final titleA = a.media?.titleRomaji ?? '';
          final titleB = b.media?.titleRomaji ?? '';
          return ascending 
              ? titleA.compareTo(titleB)
              : titleB.compareTo(titleA);
        });
        break;

      case SortOption.score:
        sorted.sort((a, b) {
          final scoreA = a.score ?? 0;
          final scoreB = b.score ?? 0;
          return ascending
              ? scoreA.compareTo(scoreB)
              : scoreB.compareTo(scoreA);
        });
        break;

      case SortOption.progress:
        sorted.sort((a, b) {
          final progressA = a.progress;
          final progressB = b.progress;
          return ascending
              ? progressA.compareTo(progressB)
              : progressB.compareTo(progressA);
        });
        break;

      case SortOption.lastUpdated:
        sorted.sort((a, b) {
          final dateA = a.updatedAt ?? DateTime(1970);
          final dateB = b.updatedAt ?? DateTime(1970);
          return ascending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
        break;

      case SortOption.lastAdded:
        // Use updatedAt for last added (entry creation time)
        sorted.sort((a, b) {
          final dateA = a.updatedAt ?? DateTime(1970);
          final dateB = b.updatedAt ?? DateTime(1970);
          return ascending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
        break;

      case SortOption.startDate:
        sorted.sort((a, b) {
          final dateA = a.startedAt ?? DateTime(1970);
          final dateB = b.startedAt ?? DateTime(1970);
          return ascending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
        break;

      case SortOption.completedDate:
        sorted.sort((a, b) {
          final dateA = a.completedAt ?? DateTime(1970);
          final dateB = b.completedAt ?? DateTime(1970);
          return ascending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
        break;

      case SortOption.releaseDate:
        sorted.sort((a, b) {
          final dateA = a.media?.startDate ?? DateTime(1970);
          final dateB = b.media?.startDate ?? DateTime(1970);
          return ascending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
        break;

      case SortOption.averageScore:
        sorted.sort((a, b) {
          final scoreA = a.media?.averageScore ?? 0;
          final scoreB = b.media?.averageScore ?? 0;
          return ascending
              ? scoreA.compareTo(scoreB)
              : scoreB.compareTo(scoreA);
        });
        break;

      case SortOption.popularity:
        sorted.sort((a, b) {
          final popA = a.media?.popularity ?? 0;
          final popB = b.media?.popularity ?? 0;
          return ascending
              ? popA.compareTo(popB)
              : popB.compareTo(popA);
        });
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedEntryIds.length} selected')
            : (_isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search in list...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : const Text('MiyoList')),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Select all',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _selectedEntryIds.isNotEmpty ? _showBulkEditDialog : null,
              tooltip: 'Bulk edit',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedEntryIds.clear();
                });
              },
              tooltip: 'Cancel',
            ),
          ] else if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              tooltip: 'Close search',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              tooltip: 'Search in list',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter & Sort',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _fetchLatestFromAniList(showNotification: true),
              tooltip: 'Refresh from AniList',
            ),
            // More options menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) {
                switch (value) {
                  case 'view_grid':
                    _changeViewMode(ViewMode.grid);
                    break;
                  case 'view_list':
                    _changeViewMode(ViewMode.list);
                    break;
                  case 'view_compact':
                    _changeViewMode(ViewMode.compact);
                    break;
                  case 'bulk_operations':
                    setState(() {
                      _isSelectionMode = true;
                    });
                    break;
                  case 'global_search':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GlobalSearchPage(),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view_grid',
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_view,
                        color: _getCurrentViewMode() == ViewMode.grid
                            ? AppTheme.accentBlue
                            : AppTheme.textGray,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Grid View',
                        style: TextStyle(
                          color: _getCurrentViewMode() == ViewMode.grid
                              ? AppTheme.accentBlue
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'view_list',
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_list,
                        color: _getCurrentViewMode() == ViewMode.list
                            ? AppTheme.accentBlue
                            : AppTheme.textGray,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'List View',
                        style: TextStyle(
                          color: _getCurrentViewMode() == ViewMode.list
                              ? AppTheme.accentBlue
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'view_compact',
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_headline,
                        color: _getCurrentViewMode() == ViewMode.compact
                            ? AppTheme.accentBlue
                            : AppTheme.textGray,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Compact View',
                        style: TextStyle(
                          color: _getCurrentViewMode() == ViewMode.compact
                              ? AppTheme.accentBlue
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'bulk_operations',
                  child: Row(
                    children: [
                      Icon(Icons.checklist, color: AppTheme.textGray),
                      SizedBox(width: 12),
                      Text('Bulk Operations'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'global_search',
                  child: Row(
                    children: [
                      Icon(Icons.public, color: AppTheme.textGray),
                      SizedBox(width: 12),
                      Text('Global Search'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.sync,
                    color: _canSync() ? null : Colors.grey,
                  ),
            onPressed: _canSync() && !_isSyncing ? _syncData : null,
            tooltip: _isSyncing
                ? 'Syncing...'
                : _canSync()
                    ? 'Sync with AniList'
                    : 'Wait ${_getSecondsUntilNextSync()}s',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _getVisibleTabs(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _getVisibleTabViews(),
            ),
    );
  }

  Future<void> _showFilterDialog() async {
    // Determine media type based on current visible tab
    final mediaType = _getCurrentMediaType();
    ListFilters currentFilters;
    
    switch (mediaType) {
      case 'anime':
        currentFilters = _animeFilters;
        break;
      case 'manga':
        currentFilters = _mangaFilters;
        break;
      case 'novel':
        currentFilters = _novelFilters;
        break;
      default:
        currentFilters = const ListFilters();
    }

    // Get all custom lists from current tab's entries
    final List<MediaListEntry> currentList;
    switch (mediaType) {
      case 'anime':
        currentList = _animeList;
        break;
      case 'manga':
        currentList = _mangaList;
        break;
      case 'novel':
        currentList = _novelList;
        break;
      default:
        currentList = [];
    }
    final availableCustomLists = _getAllCustomLists(currentList);

    final result = await showDialog<ListFilters>(
      context: context,
      builder: (context) => FilterSortDialog(
        initialFilters: currentFilters,
        mediaType: mediaType,
        availableCustomLists: availableCustomLists,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        switch (mediaType) {
          case 'anime':
            _animeFilters = result;
            _resetPagination('anime');
            break;
          case 'manga':
            _mangaFilters = result;
            _resetPagination('manga');
            break;
          case 'novel':
            _novelFilters = result;
            _resetPagination('novel');
            break;
        }
      });
    }
  }

  Widget _buildListView(
    List<MediaListEntry> list,
    String selectedStatus,
    bool isAnime,
    String tabType,
    ListFilters filters,
  ) {
    return Column(
      children: [
        // Status filter
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statusList.length,
            itemBuilder: (context, index) {
              final status = _statusList[index];
              final isSelected = status == selectedStatus;
              final isAllStatus = status == 'ALL';
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: isAllStatus && isSelected
                    ? _buildAllStatusChip(isAnime)
                    : FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAllStatus) ...[
                              const Icon(Icons.grid_view, size: 16),
                              const SizedBox(width: 4),
                            ],
                            Text(_formatStatus(status, isAnime)),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          // Ignore if already selected
                          if (isSelected) return;
                          
                          setState(() {
                            if (tabType == 'anime') {
                              _selectedAnimeStatus = status;
                              _resetPagination('anime');
                            } else if (tabType == 'manga') {
                              _selectedMangaStatus = status;
                              _resetPagination('manga');
                            } else if (tabType == 'novel') {
                              _selectedNovelStatus = status;
                              _resetPagination('novel');
                            }
                          });
                        },
                        selectedColor: _getStatusColor(status),
                        backgroundColor: AppTheme.cardGray,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textGray,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
              );
            },
          ),
        ),
        
        // Filter indicator
        if (filters.hasActiveFilters)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.accentBlue.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 16, color: AppTheme.accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getActiveFiltersText(filters),
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (tabType == 'anime') {
                        _animeFilters = const ListFilters();
                        _resetPagination('anime');
                      } else if (tabType == 'manga') {
                        _mangaFilters = const ListFilters();
                        _resetPagination('manga');
                      } else if (tabType == 'novel') {
                        _novelFilters = const ListFilters();
                        _resetPagination('novel');
                      }
                    });
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppTheme.accentBlue),
                  ),
                ),
              ],
            ),
          ),
        
        // Search indicator
        if (_searchQuery.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.accentRed.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppTheme.accentRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Searching: "$_searchQuery"',
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _isSearching = false;
                    });
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppTheme.accentRed),
                  ),
                ),
              ],
            ),
          ),
        
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _handlePullToRefresh(),
            color: AppTheme.accentBlue,
            backgroundColor: AppTheme.cardGray,
            child: _buildMediaGrid(
              _applyFiltersAndSort(list, selectedStatus, filters),
              isAnime,
              selectedStatus == 'ALL',
            ),
          ),
        ),
      ],
    );
  }

  String _getActiveFiltersText(ListFilters filters) {
    final parts = <String>[];
    
    if (filters.formats.isNotEmpty) {
      parts.add('${filters.formats.length} format(s)');
    }
    if (filters.mediaStatuses.isNotEmpty) {
      parts.add('${filters.mediaStatuses.length} status(es)');
    }
    if (filters.genres.isNotEmpty) {
      parts.add('${filters.genres.length} genre(s)');
    }
    if (filters.countries.isNotEmpty) {
      parts.add('${filters.countries.length} country(ies)');
    }
    if (filters.startYear != null || filters.endYear != null) {
      if (filters.startYear != null && filters.endYear != null) {
        parts.add('${filters.startYear}-${filters.endYear}');
      } else if (filters.startYear != null) {
        parts.add('from ${filters.startYear}');
      } else {
        parts.add('until ${filters.endYear}');
      }
    }
    
    final filterText = parts.isEmpty ? 'Filters active' : parts.join(', ');
    final sortText = filters.sortOption != SortOption.title 
        ? ' • Sorted by ${filters.sortOption.label}'
        : '';
    
    return '$filterText$sortText';
  }

  Widget _buildMediaGrid(List<MediaListEntry> entries, bool isAnime, bool showStatusIndicator) {
    // Debug: Log what we're about to display
    print('🎨 Building grid with ${entries.length} entries');
    if (entries.isNotEmpty && entries.length <= 5) {
      for (final entry in entries) {
        print('  - ${entry.media?.titleRomaji} (${entry.status})');
      }
    }
    
    // Show skeleton during initial loading
    if (_isLoading) {
      return const MediaGridSkeleton(itemCount: 12);
    }
    
    // Enhanced empty states
    if (entries.isEmpty) {
      // Check if it's due to search
      if (_searchQuery.isNotEmpty) {
        return EmptyStateWidget.noSearchResults(
          query: _searchQuery,
          onClearSearch: () {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
              _isSearching = false;
            });
          },
        );
      }
      
      // Check if it's due to filters
      final currentTab = _tabController.index;
      final hasActiveFilters = currentTab == 0
          ? _animeFilters.hasActiveFilters
          : (currentTab == 1
              ? _mangaFilters.hasActiveFilters
              : _novelFilters.hasActiveFilters);
      
      if (hasActiveFilters) {
        return EmptyStateWidget.noFilterResults(
          onClearFilters: () {
            setState(() {
              if (currentTab == 0) {
                _animeFilters = ListFilters();
                _resetPagination('anime');
              } else if (currentTab == 1) {
                _mangaFilters = ListFilters();
                _resetPagination('manga');
              } else {
                _novelFilters = ListFilters();
                _resetPagination('novel');
              }
            });
          },
        );
      }
      
      // Check if it's a specific status with no entries
      final currentStatus = currentTab == 0
          ? _selectedAnimeStatus
          : (currentTab == 1 ? _selectedMangaStatus : _selectedNovelStatus);
      
      if (currentStatus != 'ALL') {
        final statusName = _formatStatus(currentStatus, isAnime);
        return EmptyStateWidget.noEntriesInStatus(
          statusName: statusName,
          isAnime: isAnime,
        );
      }
      
      // Default: completely empty list (new user)
      return EmptyStateWidget.noEntriesAtAll(isAnime: isAnime);
    }

    // Apply pagination - only show loaded items
    final mediaType = _getCurrentMediaType();
    int loadedCount;
    switch (mediaType) {
      case 'anime':
        loadedCount = _animeLoadedCount;
        break;
      case 'manga':
        loadedCount = _mangaLoadedCount;
        break;
      case 'novel':
        loadedCount = _novelLoadedCount;
        break;
      default:
        loadedCount = _pageSize;
    }
    
    final totalCount = entries.length;
    final displayEntries = entries.take(loadedCount).toList();
    final hasMore = loadedCount < totalCount;
    
    print('📄 Pagination: showing $loadedCount of $totalCount items (hasMore: $hasMore)');

    // Get current view mode
    final viewMode = _getCurrentViewMode();
    
    // Build based on view mode
    switch (viewMode) {
      case ViewMode.grid:
        return _buildGridView(displayEntries, isAnime, showStatusIndicator, hasMore: hasMore);
      case ViewMode.list:
        return _buildListViewMode(displayEntries, isAnime, showStatusIndicator, hasMore: hasMore);
      case ViewMode.compact:
        return _buildCompactView(displayEntries, isAnime, showStatusIndicator, hasMore: hasMore);
    }
  }

  Widget _buildGridView(List<MediaListEntry> entries, bool isAnime, bool showStatusIndicator, {bool hasMore = false}) {
    return GridView.builder(
      key: ValueKey('grid_${entries.length}_${entries.hashCode}'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even with few items
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200, // Максимальная ширина карточки (~6 карточек на Full HD)
        childAspectRatio: 0.67, // Соотношение сторон (460x690 ≈ 0.67)
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: entries.length + (hasMore ? 1 : 0), // +1 for loading indicator
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == entries.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: AppTheme.accentBlue,
              ),
            ),
          );
        }
        
        final entry = entries[index];
        return MediaListCard(
          key: ValueKey(entry.id),
          entry: entry,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(entry.id);
            } else {
              _showEditDialog(entry, isAnime);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedEntryIds.add(entry.id);
              });
            }
          },
          showStatusIndicator: showStatusIndicator,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedEntryIds.contains(entry.id),
        );
      },
    );
  }

  Widget _buildListViewMode(List<MediaListEntry> entries, bool isAnime, bool showStatusIndicator, {bool hasMore = false}) {
    return ListView.builder(
      key: ValueKey('list_${entries.length}_${entries.hashCode}'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == entries.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: AppTheme.accentBlue,
              ),
            ),
          );
        }
        
        final entry = entries[index];
        return MediaListViewCard(
          key: ValueKey(entry.id),
          entry: entry,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(entry.id);
            } else {
              _showEditDialog(entry, isAnime);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedEntryIds.add(entry.id);
              });
            }
          },
          showStatusIndicator: showStatusIndicator,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedEntryIds.contains(entry.id),
        );
      },
    );
  }

  Widget _buildCompactView(List<MediaListEntry> entries, bool isAnime, bool showStatusIndicator, {bool hasMore = false}) {
    return ListView.builder(
      key: ValueKey('compact_${entries.length}_${entries.hashCode}'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == entries.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: AppTheme.accentBlue,
              ),
            ),
          );
        }
        
        final entry = entries[index];
        return MediaCompactViewCard(
          key: ValueKey(entry.id),
          entry: entry,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(entry.id);
            } else {
              _showEditDialog(entry, isAnime);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedEntryIds.add(entry.id);
              });
            }
          },
          showStatusIndicator: showStatusIndicator,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedEntryIds.contains(entry.id),
        );
      },
    );
  }

  String _formatStatus(String status, bool isAnime) {
    switch (status) {
      case 'ALL':
        return 'All';
      case 'CURRENT':
        return isAnime ? 'Watching' : 'Reading';
      case 'PLANNING':
        return isAnime ? 'Plan to Watch' : 'Plan to Read';
      case 'COMPLETED':
        return 'Completed';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      case 'REPEATING':
        return isAnime ? 'Rewatching' : 'Rereading';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ALL':
        return AppTheme.accentBlue;
      case 'CURRENT':
        return const Color(0xFF4CAF50); // Зелёный - смотрю/читаю
      case 'PLANNING':
        return const Color(0xFF2196F3); // Синий - планирую
      case 'COMPLETED':
        return const Color(0xFF9C27B0); // Фиолетовый - завершено
      case 'PAUSED':
        return const Color(0xFFFF9800); // Оранжевый - на паузе
      case 'DROPPED':
        return const Color(0xFFF44336); // Красный - брошено
      case 'REPEATING':
        return const Color(0xFF00BCD4); // Голубой - пересматриваю
      default:
        return AppTheme.accentBlue;
    }
  }

  Widget _buildAllStatusChip(bool isAnime) {
    return GestureDetector(
      onTap: () {
        // Already selected, no action needed
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor('CURRENT'),      // Зелёный
              _getStatusColor('PLANNING'),     // Синий
              _getStatusColor('COMPLETED'),    // Фиолетовый
              _getStatusColor('PAUSED'),       // Оранжевый
              _getStatusColor('DROPPED'),      // Красный
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.grid_view,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            const Text(
              'All',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncData() async {
    if (!_canSync()) {
      final secondsRemaining = _getSecondsUntilNextSync();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait $secondsRemaining seconds before syncing again'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // First, push local changes to AniList
    await _syncWithAniList(isAutoSync: false);
    
    // Then, fetch latest data from AniList (including custom lists)
    await _fetchLatestFromAniList(showNotification: false);
  }

  Future<void> _syncWithAniList({required bool isAutoSync}) async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      if (!isAutoSync) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syncing with AniList...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get user info
      final user = widget.localStorageService.getUser();
      if (user == null) {
        throw Exception('User not found');
      }

      // Sync modified entries to AniList API
      if (_modifiedEntryIds.isNotEmpty) {
        debugPrint('📤 Syncing ${_modifiedEntryIds.length} modified entries to AniList...');
        
        final allEntries = [..._animeList, ..._mangaList, ..._novelList];
        int successCount = 0;
        int failCount = 0;

        for (final entryId in _modifiedEntryIds) {
          try {
            final entry = allEntries.firstWhere((e) => e.id == entryId);
            
            // Update in AniList
            final result = await _anilist.updateMediaListEntry(
              entryId: entry.id,
              status: entry.status,
              score: entry.score,
              progress: entry.progress,
              progressVolumes: entry.progressVolumes,
              notes: entry.notes,
              customLists: entry.customLists,
            );

            if (result != null) {
              successCount++;
              debugPrint('✅ Entry ${entry.id} synced to AniList');
            } else {
              failCount++;
              debugPrint('❌ Failed to sync entry ${entry.id} to AniList');
            }
          } catch (e) {
            failCount++;
            debugPrint('❌ Error syncing entry $entryId: $e');
          }
        }

        debugPrint('📊 AniList sync complete: $successCount success, $failCount failed');
        
        // Clear modified entries after successful sync
        if (successCount > 0) {
          _modifiedEntryIds.clear();
        }
      }

      // Sync anime list with Supabase (if enabled)
      if (widget.localStorageService.isCloudSyncEnabled()) {
        try {
          // Get user settings for selective sync
          final settings = widget.localStorageService.getUserSettings();
          
          // Check if any sync is enabled
          final shouldSyncAnime = settings?.syncAnimeList ?? true;
          final shouldSyncManga = settings?.syncMangaList ?? true;
          
          if (!shouldSyncAnime && !shouldSyncManga) {
            debugPrint('⏭️ Skipping list sync - all list sync disabled in settings');
          } else {
            // Check for conflicts before syncing
            List<SyncConflict> animeConflicts = [];
            List<SyncConflict> mangaConflicts = [];
            
            if (shouldSyncAnime) {
              final cloudAnimeData = await widget.supabaseService.fetchAnimeList(user.id);
              animeConflicts = await _conflictResolver.detectConflicts(
                localEntries: _animeList,
                cloudEntries: cloudAnimeData,
                anilistEntries: _animeList, // Use current AniList state
              );
            }
            
            if (shouldSyncManga) {
              final cloudMangaData = await widget.supabaseService.fetchMangaList(user.id);
              final combinedMangaList = [..._mangaList, ..._novelList];
              mangaConflicts = await _conflictResolver.detectConflicts(
                localEntries: combinedMangaList,
                cloudEntries: cloudMangaData,
                anilistEntries: combinedMangaList,
              );
            }
            
            final allConflicts = [...animeConflicts, ...mangaConflicts];
            
            if (allConflicts.isNotEmpty) {
              debugPrint('⚠️ Detected ${allConflicts.length} sync conflicts');
              
              // Check resolution strategy
              final strategy = _conflictResolver.defaultStrategy;
              
              if (strategy == ConflictResolutionStrategy.manual) {
                // Show conflict resolution dialog
                if (!isAutoSync && mounted) {
                  await _showConflictResolutionDialog(allConflicts);
                } else {
                  // Auto-sync with conflicts: use last-write-wins
                  debugPrint('🔧 Auto-resolving conflicts with Last-Write-Wins');
                  final resolutions = await _conflictResolver.resolveConflicts(
                    conflicts: allConflicts,
                    strategy: ConflictResolutionStrategy.lastWriteWins,
                  );
                  await _applyResolvedConflicts(resolutions);
                }
              } else {
                // Auto-resolve with selected strategy
                debugPrint('🔧 Auto-resolving conflicts with ${strategy.name}');
                final resolutions = await _conflictResolver.resolveConflicts(
                  conflicts: allConflicts,
                  strategy: strategy,
                );
                await _applyResolvedConflicts(resolutions);
              }
            }
            
            // Sync with metadata
            final metadata = SyncMetadata.current(SyncSource.app);
            
            // Sync anime list (if enabled)
            if (shouldSyncAnime) {
              final animeListJson = _animeList.map((e) => e.toSupabaseJson(isManga: false)).toList();
              await widget.supabaseService.syncAnimeList(user.id, animeListJson, metadata: metadata);
              debugPrint('☁️ Anime list synced to cloud');
            } else {
              debugPrint('⏭️ Skipping anime list sync - disabled in settings');
            }
            
            // Sync manga list (if enabled)
            if (shouldSyncManga) {
              final combinedMangaList = [..._mangaList, ..._novelList];
              final mangaListJson = combinedMangaList.map((e) => e.toSupabaseJson(isManga: true)).toList();
              await widget.supabaseService.syncMangaList(user.id, mangaListJson, metadata: metadata);
              debugPrint('☁️ Manga list synced to cloud');
            } else {
              debugPrint('⏭️ Skipping manga list sync - disabled in settings');
            }
          }
        } catch (e) {
          debugPrint('Cloud sync failed (non-critical): $e');
          CrashReporter().log(
            'Cloud sync error: $e',
            level: LogLevel.error,
          );
        }
      }

      // Download cover images in background after successful sync
      _downloadCoverImagesInBackground();

      _lastSyncTime = DateTime.now();
      _lastModificationTime = null; // Reset modification time
      _autoSyncTimer?.cancel(); // Cancel auto-sync timer

      if (!isAutoSync && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Synced successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!isAutoSync && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _showEditDialog(MediaListEntry entry, bool isAnime) async {
    await showDialog(
      context: context,
      builder: (context) => EditEntryDialog(
        entry: entry,
        isAnime: isAnime,
        onSave: (updatedEntry) async {
          try {
            // Update in local storage
            if (isAnime) {
              await widget.localStorageService.updateAnimeEntry(updatedEntry);
            } else {
              await widget.localStorageService.updateMangaEntry(updatedEntry);
            }

            // Mark as modified for auto-sync
            _markAsModified(entryId: updatedEntry.id);

            // Reload data from storage to ensure consistency
            await _loadData();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating entry: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onDelete: () async {
          try {
            // Delete from local storage
            if (isAnime) {
              await widget.localStorageService.deleteAnimeEntry(entry.id);
            } else {
              await widget.localStorageService.deleteMangaEntry(entry.id);
            }

            // Mark as modified for auto-sync
            _markAsModified(entryId: entry.id);

            // Refresh the list
            if (mounted) {
              setState(() {
                if (isAnime) {
                  _animeList.removeWhere((e) => e.id == entry.id);
                } else {
                  // Check if it's a novel or manga
                  final isNovel = entry.media?.format?.toUpperCase() == 'NOVEL';
                  
                  if (isNovel) {
                    _novelList.removeWhere((e) => e.id == entry.id);
                  } else {
                    _mangaList.removeWhere((e) => e.id == entry.id);
                  }
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting entry: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onAddToFavorites: () {
          // TODO: Implement add to favorites functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add to favorites feature coming soon!'),
            ),
          );
        },
      ),
    );
  }

  /// Download cover images for all list entries in background
  Future<void> _downloadCoverImagesInBackground() async {
    try {
      final imageCache = ImageCacheService();
      final allMedia = <({int mediaId, String? coverUrl})>[];

      // Collect all media from lists
      for (final entry in _animeList) {
        if (entry.media?.id != null && entry.media?.coverImage != null) {
          allMedia.add((mediaId: entry.media!.id, coverUrl: entry.media!.coverImage));
        }
      }
      for (final entry in _mangaList) {
        if (entry.media?.id != null && entry.media?.coverImage != null) {
          allMedia.add((mediaId: entry.media!.id, coverUrl: entry.media!.coverImage));
        }
      }
      for (final entry in _novelList) {
        if (entry.media?.id != null && entry.media?.coverImage != null) {
          allMedia.add((mediaId: entry.media!.id, coverUrl: entry.media!.coverImage));
        }
      }

      // Download in background (non-blocking)
      imageCache.downloadBatch(allMedia).then((_) {
        // Success message is now printed inside downloadBatch
      }).catchError((e) {
        debugPrint('⚠️ Error downloading images: $e');
      });
    } catch (e) {
      debugPrint('⚠️ Error preparing image downloads: $e');
    }
  }

  /// Show conflict resolution dialog
  Future<void> _showConflictResolutionDialog(List<SyncConflict> conflicts) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictResolutionDialog(
        conflicts: conflicts,
        onResolve: (resolvedEntries) async {
          // Convert to conflict resolutions
          final resolutions = conflicts.asMap().entries.map((entry) {
            return ConflictResolution(
              resolvedEntry: resolvedEntries[entry.key],
              metadata: SyncMetadata.current(SyncSource.app),
              usedStrategy: ConflictResolutionStrategy.manual,
            );
          }).toList();
          
          await _applyResolvedConflicts(resolutions);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${conflicts.length} conflicts resolved'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync cancelled. Please resolve conflicts later.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  /// Apply resolved conflicts to local lists
  Future<void> _applyResolvedConflicts(List<ConflictResolution> resolutions) async {
    for (final resolution in resolutions) {
      final entry = resolution.resolvedEntry;
      
      // Determine if anime or manga
      final isAnime = entry.media?.format?.toUpperCase() == 'ANIME' ||
          entry.media?.format?.toUpperCase() == 'TV' ||
          entry.media?.format?.toUpperCase() == 'MOVIE' ||
          entry.media?.format?.toUpperCase() == 'OVA' ||
          entry.media?.format?.toUpperCase() == 'ONA' ||
          entry.media?.format?.toUpperCase() == 'SPECIAL' ||
          entry.media?.format?.toUpperCase() == 'MUSIC';
      
      // Update local storage
      if (isAnime) {
        await widget.localStorageService.updateAnimeEntry(entry);
      } else {
        await widget.localStorageService.updateMangaEntry(entry);
      }
    }
    
    // Reload all data from storage after applying resolutions
    await _loadData();
    
    debugPrint('✅ Applied ${resolutions.length} conflict resolutions');
  }
}
