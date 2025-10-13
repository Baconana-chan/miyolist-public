import 'package:hive/hive.dart';

part 'studio_details.g.dart';

@HiveType(typeId: 19)
class StudioDetails extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isAnimationStudio;

  @HiveField(3)
  final int? favourites;

  @HiveField(4)
  final String? siteUrl;

  @HiveField(5)
  final List<StudioMedia>? media;

  @HiveField(6)
  final DateTime cachedAt;

  StudioDetails({
    required this.id,
    required this.name,
    required this.isAnimationStudio,
    this.favourites,
    this.siteUrl,
    this.media,
    required this.cachedAt,
  });

  factory StudioDetails.fromJson(Map<String, dynamic> json) {
    return StudioDetails(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      isAnimationStudio: json['isAnimationStudio'] as bool? ?? false,
      favourites: json['favourites'] as int?,
      siteUrl: json['siteUrl'] as String?,
      media: (json['media']?['edges'] as List?)
          ?.map((e) => StudioMedia.fromJson(e))
          .toList(),
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isAnimationStudio': isAnimationStudio,
      'favourites': favourites,
      'siteUrl': siteUrl,
      'media': media?.map((e) => e.toJson()).toList(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  bool isCacheExpired({Duration maxAge = const Duration(days: 7)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

@HiveType(typeId: 20)
class StudioMedia extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? coverImage;

  @HiveField(3)
  final String? type;

  @HiveField(4)
  final String? format;

  @HiveField(5)
  final int? seasonYear;

  @HiveField(6)
  final String? season;

  @HiveField(7)
  final int? averageScore;

  @HiveField(8)
  final bool isMainStudio;

  StudioMedia({
    required this.id,
    required this.title,
    this.coverImage,
    this.type,
    this.format,
    this.seasonYear,
    this.season,
    this.averageScore,
    this.isMainStudio = false,
  });

  factory StudioMedia.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    return StudioMedia(
      id: node['id'] as int,
      title: node['title']?['romaji'] as String? ?? 'Unknown',
      coverImage: node['coverImage']?['large'] as String?,
      type: node['type'] as String?,
      format: node['format'] as String?,
      seasonYear: node['seasonYear'] as int?,
      season: node['season'] as String?,
      averageScore: node['averageScore'] as int?,
      isMainStudio: json['isMainStudio'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverImage': coverImage,
      'type': type,
      'format': format,
      'seasonYear': seasonYear,
      'season': season,
      'averageScore': averageScore,
      'isMainStudio': isMainStudio,
    };
  }
}
