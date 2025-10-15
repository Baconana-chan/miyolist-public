/// Модель для информации о выходе следующего эпизода
class AiringEpisode {
  final int id;
  final int mediaId;
  final int episode;
  final DateTime airingAt;
  final int timeUntilAiring; // секунды
  
  // Информация о медиа
  final String title;
  final String? coverImageUrl;
  final int? totalEpisodes;
  final bool isAdult;
  
  AiringEpisode({
    required this.id,
    required this.mediaId,
    required this.episode,
    required this.airingAt,
    required this.timeUntilAiring,
    required this.title,
    this.coverImageUrl,
    this.totalEpisodes,
    this.isAdult = false,
  });
  
  factory AiringEpisode.fromJson(Map<String, dynamic> json) {
    final media = json['media'] as Map<String, dynamic>;
    final title = media['title'] as Map<String, dynamic>;
    final coverImage = media['coverImage'] as Map<String, dynamic>?;
    
    return AiringEpisode(
      id: json['id'] as int,
      mediaId: json['mediaId'] as int,
      episode: json['episode'] as int,
      airingAt: DateTime.fromMillisecondsSinceEpoch(
        (json['airingAt'] as int) * 1000,
      ),
      timeUntilAiring: json['timeUntilAiring'] as int,
      title: (title['romaji'] ?? title['english'] ?? 'Unknown') as String,
      coverImageUrl: coverImage?['large'] as String?,
      totalEpisodes: media['episodes'] as int?,
      isAdult: media['isAdult'] as bool? ?? false,
    );
  }
  
  /// Получить читаемое время до выхода эпизода
  String getTimeUntilText() {
    if (timeUntilAiring <= 0) {
      return 'Aired';
    }
    
    final duration = Duration(seconds: timeUntilAiring);
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Soon';
    }
  }
  
  /// Проверить выходит ли эпизод сегодня
  bool get isToday {
    final now = DateTime.now();
    return airingAt.year == now.year &&
           airingAt.month == now.month &&
           airingAt.day == now.day;
  }
  
  /// Проверить выходит ли эпизод на этой неделе
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return airingAt.isAfter(weekStart) && airingAt.isBefore(weekEnd);
  }
}
