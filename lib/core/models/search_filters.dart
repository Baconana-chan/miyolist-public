/// Модель для расширенных фильтров поиска
class SearchFilters {
  // Базовые фильтры
  final String? type; // ANIME, MANGA, etc.
  final List<String>? genres;
  final int? year;
  final String? season; // WINTER, SPRING, SUMMER, FALL
  final String? format; // TV, MOVIE, MANGA, NOVEL, etc.
  final String? status; // FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED
  
  // Фильтры по диапазону
  final int? scoreMin; // 0-100
  final int? scoreMax; // 0-100
  final int? episodesMin;
  final int? episodesMax;
  final int? chaptersMin;
  final int? chaptersMax;
  
  // Сортировка
  final String sortBy; // POPULARITY, SCORE, TRENDING, TITLE_ROMAJI, UPDATED_AT
  final String sortOrder; // DESC, ASC
  
  // Контент для взрослых
  final bool includeAdultContent; // Показывать ли контент 18+
  
  SearchFilters({
    this.type,
    this.genres,
    this.year,
    this.season,
    this.format,
    this.status,
    this.scoreMin,
    this.scoreMax,
    this.episodesMin,
    this.episodesMax,
    this.chaptersMin,
    this.chaptersMax,
    this.sortBy = 'POPULARITY',
    this.sortOrder = 'DESC',
    this.includeAdultContent = false,
  });
  
  SearchFilters copyWith({
    String? type,
    List<String>? genres,
    int? year,
    String? season,
    String? format,
    String? status,
    int? scoreMin,
    int? scoreMax,
    int? episodesMin,
    int? episodesMax,
    int? chaptersMin,
    int? chaptersMax,
    String? sortBy,
    String? sortOrder,
    bool? includeAdultContent,
  }) {
    return SearchFilters(
      type: type ?? this.type,
      genres: genres ?? this.genres,
      year: year ?? this.year,
      season: season ?? this.season,
      format: format ?? this.format,
      status: status ?? this.status,
      scoreMin: scoreMin ?? this.scoreMin,
      scoreMax: scoreMax ?? this.scoreMax,
      episodesMin: episodesMin ?? this.episodesMin,
      episodesMax: episodesMax ?? this.episodesMax,
      chaptersMin: chaptersMin ?? this.chaptersMin,
      chaptersMax: chaptersMax ?? this.chaptersMax,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      includeAdultContent: includeAdultContent ?? this.includeAdultContent,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'genres': genres,
      'year': year,
      'season': season,
      'format': format,
      'status': status,
      'scoreMin': scoreMin,
      'scoreMax': scoreMax,
      'episodesMin': episodesMin,
      'episodesMax': episodesMax,
      'chaptersMin': chaptersMin,
      'chaptersMax': chaptersMax,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      'includeAdultContent': includeAdultContent,
    };
  }
  
  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      type: json['type'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      year: json['year'] as int?,
      season: json['season'] as String?,
      format: json['format'] as String?,
      status: json['status'] as String?,
      scoreMin: json['scoreMin'] as int?,
      scoreMax: json['scoreMax'] as int?,
      episodesMin: json['episodesMin'] as int?,
      episodesMax: json['episodesMax'] as int?,
      chaptersMin: json['chaptersMin'] as int?,
      chaptersMax: json['chaptersMax'] as int?,
      sortBy: json['sortBy'] as String? ?? 'POPULARITY',
      sortOrder: json['sortOrder'] as String? ?? 'DESC',
      includeAdultContent: json['includeAdultContent'] as bool? ?? false,
    );
  }
  
  bool get hasActiveFilters {
    return genres != null && genres!.isNotEmpty ||
        year != null ||
        season != null ||
        format != null ||
        status != null ||
        scoreMin != null ||
        scoreMax != null ||
        episodesMin != null ||
        episodesMax != null ||
        chaptersMin != null ||
        chaptersMax != null;
  }
  
  SearchFilters clearFilters() {
    return SearchFilters(
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}

/// История поиска
class SearchHistoryItem {
  final String query;
  final DateTime timestamp;
  final SearchFilters? filters;
  
  SearchHistoryItem({
    required this.query,
    required this.timestamp,
    this.filters,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'filters': filters?.toJson(),
    };
  }
  
  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      filters: json['filters'] != null 
          ? SearchFilters.fromJson(json['filters'] as Map<String, dynamic>)
          : null,
    );
  }
}
