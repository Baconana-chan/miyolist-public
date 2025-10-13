/// Универсальная модель для результатов поиска
class SearchResult {
  final int id;
  final String type; // ANIME, MANGA, CHARACTER, STAFF, STUDIO
  final String title;
  final String? subtitle; // Дополнительная информация
  final String? imageUrl;
  final double? score;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.score,
  });

  factory SearchResult.fromMedia(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title']?['romaji'] ?? json['title']?['english'] ?? 'Unknown',
      subtitle: json['format'] as String?,
      imageUrl: json['coverImage']?['large'] as String?,
      score: (json['averageScore'] as num?)?.toDouble(),
    );
  }

  factory SearchResult.fromCharacter(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as int,
      type: 'CHARACTER',
      title: json['name']?['full'] ?? 'Unknown',
      subtitle: json['name']?['native'] as String?,
      imageUrl: json['image']?['large'] as String?,
      score: null,
    );
  }

  factory SearchResult.fromStaff(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as int,
      type: 'STAFF',
      title: json['name']?['full'] ?? 'Unknown',
      subtitle: json['name']?['native'] as String?,
      imageUrl: json['image']?['large'] as String?,
      score: null,
    );
  }

  factory SearchResult.fromStudio(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as int,
      type: 'STUDIO',
      title: json['name'] as String? ?? 'Unknown',
      subtitle: json['isAnimationStudio'] == true ? 'Animation Studio' : 'Production Company',
      imageUrl: null,
      score: null,
    );
  }
}
