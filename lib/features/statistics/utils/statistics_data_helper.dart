import '../../../core/models/media_list_entry.dart';
import '../models/wrapup_data.dart';
import '../models/statistics_overview_data.dart';

/// Helper class for generating statistics data from media lists
class StatisticsDataHelper {
  /// Generate wrap-up data for a specific period
  static WrapupData generateWrapupData({
    required List<MediaListEntry> allEntries,
    required WrapupPeriod period,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Filter entries updated in this period
    final periodEntries = allEntries.where((entry) {
      final updatedAt = entry.updatedAt;
      if (updatedAt == null) return false;
      return updatedAt.isAfter(startDate) && updatedAt.isBefore(endDate);
    }).toList();
    
    // Calculate stats
    final totalEpisodes = periodEntries.fold<int>(
      0, 
      (sum, entry) => sum + (entry.progress ?? 0),
    );
    
    final totalChapters = periodEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry.progressVolumes ?? 0),
    );
    
    final completedCount = periodEntries.where(
      (entry) => entry.status == 'COMPLETED',
    ).length;
    
    // Calculate days watched (assuming 24 min per episode)
    final minutesWatched = totalEpisodes * 24;
    final daysWatched = minutesWatched / (24 * 60);
    
    // Score distribution
    final scoreDistribution = <int, int>{};
    for (final entry in periodEntries) {
      final score = entry.score?.toInt();
      if (score != null && score > 0) {
        scoreDistribution[score] = (scoreDistribution[score] ?? 0) + 1;
      }
    }
    
    // Calculate mean score
    double meanScore = 0;
    if (scoreDistribution.isNotEmpty) {
      int totalScore = 0;
      int totalCount = 0;
      scoreDistribution.forEach((score, count) {
        totalScore += score * count;
        totalCount += count;
      });
      meanScore = totalCount > 0 ? totalScore / totalCount : 0;
    }
    
    // Top genres
    final genreCounts = <String, int>{};
    for (final entry in periodEntries) {
      final genres = entry.media?.genres;
      if (genres != null) {
        for (final genre in genres) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }
    }
    
    final topGenres = genreCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final topGenresList = topGenres.take(10).map((e) => 
      GenreCount(genre: e.key, count: e.value)
    ).toList();
    
    return WrapupData(
      period: period,
      startDate: startDate,
      endDate: endDate,
      totalEntries: periodEntries.length,
      totalEpisodes: totalEpisodes,
      totalChapters: totalChapters,
      daysWatched: daysWatched,
      scoreDistribution: scoreDistribution,
      topGenres: topGenresList,
      meanScore: meanScore,
      newEntriesCount: periodEntries.length,
      completedCount: completedCount,
    );
  }
  
  /// Generate weekly wrap-up data
  static WrapupData generateWeeklyWrapup(List<MediaListEntry> allEntries) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return generateWrapupData(
      allEntries: allEntries,
      period: WrapupPeriod.week,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }
  
  /// Generate monthly wrap-up data
  static WrapupData generateMonthlyWrapup(List<MediaListEntry> allEntries) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return generateWrapupData(
      allEntries: allEntries,
      period: WrapupPeriod.month,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }
  
  /// Generate statistics overview from all entries
  static StatisticsOverviewData generateStatisticsOverview({
    required List<MediaListEntry> allEntries,
    required String contentType,
  }) {
    // Calculate totals
    final totalEpisodes = allEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry.progress ?? 0),
    );
    
    final totalChapters = allEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry.progressVolumes ?? 0),
    );
    
    // Days watched
    final minutesWatched = totalEpisodes * 24;
    final daysWatched = minutesWatched / (24 * 60);
    
    // Score distribution
    final scoreDistribution = <int, int>{};
    for (final entry in allEntries) {
      final score = entry.score?.toInt();
      if (score != null && score > 0) {
        scoreDistribution[score] = (scoreDistribution[score] ?? 0) + 1;
      }
    }
    
    // Mean score
    double meanScore = 0;
    if (scoreDistribution.isNotEmpty) {
      int totalScore = 0;
      int totalCount = 0;
      scoreDistribution.forEach((score, count) {
        totalScore += score * count;
        totalCount += count;
      });
      meanScore = totalCount > 0 ? totalScore / totalCount : 0;
    }
    
    // Top genres
    final genreCounts = <String, int>{};
    for (final entry in allEntries) {
      final genres = entry.media?.genres;
      if (genres != null) {
        for (final genre in genres) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }
    }
    
    final topGenres = genreCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final topGenresList = topGenres.take(10).map((e) => 
      GenreCount(genre: e.key, count: e.value)
    ).toList();
    
    // Status counts
    final statusCounts = <String, int>{};
    for (final entry in allEntries) {
      final status = entry.status;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    
    // Format counts
    final formatCounts = <String, int>{};
    for (final entry in allEntries) {
      final format = entry.media?.format;
      if (format != null) {
        formatCounts[format] = (formatCounts[format] ?? 0) + 1;
      }
    }
    
    return StatisticsOverviewData(
      totalEntries: allEntries.length,
      totalEpisodes: totalEpisodes,
      totalChapters: totalChapters,
      daysWatched: daysWatched,
      meanScore: meanScore,
      scoreDistribution: scoreDistribution,
      topGenres: topGenresList,
      statusCounts: statusCounts,
      formatCounts: formatCounts,
      contentType: contentType,
    );
  }
}

