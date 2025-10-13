/// Lightweight model for displaying media preview cards
class MediaPreview {
  final int id;
  final String? titleRomaji;
  final String? titleEnglish;
  final String? coverImage;
  final String? format;
  final String? status;
  final String mediaType;
  final double? averageScore;
  final int? startYear;

  MediaPreview({
    required this.id,
    this.titleRomaji,
    this.titleEnglish,
    this.coverImage,
    this.format,
    this.status,
    required this.mediaType,
    this.averageScore,
    this.startYear,
  });

  factory MediaPreview.fromJson(Map<String, dynamic> json) {
    return MediaPreview(
      id: json['id'],
      mediaType: json['type'] ?? 'ANIME',
      titleRomaji: json['title']?['romaji'],
      titleEnglish: json['title']?['english'],
      coverImage: json['coverImage']?['large'] ?? json['coverImage']?['medium'],
      format: json['format'],
      status: json['status'],
      averageScore: json['averageScore']?.toDouble(),
      startYear: json['startDate']?['year'],
    );
  }

  factory MediaPreview.fromMediaListEntry(dynamic entry) {
    final media = entry.media;
    if (media == null) {
      throw Exception('MediaListEntry has no media');
    }
    
    // Determine type based on presence of episodes (anime) or chapters (manga)
    String type = 'ANIME';
    if (media.chapters != null || media.volumes != null) {
      type = 'MANGA';
    }
    
    return MediaPreview(
      id: media.id,
      mediaType: type,
      titleRomaji: media.titleRomaji,
      titleEnglish: media.titleEnglish,
      coverImage: media.coverImage,
      format: media.format,
      status: media.status,
      averageScore: media.averageScore,
      startYear: media.startYear,
    );
  }

  String get displayTitle => titleRomaji ?? titleEnglish ?? 'Unknown';
}
