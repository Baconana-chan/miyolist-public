import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/activity_tracking_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../models/user_statistics.dart';
import '../../services/chart_export_service.dart';
import '../../utils/statistics_data_helper.dart';

class StatisticsPage extends StatefulWidget {
  final LocalStorageService localStorageService;
  final AniListService? anilistService;

  const StatisticsPage({
    super.key,
    required this.localStorageService,
    this.anilistService,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  
  final ActivityTrackingService _activityService = ActivityTrackingService();
  final ChartExportService _exportService = ChartExportService();
  
  UserStatistics? _stats;
  Map<String, dynamic> _activityStats = {};
  Map<DateTime, int> _activityByDate = {};
  Map<String, dynamic> _extendedStats = {}; // Studios, VA, Staff
  bool _isLoading = true;
  bool _isLoadingExtended = false;
  
  // Activity period filter (days)
  int _selectedPeriod = 365;
  final List<int> _periodOptions = [7, 30, 90, 365];
  
  // Timeline view mode
  String _timelineView = 'monthly'; // 'monthly' or 'yearly'
  
  // Pie chart touch tracking
  int _touchedFormatIndex = -1;
  int _touchedStatusIndex = -1;
  
  // Global keys for chart export
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _activityKey = GlobalKey();
  final GlobalKey _animeKey = GlobalKey();
  final GlobalKey _mangaKey = GlobalKey();
  final GlobalKey _timelineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this); // Overview, Activity, Anime, Manga, Timeline, Studios, VAs, Staff
    
    // Initialize animation controller
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    
    _loadStatistics();
    
    // Listen to tab changes to restart animation
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _chartAnimationController.forward(from: 0.0);
      }
    });
    
    // Listen to adult content filter changes
    LocalStorageService.adultContentFilterNotifier.addListener(_onAdultContentFilterChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    LocalStorageService.adultContentFilterNotifier.removeListener(_onAdultContentFilterChanged);
    super.dispose();
  }
  
  void _onAdultContentFilterChanged() {
    // Reload statistics when filter changes
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    var animeList = widget.localStorageService.getAnimeList();
    var mangaList = widget.localStorageService.getMangaList();
    
    // Filter adult content if enabled
    final shouldHideAdult = widget.localStorageService.shouldHideAdultContent();
    if (shouldHideAdult) {
      animeList = animeList.where((entry) => entry.media?.isAdult != true).toList();
      mangaList = mangaList.where((entry) => entry.media?.isAdult != true).toList();
    }

    final stats = UserStatistics.fromLists(
      animeList: animeList,
      mangaList: mangaList,
    );

    // Load activity data with selected period
    final activityStats = await _activityService.getActivityStats(days: _selectedPeriod);
    final activityByDate = await _activityService.getActivityCountByDate(days: _selectedPeriod);

    setState(() {
      _stats = stats;
      _activityStats = activityStats;
      _activityByDate = activityByDate;
      _isLoading = false;
    });
    
    // Start animation after loading
    _chartAnimationController.forward(from: 0.0);
    
    // Load extended statistics in background (studios, VA, staff)
    _loadExtendedStatistics();
  }

  Future<void> _loadExtendedStatistics() async {
    setState(() => _isLoadingExtended = true);
    
    try {
      print('📊 Computing extended statistics from local data...');
      
      // TODO: For now, we'll show empty state
      // In future, we need to store studios/characters/staff in local database
      // during sync and use them here for offline statistics
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate processing
      
      setState(() {
        _extendedStats = {
          'studios': <String, int>{},
          'voiceActors': <Map<String, dynamic>>[],
          'staff': <Map<String, dynamic>>[],
        };
        _isLoadingExtended = false;
      });
      
      print('⚠️ Extended statistics feature requires additional data');
      print('💡 This feature will be fully implemented in next update');
    } catch (e, stackTrace) {
      print('❌ Error computing extended statistics: $e');
      print('📋 Stack trace: $stackTrace');
      setState(() => _isLoadingExtended = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compute stats: $e'),
            backgroundColor: AppTheme.accentRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          // Export menu (data-driven only, no screenshots)
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export options',
            onSelected: (value) {
              switch (value) {
                case 'overview':
                  _exportStatisticsOverview();
                  break;
                case 'weekly':
                  _exportWeeklyWrapup();
                  break;
                case 'monthly':
                  _exportMonthlyWrapup();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'overview',
                child: Row(
                  children: [
                    Icon(Icons.dashboard, size: 20),
                    SizedBox(width: 12),
                    Text('📊 Full Statistics Overview'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'weekly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week, size: 20),
                    SizedBox(width: 12),
                    Text('📅 Weekly Wrap-Up'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 12),
                    Text('📆 Monthly Wrap-Up'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Activity'),
            Tab(text: 'Anime'),
            Tab(text: 'Manga'),
            Tab(text: 'Timeline'),
            Tab(text: 'Studios'),
            Tab(text: 'Voice Actors'),
            Tab(text: 'Staff'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('No data available'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildActivityTab(),
                    _buildAnimeTab(),
                    _buildMangaTab(),
                    _buildTimelineTab(),
                    _buildStudiosTab(),
                    _buildVoiceActorsTab(),
                    _buildStaffTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _stats!;

    return RepaintBoundary(
      key: _overviewKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
              Expanded(
                child: _buildStatCard(
                  'Total Entries',
                  '${stats.totalAnime + stats.totalManga}',
                  Icons.list,
                  AppTheme.colors.primaryAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Episodes',
                  '${stats.totalEpisodesWatched}',
                  Icons.tv,
                  AppTheme.colors.secondaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Chapters',
                  '${stats.totalChaptersRead}',
                  Icons.book,
                  AppTheme.colors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Days Watched',
                  stats.daysWatchedAnime.toStringAsFixed(1),
                  Icons.calendar_today,
                  AppTheme.colors.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Score distribution
          _buildSectionTitle('Score Distribution'),
          const SizedBox(height: 16),
          _buildScoreDistributionChart(),
          
          const SizedBox(height: 32),
          
          // Genre distribution
          _buildSectionTitle('Top Genres'),
          const SizedBox(height: 16),
          _buildGenreDistributionChart(),
          
          const SizedBox(height: 32),
          
          // Format distribution
          _buildSectionTitle('Format Distribution'),
          const SizedBox(height: 16),
          _buildFormatDistributionChart(),
          
          const SizedBox(height: 32),
          
          // Status distribution
          _buildSectionTitle('Status Distribution'),
          const SizedBox(height: 16),
          _buildStatusPieChart(),
        ],
      ),
      ),
    );
  }

  Widget _buildAnimeTab() {
    final stats = _stats!;

    return RepaintBoundary(
      key: _animeKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anime stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Anime',
                    '${stats.totalAnime}',
                    Icons.tv,
                    AppTheme.colors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                  '${stats.completedAnime}',
                  Icons.check_circle,
                  AppTheme.colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Watching',
                  '${stats.watchingAnime}',
                  Icons.play_circle,
                  AppTheme.colors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Mean Score',
                  stats.meanAnimeScore.toStringAsFixed(1),
                  Icons.star,
                  AppTheme.colors.warning,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Episodes and Days watched row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Episodes Watched',
                  '${stats.totalEpisodesWatched}',
                  Icons.movie,
                  AppTheme.colors.secondaryAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Days Watched',
                  '${stats.daysWatchedAnime.toStringAsFixed(1)}',
                  Icons.calendar_today,
                  AppTheme.colors.info,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Top rated anime
          _buildSectionTitle('Top Rated Anime'),
          const SizedBox(height: 16),
          _buildTopRatedList(stats.topRatedAnime),
        ],
      ),
      ),
    );
  }

  Widget _buildMangaTab() {
    final stats = _stats!;

    return RepaintBoundary(
      key: _mangaKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manga stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Manga',
                  '${stats.totalManga}',
                  Icons.book,
                  AppTheme.colors.primaryAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${stats.completedManga}',
                  Icons.check_circle,
                  AppTheme.colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Reading',
                  '${stats.readingManga}',
                  Icons.menu_book,
                  AppTheme.colors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Mean Score',
                  stats.meanMangaScore.toStringAsFixed(1),
                  Icons.star,
                  AppTheme.colors.warning,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Chapters/Volumes
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Chapters Read',
                  '${stats.totalChaptersRead}',
                  Icons.chrome_reader_mode,
                  AppTheme.colors.secondaryAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Volumes Read',
                  '${stats.totalVolumesRead}',
                  Icons.collections_bookmark,
                  AppTheme.colors.info,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Top rated manga
          _buildSectionTitle('Top Rated Manga'),
          const SizedBox(height: 16),
          _buildTopRatedList(stats.topRatedManga),
        ],
      ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _chartAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _chartAnimation.value)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.colors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.colors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.colors.primaryText,
      ),
    );
  }

  Widget _buildScoreDistributionChart() {
    final stats = _stats!;
    final scoreData = <int, int>{};
    
    // Get scores 1-10 (skip 0)
    for (int i = 1; i <= 10; i++) {
      scoreData[i] = stats.scoreDistribution[i] ?? 0;
    }

    final maxCount = scoreData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount.toDouble() * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppTheme.secondaryBlack,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} anime',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: AppTheme.colors.secondaryText,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: AppTheme.colors.secondaryText,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxCount / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.colors.divider,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: scoreData.entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble() * _chartAnimation.value,
                      color: _getScoreColor(entry.key),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
            swapAnimationDuration: const Duration(milliseconds: 400),
            swapAnimationCurve: Curves.easeInOutCubic,
          );
        },
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 9) return Colors.green;
    if (score >= 7) return Colors.lightGreen;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildGenreDistributionChart() {
    final stats = _stats!;
    final topGenres = stats.topGenres.take(10).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        itemCount: topGenres.length,
        itemBuilder: (context, index) {
          final genre = topGenres[index];
          final count = stats.genreDistribution[genre] ?? 0;
          final maxCount = stats.genreDistribution[topGenres.first] ?? 1;

          return AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          genre,
                          style: TextStyle(
                            color: AppTheme.colors.primaryText,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(
                            color: AppTheme.colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (count / maxCount) * _chartAnimation.value,
                      backgroundColor: AppTheme.colors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.colors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFormatDistributionChart() {
    final stats = _stats!;
    final formatData = stats.formatDistribution.entries.toList();
    
    // Calculate total for percentage
    final total = formatData.fold<int>(0, (sum, entry) => sum + entry.value);
    
    if (formatData.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No format data available',
            style: TextStyle(
              color: AppTheme.colors.secondaryText,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 320, // Increased from 250 to 320
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedFormatIndex = -1;
                            return;
                          }
                          _touchedFormatIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                      enabled: true,
                    ),
                    sections: formatData.asMap().entries.map((mapEntry) {
                      final index = mapEntry.key;
                      final entry = mapEntry.value;
                      final isTouched = index == _touchedFormatIndex;
                      final percentage = (entry.value / total * 100);
                      // Show title only if segment is large enough (> 5%)
                      final showTitle = percentage > 5;
                      
                      return PieChartSectionData(
                        value: entry.value.toDouble() * _chartAnimation.value,
                        title: showTitle ? '${entry.value}' : '',
                        color: _getFormatColor(entry.key),
                        radius: isTouched ? 90 : 80,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        badgeWidget: isTouched
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${entry.key}\n${entry.value} (${percentage.toStringAsFixed(1)}%)',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        badgePositionPercentageOffset: 1.2,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 400),
                  swapAnimationCurve: Curves.easeInOutCubic,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: formatData.map((entry) {
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getFormatColor(entry.key),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: AppTheme.colors.primaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: AppTheme.colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart() {
    final stats = _stats!;
    final statusData = stats.statusDistribution.entries.toList();
    
    // Calculate total for percentage
    final total = statusData.fold<int>(0, (sum, entry) => sum + entry.value);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedStatusIndex = -1;
                            return;
                          }
                          _touchedStatusIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                      enabled: true,
                    ),
                    sections: statusData.asMap().entries.map((mapEntry) {
                      final index = mapEntry.key;
                      final entry = mapEntry.value;
                      final isTouched = index == _touchedStatusIndex;
                      final percentage = (entry.value / total * 100);
                      // Show title only if segment is large enough (> 5%)
                      final showTitle = percentage > 5;
                      
                      return PieChartSectionData(
                        value: entry.value.toDouble() * _chartAnimation.value,
                        title: showTitle ? '${entry.value}' : '',
                        color: _getStatusColor(entry.key),
                        radius: isTouched ? 90 : 80,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        badgeWidget: isTouched
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_getStatusLabel(entry.key)}\n${entry.value} (${percentage.toStringAsFixed(1)}%)',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        badgePositionPercentageOffset: 1.2,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 400),
                  swapAnimationCurve: Curves.easeInOutCubic,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: statusData.map((entry) {
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getStatusColor(entry.key),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatStatus(entry.key),
                          style: TextStyle(
                            color: AppTheme.colors.primaryText,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          color: AppTheme.colors.primaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($percentage%)',
                        style: TextStyle(
                          color: AppTheme.colors.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CURRENT':
        return Colors.green;
      case 'PLANNING':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.purple;
      case 'PAUSED':
        return Colors.orange;
      case 'DROPPED':
        return Colors.red;
      case 'REPEATING':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'CURRENT':
        return 'Watching';
      case 'PLANNING':
        return 'Planning';
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

  Color _getFormatColor(String format) {
    switch (format.toUpperCase()) {
      case 'TV':
        return Colors.blue;
      case 'MOVIE':
        return Colors.purple;
      case 'OVA':
        return Colors.orange;
      case 'ONA':
        return Colors.teal;
      case 'SPECIAL':
        return Colors.pink;
      case 'MUSIC':
        return Colors.deepPurple;
      case 'MANGA':
        return Colors.green;
      case 'ONE_SHOT':
        return Colors.amber;
      case 'NOVEL':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'CURRENT':
        return 'Watching/Reading';
      case 'PLANNING':
        return 'Plan to Watch/Read';
      case 'COMPLETED':
        return 'Completed';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      case 'REPEATING':
        return 'Rewatching/Rereading';
      default:
        return status;
    }
  }

  Widget _buildTopRatedList(List<MediaListEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No rated entries yet',
            style: TextStyle(
              color: AppTheme.colors.secondaryText,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: entries.take(10).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getScoreColor((entry.score ?? 0).floor()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      entry.score?.toStringAsFixed(1) ?? '0',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.media?.titleRomaji ?? 'Unknown',
                    style: TextStyle(
                      color: AppTheme.colors.primaryText,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityTab() {
    return RepaintBoundary(
      key: _activityKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter
            _buildPeriodFilter(),
            
            const SizedBox(height: 16),
            
            // Activity stats overview
            _buildActivityStatsOverview(),
            
            const SizedBox(height: 24),
            
            // GitHub-style activity heatmap
            _buildSectionTitle('Activity History - Last $_selectedPeriod Days'),
          const SizedBox(height: 16),
          _buildActivityHeatmap(),
          
          const SizedBox(height: 24),
          
          // Activity type breakdown
          _buildSectionTitle('Activity Breakdown'),
          const SizedBox(height: 16),
          _buildActivityTypeBreakdown(),
          
          const SizedBox(height: 24),
          
          // Import and Export buttons
          Row(
            children: [
              Expanded(child: _buildImportButton()),
              const SizedBox(width: 12),
              Expanded(child: _buildExportButton()),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildActivityStatsOverview() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActivityStatCard(
                'Total Activities',
                '${_activityStats['totalActivities'] ?? 0}',
                Icons.auto_graph,
                AppTheme.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityStatCard(
                'Active Days',
                '${_activityStats['activeDays'] ?? 0}',
                Icons.calendar_today,
                AppTheme.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActivityStatCard(
                'Current Streak',
                '${_activityStats['currentStreak'] ?? 0} days',
                Icons.local_fire_department,
                AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityStatCard(
                'Longest Streak',
                '${_activityStats['longestStreak'] ?? 0} days',
                Icons.emoji_events,
                AppTheme.accentPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildHeatmapGrid(),
          const SizedBox(height: 12),
          _buildHeatmapLegend(),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedPeriod - 1));
    
    // Calculate number of weeks
    final totalDays = _selectedPeriod;
    final weeks = (totalDays / 7).ceil();
    
    // Month labels
    final monthLabels = <String>[];
    DateTime currentMonth = startDate;
    while (currentMonth.isBefore(now)) {
      monthLabels.add(_getMonthAbbr(currentMonth.month));
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
    
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels (Mon, Wed, Fri)
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < 7; i++)
                      SizedBox(
                        height: 16,
                        child: i % 2 == 1
                            ? Text(
                                _getDayAbbr(i),
                                style: const TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 10,
                                ),
                              )
                            : const SizedBox(),
                      ),
                  ],
                ),
              ),
              // Heatmap grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weeks, (weekIndex) {
                  return Column(
                    children: List.generate(7, (dayIndex) {
                      final dayOffset = weekIndex * 7 + dayIndex;
                      if (dayOffset >= totalDays) {
                        return const SizedBox(width: 16, height: 16);
                      }
                      
                      final date = startDate.add(Duration(days: dayOffset));
                      final normalizedDate = DateTime(date.year, date.month, date.day);
                      final count = _activityByDate[normalizedDate] ?? 0;
                      
                      return Padding(
                        padding: const EdgeInsets.all(1),
                        child: Tooltip(
                          message: '${date.day}/${date.month}/${date.year}: $count activities',
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 600 + (dayOffset * 5)),
                            curve: Curves.easeOut,
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(count).withOpacity(_chartAnimation.value),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayAbbr(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day];
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Color _getHeatmapColor(int count) {
    if (count == 0) return AppTheme.primaryBlack;
    if (count <= 2) return AppTheme.accentGreen.withOpacity(0.3);
    if (count <= 5) return AppTheme.accentGreen.withOpacity(0.5);
    if (count <= 10) return AppTheme.accentGreen.withOpacity(0.7);
    return AppTheme.accentGreen;
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Less',
          style: TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getHeatmapColor(index == 0 ? 0 : index * 3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        const Text(
          'More',
          style: TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTypeBreakdown() {
    final activityByType = _activityStats['activityByType'] as Map<String, int>? ?? {};
    
    if (activityByType.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No activity data yet',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: activityByType.entries.map((entry) {
          final icon = _getActivityTypeIcon(entry.key);
          final color = _getActivityTypeColor(entry.key);
          final label = _getActivityTypeLabel(entry.key);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type) {
      case 'added':
      case 'list_update':
        return Icons.add_circle;
      case 'progress':
      case 'progress_update':
        return Icons.trending_up;
      case 'status':
      case 'status_change':
        return Icons.swap_horiz;
      case 'score':
        return Icons.star;
      case 'favorite_added':
        return Icons.favorite;
      case 'favorite_removed':
        return Icons.heart_broken;
      case 'notes':
        return Icons.note_alt;
      default:
        return Icons.circle;
    }
  }

  Color _getActivityTypeColor(String type) {
    switch (type) {
      case 'added':
      case 'list_update':
        return AppTheme.accentGreen;
      case 'progress':
      case 'progress_update':
        return AppTheme.accentBlue;
      case 'status':
      case 'status_change':
        return AppTheme.accentOrange;
      case 'score':
        return AppTheme.accentYellow;
      case 'favorite_added':
        return AppTheme.accentRed;
      case 'favorite_removed':
        return AppTheme.textGray;
      case 'notes':
        return AppTheme.accentPurple;
      default:
        return AppTheme.textGray;
    }
  }

  String _getActivityTypeLabel(String type) {
    switch (type) {
      case 'added':
        return 'Entries Added';
      case 'list_update':
        return 'List Updates';
      case 'progress':
      case 'progress_update':
        return 'Progress Updates';
      case 'status':
      case 'status_change':
        return 'Status Changes';
      case 'score':
        return 'Ratings';
      case 'favorite_added':
        return 'Favorites Added';
      case 'favorite_removed':
        return 'Favorites Removed';
      case 'notes':
        return 'Notes Updated';
      default:
        return 'Other';
    }
  }

  /// Period filter widget
  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: AppTheme.accentBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Period:',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: _periodOptions.map((days) {
                final isSelected = _selectedPeriod == days;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: ChoiceChip(
                    label: Text(
                      days == 7
                          ? '7 days'
                          : days == 30
                              ? '30 days'
                              : days == 90
                                  ? '90 days'
                                  : '1 year',
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = days;
                        });
                        _loadStatistics();
                      }
                    },
                    backgroundColor: AppTheme.primaryBlack,
                    selectedColor: AppTheme.accentBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.textWhite : AppTheme.textGray,
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Import activity history from AniList button
  Widget _buildImportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import History',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import your activity from AniList',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _importActivityHistory,
            icon: const Icon(Icons.cloud_download, size: 20),
            label: const Text('Import Last 30 Days'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              foregroundColor: AppTheme.textWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Export statistics button
  Widget _buildExportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Statistics',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Export your activity data and statistics',
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportActivityData,
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text('Activity Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: AppTheme.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportStatistics,
                  icon: const Icon(Icons.file_download, size: 20),
                  label: const Text('Full Stats'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Export activity data as JSON
  Future<void> _exportActivityData() async {
    try {
      final activities = await _activityService.exportActivities();
      
      // Convert to JSON string
      final encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(activities);
      
      // Show dialog with the data
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.secondaryBlack,
            title: const Text(
              'Activity Data',
              style: TextStyle(color: AppTheme.textWhite),
            ),
            content: SizedBox(
              width: 400,
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: jsonString));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// Export current tab as image
  
  /// Export full statistics overview (data-driven, not screenshot)
  Future<void> _exportStatisticsOverview() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Generating statistics overview...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Get all entries
      var animeList = await widget.localStorageService.getAnimeList();
      var mangaList = await widget.localStorageService.getMangaList();
      
      // Filter adult content if enabled
      final shouldHideAdult = widget.localStorageService.shouldHideAdultContent();
      if (shouldHideAdult) {
        animeList = animeList.where((entry) => entry.media?.isAdult != true).toList();
        mangaList = mangaList.where((entry) => entry.media?.isAdult != true).toList();
      }
      
      final allEntries = [...animeList, ...mangaList];
      
      // Generate overview data
      final overviewData = StatisticsDataHelper.generateStatisticsOverview(
        allEntries: allEntries,
        contentType: 'All Media',
      );
      
      // Generate image
      final filepath = await _exportService.generateStatisticsOverview(
        data: overviewData,
        filename: 'miyolist_statistics_overview',
        pixelRatio: 3.0,
      );
      
      if (filepath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Statistics overview saved!\n$filepath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate overview'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Export overview error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Export weekly wrap-up
  Future<void> _exportWeeklyWrapup() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('📅 Generating weekly wrap-up...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Get all entries
      var animeList = await widget.localStorageService.getAnimeList();
      var mangaList = await widget.localStorageService.getMangaList();
      
      // Filter adult content if enabled
      final shouldHideAdult = widget.localStorageService.shouldHideAdultContent();
      if (shouldHideAdult) {
        animeList = animeList.where((entry) => entry.media?.isAdult != true).toList();
        mangaList = mangaList.where((entry) => entry.media?.isAdult != true).toList();
      }
      
      final allEntries = [...animeList, ...mangaList];
      
      // Generate weekly data
      final wrapupData = StatisticsDataHelper.generateWeeklyWrapup(allEntries);
      
      // Generate image
      final filepath = await _exportService.generateWrapupImage(
        data: wrapupData,
        filename: 'miyolist_weekly_wrapup',
        pixelRatio: 3.0,
      );
      
      if (filepath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Weekly wrap-up saved!\n$filepath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate weekly wrap-up'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Weekly wrap-up error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Export monthly wrap-up
  Future<void> _exportMonthlyWrapup() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('📆 Generating monthly wrap-up...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Get all entries
      var animeList = await widget.localStorageService.getAnimeList();
      var mangaList = await widget.localStorageService.getMangaList();
      
      // Filter adult content if enabled
      final shouldHideAdult = widget.localStorageService.shouldHideAdultContent();
      if (shouldHideAdult) {
        animeList = animeList.where((entry) => entry.media?.isAdult != true).toList();
        mangaList = mangaList.where((entry) => entry.media?.isAdult != true).toList();
      }
      
      final allEntries = [...animeList, ...mangaList];
      
      // Generate monthly data
      final wrapupData = StatisticsDataHelper.generateMonthlyWrapup(allEntries);
      
      // Generate image
      final filepath = await _exportService.generateWrapupImage(
        data: wrapupData,
        filename: 'miyolist_monthly_wrapup',
        pixelRatio: 3.0,
      );
      
      if (filepath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Monthly wrap-up saved!\n$filepath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate monthly wrap-up'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Monthly wrap-up error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Export full statistics including activity data
  Future<void> _exportStatistics() async {
    try {
      final activities = await _activityService.exportActivities();
      final stats = _stats!;
      
      // Convert breakdown to simple map
      final breakdown = _activityStats['breakdown'] as Map<String, dynamic>?;
      final simpleBreakdown = <String, int>{};
      if (breakdown != null) {
        breakdown.forEach((key, value) {
          if (value is int) {
            simpleBreakdown[key] = value;
          } else if (value is num) {
            simpleBreakdown[key] = value.toInt();
          }
        });
      }
      
      // Convert timeline to simple list
      final timeline = _activityStats['timeline'] as List?;
      final simpleTimeline = <Map<String, dynamic>>[];
      if (timeline != null) {
        for (final item in timeline) {
          if (item is Map) {
            simpleTimeline.add({
              'date': item['date']?.toString() ?? '',
              'count': (item['count'] is int) ? item['count'] : (item['count'] as num?)?.toInt() ?? 0,
            });
          }
        }
      }
      
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'period': _selectedPeriod,
        'statistics': {
          'anime': {
            'total': stats.totalAnime,
            'completed': stats.completedAnime,
            'watching': stats.watchingAnime,
            'meanScore': stats.meanAnimeScore,
            'daysWatched': stats.daysWatchedAnime,
            'episodesWatched': stats.totalEpisodesWatched,
          },
          'manga': {
            'total': stats.totalManga,
            'completed': stats.completedManga,
            'reading': stats.readingManga,
            'meanScore': stats.meanMangaScore,
            'chaptersRead': stats.totalChaptersRead,
            'volumesRead': stats.totalVolumesRead,
          },
          'activity': {
            'totalActivities': _activityStats['totalActivities'] ?? 0,
            'breakdown': simpleBreakdown,
            'timeline': simpleTimeline,
          },
          'genres': stats.genreDistribution.map((k, v) => MapEntry(k, v)),
          'formats': stats.formatDistribution.map((k, v) => MapEntry(k, v)),
          'scores': stats.scoreDistribution.map((k, v) => MapEntry(k, v)),
          'statuses': stats.statusDistribution.map((k, v) => MapEntry(k, v)),
        },
        'activities': activities,
      };
      
      // Convert to JSON string
      final encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(exportData);
      
      // Show dialog with data
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.secondaryBlack,
            title: const Text(
              'Full Statistics',
              style: TextStyle(color: AppTheme.textWhite),
            ),
            content: SizedBox(
              width: 400,
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: jsonString));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// Import activity history from AniList
  Future<void> _importActivityHistory() async {
    if (widget.anilistService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AniList service not available'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: AppTheme.secondaryBlack,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.accentPurple),
              SizedBox(height: 16),
              Text(
                'Importing activity history...',
                style: TextStyle(color: AppTheme.textWhite),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final count = await widget.anilistService!.importActivityHistory(days: 30);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Reload statistics
        await _loadStatistics();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $count activities'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// Timeline Tab - Watching History
  Widget _buildTimelineTab() {
    var animeList = widget.localStorageService.getAnimeList();
    
    // Filter adult content if enabled
    final shouldHideAdult = widget.localStorageService.shouldHideAdultContent();
    if (shouldHideAdult) {
      animeList = animeList.where((entry) => entry.media?.isAdult != true).toList();
    }
    
    // Calculate monthly/yearly statistics from Activity data
    final monthlyData = _calculateMonthlyDataFromActivity();
    final yearlyData = _calculateYearlyDataFromActivity();
    final recentWatchHistory = _getRecentWatchHistory(animeList);
    
    return RepaintBoundary(
      key: _timelineKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View mode toggle
            Row(
              children: [
                _buildSectionTitle('Watching History'),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewModeButton('Monthly', 'monthly'),
                      _buildViewModeButton('Yearly', 'yearly'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Chart
            if (_timelineView == 'monthly') ...[
              _buildSectionTitle('Activity per Month'),
              const SizedBox(height: 8),
              Text(
                'Last 12 months - Updates, completions, and progress',
                style: TextStyle(
                  color: AppTheme.colors.secondaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildMonthlyTimelineChart(monthlyData),
              ),
            ] else ...[
              _buildSectionTitle('Activity per Year'),
              const SizedBox(height: 8),
              Text(
                'All time activity',
                style: TextStyle(
                  color: AppTheme.colors.secondaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildYearlyTimelineChart(yearlyData),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Statistics cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Episodes',
                    '${_stats!.totalEpisodesWatched}',
                    Icons.tv,
                    AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Days Watched',
                    _stats!.daysWatchedAnime.toStringAsFixed(1),
                    Icons.calendar_today,
                    AppTheme.accentPurple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Watch History
            _buildSectionTitle('Recent Watch History'),
            const SizedBox(height: 16),
            _buildRecentWatchHistory(recentWatchHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(String label, String mode) {
    final isSelected = _timelineView == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timelineView = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Map<String, int> _calculateMonthlyData(List<MediaListEntry> animeList) {
    final Map<String, int> monthlyEpisodes = {};
    final now = DateTime.now();
    
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyEpisodes[monthKey] = 0;
    }
    
    for (final entry in animeList) {
      if (entry.completedAt != null && entry.progress > 0) {
        final completedDate = entry.completedAt!;
        final monthKey = '${completedDate.year}-${completedDate.month.toString().padLeft(2, '0')}';
        
        if (monthlyEpisodes.containsKey(monthKey)) {
          monthlyEpisodes[monthKey] = (monthlyEpisodes[monthKey] ?? 0) + entry.progress;
        }
      }
    }
    
    return monthlyEpisodes;
  }

  Map<int, int> _calculateYearlyData(List<MediaListEntry> animeList) {
    final Map<int, int> yearlyEpisodes = {};
    
    for (final entry in animeList) {
      if (entry.completedAt != null && entry.progress > 0) {
        final year = entry.completedAt!.year;
        yearlyEpisodes[year] = (yearlyEpisodes[year] ?? 0) + entry.progress;
      }
    }
    
    return Map.fromEntries(
      yearlyEpisodes.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
  }

  Widget _buildMonthlyChart(Map<String, int> data) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: AppTheme.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No watching data for the past 12 months',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final spots = data.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textGray.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppTheme.colors.secondaryText,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                
                final monthKey = data.keys.toList()[index];
                final month = monthKey.split('-')[1];
                final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    monthNames[int.parse(month) - 1],
                    style: TextStyle(
                      color: AppTheme.colors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.accentBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.accentBlue,
                  strokeWidth: 2,
                  strokeColor: AppTheme.primaryBlack,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accentBlue.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.secondaryBlack,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final monthKey = data.keys.toList()[spot.x.toInt()];
                return LineTooltipItem(
                  '${spot.y.toInt()} episodes\n$monthKey',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildYearlyChart(Map<int, int> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: AppTheme.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No yearly watching data available',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.secondaryBlack,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final year = data.keys.toList()[groupIndex];
              return BarTooltipItem(
                '${rod.toY.toInt()} episodes\n$year',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.keys.toList()[index].toString(),
                    style: TextStyle(
                      color: AppTheme.colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppTheme.colors.secondaryText,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textGray.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.entries.toList().asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value.toDouble(),
                color: AppTheme.accentPurple,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
      swapAnimationCurve: Curves.easeInOut,
    );
  }

  /// Calculate monthly activity data from ActivityTrackingService
  Map<String, int> _calculateMonthlyDataFromActivity() {
    final Map<String, int> monthlyActivity = {};
    final now = DateTime.now();
    
    // Initialize last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyActivity[monthKey] = 0;
    }
    
    // Count activities by month
    if (_activityByDate.isNotEmpty) {
      for (final entry in _activityByDate.entries) {
        final date = entry.key;
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (monthlyActivity.containsKey(monthKey)) {
          monthlyActivity[monthKey] = (monthlyActivity[monthKey] ?? 0) + entry.value;
        }
      }
    }
    
    return monthlyActivity;
  }

  /// Calculate yearly activity data from ActivityTrackingService
  Map<int, int> _calculateYearlyDataFromActivity() {
    final Map<int, int> yearlyActivity = {};
    
    // Count activities by year
    if (_activityByDate.isNotEmpty) {
      for (final entry in _activityByDate.entries) {
        final year = entry.key.year;
        yearlyActivity[year] = (yearlyActivity[year] ?? 0) + entry.value;
      }
    }
    
    return Map.fromEntries(
      yearlyActivity.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
  }

  /// Get recent watch history from list
  List<Map<String, dynamic>> _getRecentWatchHistory(List<MediaListEntry> animeList) {
    // Get entries with recent updates (sorted by updatedAt)
    final recentEntries = animeList.where((entry) => 
      entry.updatedAt != null && entry.progress > 0
    ).toList()
      ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    
    return recentEntries.take(10).map((entry) {
      final media = entry.media;
      return {
        'id': entry.mediaId,
        'title': media?.titleEnglish ?? media?.titleRomaji ?? 'Unknown',
        'progress': entry.progress,
        'totalEpisodes': media?.episodes,
        'status': entry.status,
        'updatedAt': entry.updatedAt,
        'coverImage': media?.coverImage,
      };
    }).toList();
  }

  /// Build monthly timeline chart (using activity data)
  Widget _buildMonthlyTimelineChart(Map<String, int> data) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: AppTheme.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No activity data for the past 12 months',
              style: TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking your progress!',
              style: TextStyle(color: AppTheme.textGray, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final spots = data.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textGray.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppTheme.colors.secondaryText,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                
                final monthKey = data.keys.toList()[index];
                final month = monthKey.split('-')[1];
                final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    monthNames[int.parse(month) - 1],
                    style: TextStyle(
                      color: AppTheme.colors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.accentBlue,
                AppTheme.accentPurple,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.accentBlue,
                  strokeWidth: 2,
                  strokeColor: AppTheme.primaryBlack,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentBlue.withOpacity(0.3),
                  AppTheme.accentPurple.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.secondaryBlack,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final monthKey = data.keys.toList()[spot.x.toInt()];
                final count = spot.y.toInt();
                return LineTooltipItem(
                  '$count ${count == 1 ? 'activity' : 'activities'}\n$monthKey',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Build yearly timeline chart (using activity data)
  Widget _buildYearlyTimelineChart(Map<int, int> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: AppTheme.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No yearly activity data available',
              style: TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep watching and tracking!',
              style: TextStyle(color: AppTheme.textGray, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.secondaryBlack,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final year = data.keys.toList()[groupIndex];
              final count = rod.toY.toInt();
              return BarTooltipItem(
                '$count ${count == 1 ? 'activity' : 'activities'}\n$year',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.keys.toList()[index].toString(),
                    style: TextStyle(
                      color: AppTheme.colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppTheme.colors.secondaryText,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textGray.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value.value;
          
          // Gradient colors for bars
          final colors = [
            AppTheme.accentPurple,
            AppTheme.accentBlue,
            AppTheme.accentGreen,
          ];
          final color = colors[index % colors.length];
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value.toDouble(),
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
      swapAnimationCurve: Curves.easeInOut,
    );
  }

  /// Build recent watch history list
  Widget _buildRecentWatchHistory(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: AppTheme.textGray.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No recent activity',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start watching and tracking your progress!',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: history.map((item) {
        final title = item['title'] as String;
        final progress = item['progress'] as int;
        final totalEpisodes = item['totalEpisodes'] as int?;
        final status = item['status'] as String;
        final updatedAt = item['updatedAt'] as DateTime;
        final coverImage = item['coverImage'] as String?;
        
        final progressText = totalEpisodes != null 
            ? '$progress / $totalEpisodes'
            : '$progress episodes';
        
        final timeAgo = _getTimeAgo(updatedAt);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: coverImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      coverImage,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 70,
                          color: AppTheme.secondaryBlack,
                          child: const Icon(Icons.image, color: AppTheme.textGray),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tv, color: AppTheme.textGray),
                  ),
            title: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  progressText,
                  style: TextStyle(
                    color: AppTheme.colors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _getStatusBadge(status),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: AppTheme.colors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppTheme.colors.secondaryText,
            ),
            onTap: () {
              // TODO: Navigate to anime details
              print('Navigate to anime ${item['id']}');
            },
          ),
        );
      }).toList(),
    );
  }

  /// Get status badge widget
  Widget _getStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'CURRENT':
        color = AppTheme.accentGreen;
        label = 'Watching';
        break;
      case 'COMPLETED':
        color = AppTheme.accentPurple;
        label = 'Completed';
        break;
      case 'PAUSED':
        color = AppTheme.accentOrange;
        label = 'Paused';
        break;
      case 'DROPPED':
        color = AppTheme.accentRed;
        label = 'Dropped';
        break;
      case 'PLANNING':
        color = AppTheme.accentBlue;
        label = 'Planning';
        break;
      case 'REPEATING':
        color = const Color(0xFF00BCD4); // Cyan color
        label = 'Rewatching';
        break;
      default:
        color = AppTheme.textGray;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Studios Tab
  Widget _buildStudiosTab() {
    if (_isLoadingExtended) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '(｡･ω･｡)',
              style: TextStyle(fontSize: 64, color: AppTheme.accentBlue),
            ),
            SizedBox(height: 16),
            Text(
              'Loading studio statistics...',
              style: TextStyle(color: AppTheme.textGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final studiosData = _extendedStats['studios'] as Map<String, int>?;
    
    if (studiosData == null || studiosData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: AppTheme.textGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Coming Soon! (｡•̀ᴗ-)✧',
              style: TextStyle(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Studio statistics will be available in the next update',
                style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by anime count
    final sortedStudios = studiosData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topStudios = sortedStudios.take(15).toList();
    final total = studiosData.values.fold<int>(0, (sum, count) => sum + count);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildSectionTitle('Top Studios by Anime Count'),
          const SizedBox(height: 8),
          Text(
            '${sortedStudios.length} studios total',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          // Studio pie chart
          Container(
            height: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: topStudios.map((entry) {
                        final percentage = (entry.value / total * 100);
                        final showTitle = percentage > 3;
                        
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: showTitle ? '${entry.value}' : '',
                          color: _getStudioColor(topStudios.indexOf(entry)),
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: topStudios.map((entry) {
                        final percentage = (entry.value / total * 100).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getStudioColor(topStudios.indexOf(entry)),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: AppTheme.colors.primaryText,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  color: AppTheme.colors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Studio list
          _buildSectionTitle('All Studios'),
          const SizedBox(height: 16),
          ...sortedStudios.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: AppTheme.accentBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.value} ${entry.value == 1 ? 'anime' : 'anime'}',
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '#${sortedStudios.indexOf(entry) + 1}',
                  style: TextStyle(
                    color: AppTheme.accentBlue.withOpacity(0.6),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Voice Actors Tab
  Widget _buildVoiceActorsTab() {
    if (_isLoadingExtended) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '(｡•̀ᴗ-)✧',
              style: TextStyle(fontSize: 64, color: AppTheme.accentPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Loading voice actor statistics...',
              style: TextStyle(color: AppTheme.textGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final voiceActorsData = _extendedStats['voiceActors'] as List<dynamic>?;
    
    if (voiceActorsData == null || voiceActorsData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 64, color: AppTheme.textGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Coming Soon! (｡•̀ᴗ-)✧',
              style: TextStyle(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Voice actor statistics will be available in the next update',
                style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by anime count
    final sortedVAs = List<Map<String, dynamic>>.from(voiceActorsData)
      ..sort((a, b) => (b['animeCount'] as int).compareTo(a['animeCount'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Top Voice Actors'),
          const SizedBox(height: 8),
          Text(
            '${sortedVAs.length} voice actors in your list',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // VA List
          ...sortedVAs.take(50).map((va) {
            final characters = va['characters'] as List<dynamic>;
            final animeCount = va['animeCount'] as int;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                leading: va['image'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(va['image']),
                        radius: 28,
                      )
                    : const CircleAvatar(
                        backgroundColor: AppTheme.accentPurple,
                        child: Icon(Icons.person, color: Colors.white),
                        radius: 28,
                      ),
                title: Text(
                  va['name'],
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$animeCount ${animeCount == 1 ? 'anime' : 'anime'} • ${characters.length} ${characters.length == 1 ? 'character' : 'characters'}',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 14,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${sortedVAs.indexOf(va) + 1}',
                    style: const TextStyle(
                      color: AppTheme.accentPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Characters:',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: characters.take(10).map<Widget>((char) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getRoleColor(char['role']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getRoleColor(char['role']).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (char['image'] != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        char['image'],
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        char['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: AppTheme.textWhite,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        char['role'] ?? 'Unknown',
                                        style: TextStyle(
                                          color: _getRoleColor(char['role']),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        if (characters.length > 10) ...[
                          const SizedBox(height: 12),
                          Text(
                            '+${characters.length - 10} more characters',
                            style: const TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Staff Tab
  Widget _buildStaffTab() {
    if (_isLoadingExtended) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
              style: TextStyle(fontSize: 64, color: AppTheme.accentGreen),
            ),
            SizedBox(height: 16),
            Text(
              'Loading staff statistics...',
              style: TextStyle(color: AppTheme.textGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final staffData = _extendedStats['staff'] as List<dynamic>?;
    
    if (staffData == null || staffData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: AppTheme.textGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Coming Soon! (｡•̀ᴗ-)✧',
              style: TextStyle(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Staff statistics will be available in the next update',
                style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by anime count
    final sortedStaff = List<Map<String, dynamic>>.from(staffData)
      ..sort((a, b) => (b['animeCount'] as int).compareTo(a['animeCount'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Top Staff'),
          const SizedBox(height: 8),
          Text(
            '${sortedStaff.length} staff members in your list',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // Staff List
          ...sortedStaff.take(50).map((staff) {
            final roles = staff['roles'] as Map<String, int>;
            final animeCount = staff['animeCount'] as int;
            final topRole = roles.entries.isNotEmpty
                ? roles.entries.reduce((a, b) => a.value > b.value ? a : b).key
                : 'Unknown';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                leading: staff['image'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(staff['image']),
                        radius: 28,
                      )
                    : const CircleAvatar(
                        backgroundColor: AppTheme.accentGreen,
                        child: Icon(Icons.person, color: Colors.white),
                        radius: 28,
                      ),
                title: Text(
                  staff['name'],
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$topRole • $animeCount ${animeCount == 1 ? 'anime' : 'anime'}',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 14,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${sortedStaff.indexOf(staff) + 1}',
                    style: const TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Roles:',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: roles.entries.map<Widget>((role) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.accentGreen.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    role.key,
                                    style: const TextStyle(
                                      color: AppTheme.textWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '×${role.value}',
                                    style: const TextStyle(
                                      color: AppTheme.accentGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStudioColor(int index) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.green,
      Colors.red,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.deepPurple,
      Colors.yellow,
    ];
    return colors[index % colors.length];
  }

  Color _getRoleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'MAIN':
        return AppTheme.accentGreen;
      case 'SUPPORTING':
        return AppTheme.accentBlue;
      case 'BACKGROUND':
        return AppTheme.textGray;
      default:
        return AppTheme.accentOrange;
    }
  }

}
