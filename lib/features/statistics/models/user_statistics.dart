import '../../../core/models/media_list_entry.dart';

/// Statistics calculated from user's anime/manga lists
class UserStatistics {
  // Anime statistics
  final int totalAnime;
  final int completedAnime;
  final int watchingAnime;
  final int planningAnime;
  final int pausedAnime;
  final int droppedAnime;
  final int rewatchingAnime;
  final int totalEpisodesWatched;
  final double meanAnimeScore;
  final double daysWatchedAnime;
  
  // Manga statistics
  final int totalManga;
  final int completedManga;
  final int readingManga;
  final int planningManga;
  final int pausedManga;
  final int droppedManga;
  final int rereadingManga;
  final int totalChaptersRead;
  final int totalVolumesRead;
  final double meanMangaScore;
  
  // Genre distribution
  final Map<String, int> genreDistribution;
  final Map<String, double> genreScores;
  
  // Score distribution
  final Map<int, int> scoreDistribution; // 0-10 → count
  
  // Format distribution
  final Map<String, int> formatDistribution;
  
  // Status distribution
  final Map<String, int> statusDistribution;
  
  // Top items
  final List<String> topGenres;
  final List<MediaListEntry> topRatedAnime;
  final List<MediaListEntry> topRatedManga;
  
  // Temporal data
  final Map<int, int> yearDistribution; // Year → count
  final int currentYearCount;
  
  UserStatistics({
    required this.totalAnime,
    required this.completedAnime,
    required this.watchingAnime,
    required this.planningAnime,
    required this.pausedAnime,
    required this.droppedAnime,
    required this.rewatchingAnime,
    required this.totalEpisodesWatched,
    required this.meanAnimeScore,
    required this.daysWatchedAnime,
    required this.totalManga,
    required this.completedManga,
    required this.readingManga,
    required this.planningManga,
    required this.pausedManga,
    required this.droppedManga,
    required this.rereadingManga,
    required this.totalChaptersRead,
    required this.totalVolumesRead,
    required this.meanMangaScore,
    required this.genreDistribution,
    required this.genreScores,
    required this.scoreDistribution,
    required this.formatDistribution,
    required this.statusDistribution,
    required this.topGenres,
    required this.topRatedAnime,
    required this.topRatedManga,
    required this.yearDistribution,
    required this.currentYearCount,
  });
  
