import 'wrapup_data.dart';

/// Model for current statistics overview export (data-driven, not screenshot)
class StatisticsOverviewData {
  // Basic totals
  final int totalEntries;
  final int totalEpisodes;
  final int totalChapters;
  final double daysWatched;
  
  // Mean score
  final double meanScore;
  
  // Score distribution (1-10)
  final Map<int, int> scoreDistribution;
  
  // Top genres (with counts)
  final List<GenreCount> topGenres;
  
  // Status breakdown
  final Map<String, int> statusCounts; // "Completed" -> 715
  
  // Format breakdown
  final Map<String, int> formatCounts; // "TV" -> 1200
  
  // Type of content
  final String contentType; // "Anime", "Manga", or "All"
  
  const StatisticsOverviewData({
    required this.totalEntries,
    required this.totalEpisodes,
    required this.totalChapters,
    required this.daysWatched,
    required this.meanScore,
    required this.scoreDistribution,
    required this.topGenres,
    required this.statusCounts,
    required this.formatCounts,
    required this.contentType,
  });
}
