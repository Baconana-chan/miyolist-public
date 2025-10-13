import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../models/user_statistics.dart';

class StatisticsPage extends StatefulWidget {
  final LocalStorageService localStorageService;

  const StatisticsPage({
    super.key,
    required this.localStorageService,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserStatistics? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    final animeList = widget.localStorageService.getAnimeList();
    final mangaList = widget.localStorageService.getMangaList();

    final stats = UserStatistics.fromLists(
      animeList: animeList,
      mangaList: mangaList,
    );

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Anime'),
            Tab(text: 'Manga'),
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
                    _buildAnimeTab(),
                    _buildMangaTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _stats!;

    return SingleChildScrollView(
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
          
          // Status distribution
          _buildSectionTitle('Status Distribution'),
          const SizedBox(height: 16),
          _buildStatusPieChart(),
        ],
      ),
    );
  }

  Widget _buildAnimeTab() {
    final stats = _stats!;

    return SingleChildScrollView(
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
          
          // Episodes watched
          _buildStatCard(
            'Total Episodes Watched',
            '${stats.totalEpisodesWatched}',
            Icons.movie,
            AppTheme.colors.secondaryAccent,
          ),
          
          const SizedBox(height: 16),
          
          _buildStatCard(
            'Days Watched',
            '${stats.daysWatchedAnime.toStringAsFixed(1)} days',
            Icons.calendar_today,
            AppTheme.colors.info,
          ),
          
          const SizedBox(height: 32),
          
          // Top rated anime
          _buildSectionTitle('Top Rated Anime'),
          const SizedBox(height: 16),
          _buildTopRatedList(stats.topRatedAnime),
        ],
      ),
    );
  }

  Widget _buildMangaTab() {
    final stats = _stats!;

    return SingleChildScrollView(
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
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount.toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: true),
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
                  toY: entry.value.toDouble(),
                  color: _getScoreColor(entry.key),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
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
                  value: count / maxCount,
                  backgroundColor: AppTheme.colors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.colors.primaryAccent,
                  ),
                ),
              ],
            ),
          );
        },
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
            child: PieChart(
              PieChartData(
                sections: statusData.map((entry) {
                  final percentage = (entry.value / total * 100);
                  // Show title only if segment is large enough (> 5%)
                  final showTitle = percentage > 5;
                  
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: showTitle ? '${entry.value}' : '',
                    color: _getStatusColor(entry.key),
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
}