  /// Calculate statistics from lists
  factory UserStatistics.fromLists({
    required List<MediaListEntry> animeList,
    required List<MediaListEntry> mangaList,
  }) {
    // Anime stats
    final animeByStatus = <String, List<MediaListEntry>>{};
    for (final entry in animeList) {
      animeByStatus.putIfAbsent(entry.status, () => []).add(entry);
    }
    
    final totalEpisodes = animeList.fold<int>(
      0,
      (sum, entry) => sum + entry.progress,
    );
    
    final animeScores = animeList
        .where((e) => e.score != null && e.score! > 0)
        .map((e) => e.score!)
        .toList();
    final meanAnimeScore = animeScores.isEmpty
        ? 0.0
        : animeScores.reduce((a, b) => a + b) / animeScores.length;
    
    // Calculate days watched (assuming 24 min per episode)
    final minutesWatched = totalEpisodes * 24;
    final daysWatched = minutesWatched / 1440.0;
    
    // Manga stats
    final mangaByStatus = <String, List<MediaListEntry>>{};
    for (final entry in mangaList) {
      mangaByStatus.putIfAbsent(entry.status, () => []).add(entry);
    }
    
    final totalChapters = mangaList.fold<int>(
      0,
      (sum, entry) => sum + entry.progress,
    );
    
    final totalVolumes = mangaList.fold<int>(
      0,
      (sum, entry) => sum + (entry.progressVolumes ?? 0),
    );
    
    final mangaScores = mangaList
        .where((e) => e.score != null && e.score! > 0)
        .map((e) => e.score!)
        .toList();
    final meanMangaScore = mangaScores.isEmpty
        ? 0.0
        : mangaScores.reduce((a, b) => a + b) / mangaScores.length;
    
    // Genre distribution
    final genreCount = <String, int>{};
    final genreScoreSum = <String, double>{};
    final genreScoreCount = <String, int>{};
    
    for (final entry in [...animeList, ...mangaList]) {
      final genres = entry.media?.genres ?? [];
      final score = entry.score ?? 0.0;
      
      for (final genre in genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
        if (score > 0) {
          genreScoreSum[genre] = (genreScoreSum[genre] ?? 0.0) + score;
          genreScoreCount[genre] = (genreScoreCount[genre] ?? 0) + 1;
        }
      }
    }
    
    final genreScores = <String, double>{};
    for (final genre in genreScoreSum.keys) {
      genreScores[genre] = genreScoreSum[genre]! / genreScoreCount[genre]!;
    }
    
    // Score distribution (0-10)
    final scoreDistribution = <int, int>{};
    for (int i = 0; i <= 10; i++) {
      scoreDistribution[i] = 0;
    }
    
    for (final entry in [...animeList, ...mangaList]) {
      if (entry.score != null && entry.score! > 0) {
        final scoreInt = entry.score!.floor();
        scoreDistribution[scoreInt] = (scoreDistribution[scoreInt] ?? 0) + 1;
      }
    }
    
    // Format distribution
    final formatDistribution = <String, int>{};
    for (final entry in [...animeList, ...mangaList]) {
      final format = entry.media?.format ?? 'UNKNOWN';
      formatDistribution[format] = (formatDistribution[format] ?? 0) + 1;
    }
    
    // Status distribution
    final statusDistribution = <String, int>{};
    for (final entry in [...animeList, ...mangaList]) {
      final status = entry.status;
      statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;
    }
    
    // Top genres (sorted by count)
    final topGenres = genreCount.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    final topGenresList = topGenres.take(10).map((e) => e.key).toList();
    
    // Top rated
    final sortedAnime = animeList.where((e) => e.score != null && e.score! > 0).toList()
      ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    final topRatedAnime = sortedAnime.take(10).toList();
    
    final sortedManga = mangaList.where((e) => e.score != null && e.score! > 0).toList()
      ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    final topRatedManga = sortedManga.take(10).toList();
    
    // Year distribution
    final yearDistribution = <int, int>{};
    final currentYear = DateTime.now().year;
    int currentYearCount = 0;
    
    for (final entry in [...animeList, ...mangaList]) {
      final year = entry.media?.startDate?.year;
      if (year != null) {
        yearDistribution[year] = (yearDistribution[year] ?? 0) + 1;
        if (year == currentYear) {
          currentYearCount++;
        }
      }
    }
    
    return UserStatistics(
      totalAnime: animeList.length,
      completedAnime: animeByStatus['COMPLETED']?.length ?? 0,
      watchingAnime: animeByStatus['CURRENT']?.length ?? 0,
      planningAnime: animeByStatus['PLANNING']?.length ?? 0,
      pausedAnime: animeByStatus['PAUSED']?.length ?? 0,
      droppedAnime: animeByStatus['DROPPED']?.length ?? 0,
      rewatchingAnime: animeByStatus['REPEATING']?.length ?? 0,
      totalEpisodesWatched: totalEpisodes,
      meanAnimeScore: meanAnimeScore,
      daysWatchedAnime: daysWatched,
      totalManga: mangaList.length,
      completedManga: mangaByStatus['COMPLETED']?.length ?? 0,
      readingManga: mangaByStatus['CURRENT']?.length ?? 0,
      planningManga: mangaByStatus['PLANNING']?.length ?? 0,
      pausedManga: mangaByStatus['PAUSED']?.length ?? 0,
      droppedManga: mangaByStatus['DROPPED']?.length ?? 0,
      rereadingManga: mangaByStatus['REPEATING']?.length ?? 0,
      totalChaptersRead: totalChapters,
      totalVolumesRead: totalVolumes,
      meanMangaScore: meanMangaScore,
      genreDistribution: genreCount,
      genreScores: genreScores,
      scoreDistribution: scoreDistribution,
      formatDistribution: formatDistribution,
      statusDistribution: statusDistribution,
      topGenres: topGenresList,
      topRatedAnime: topRatedAnime,
      topRatedManga: topRatedManga,
      yearDistribution: yearDistribution,
      currentYearCount: currentYearCount,
    );
  }
}
