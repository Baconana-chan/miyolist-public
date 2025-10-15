/// Period type for wrap-up
enum WrapupPeriod {
  week,
  month,
  year,
}

/// Model for wrap-up statistics export (weekly/monthly/yearly)
class WrapupData {
  // Period info
  final WrapupPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  
  // Basic stats
  final int totalEntries;
  final int totalEpisodes;
  final int totalChapters;
  final double daysWatched;
  
  // Score distribution
  final Map<int, int> scoreDistribution; // score -> count
  
  // Top genres
  final List<GenreCount> topGenres;
  
  // Mean score
  final double meanScore;
  
  // Seasonal breakdown (optional)
  final Map<String, int>? seasonalCounts; // "Winter 2024" -> count
  
  // Status breakdown
  final Map<String, int>? statusCounts; // "Completed" -> count
  
  // Format breakdown
  final Map<String, int>? formatCounts; // "TV" -> count
  
  // Top studios/producers (optional)
  final List<String>? topStudios;
  
  // Most watched day
  final String? mostWatchedDay;
  
  // Longest binge session
  final int? longestBingeEpisodes;
  
  // New entries this period
  final int newEntriesCount;
  
  // Completed this period
  final int completedCount;
  
  const WrapupData({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalEntries,
    required this.totalEpisodes,
    required this.totalChapters,
    required this.daysWatched,
    required this.scoreDistribution,
    required this.topGenres,
    required this.meanScore,
    this.seasonalCounts,
    this.statusCounts,
    this.formatCounts,
    this.topStudios,
    this.mostWatchedDay,
    this.longestBingeEpisodes,
    this.newEntriesCount = 0,
    this.completedCount = 0,
  });
  
  /// Get formatted period title
  String get periodTitle {
    switch (period) {
      case WrapupPeriod.week:
        return 'Week ${_getWeekNumber()}';
      case WrapupPeriod.month:
        return _getMonthName();
      case WrapupPeriod.year:
        return 'Year ${endDate.year}';
    }
  }
  
  /// Get week number
  int _getWeekNumber() {
    final startOfYear = DateTime(endDate.year, 1, 1);
    final days = endDate.difference(startOfYear).inDays;
    return (days / 7).ceil();
  }
  
  /// Get month name
  String _getMonthName() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[endDate.month - 1]} ${endDate.year}';
  }
}

/// Genre with count for wrap-up
class GenreCount {
  final String genre;
  final int count;
  
  const GenreCount({
    required this.genre,
    required this.count,
  });
}
