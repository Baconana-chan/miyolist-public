import 'package:hive/hive.dart';

part 'anime_model.g.dart';

@HiveType(typeId: 1)
class AnimeModel extends HiveObject {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String titleRomaji;
  
  @HiveField(2)
  final String? titleEnglish;
  
  @HiveField(3)
  final String? titleNative;
  
  @HiveField(4)
  final String? coverImage;
  
  @HiveField(5)
  final String? bannerImage;
  
  @HiveField(6)
  final int? episodes;
  
  @HiveField(7)
  final String? status;
  
  @HiveField(8)
  final String? format;
  
  @HiveField(9)
  final String? season;
  
  @HiveField(10)
  final int? seasonYear;
  
  @HiveField(11)
  final double? averageScore;
  
  @HiveField(12)
  final String? description;
  
  @HiveField(13)
  final List<String>? genres;
  
  @HiveField(14)
  final bool isAdult;
  
  @HiveField(15)
  final int? chapters;
  
  @HiveField(16)
  final int? volumes;

  @HiveField(17)
  final String? countryOfOrigin;

  @HiveField(18)
  final int? startYear;

  @HiveField(19)
  final int? popularity;

  DateTime? get startDate {
    if (startYear != null) {
      return DateTime(startYear!);
    }
    return null;
  }

  AnimeModel({
    required this.id,
    required this.titleRomaji,
    this.titleEnglish,
    this.titleNative,
    this.coverImage,
    this.bannerImage,
    this.episodes,
    this.status,
    this.format,
    this.season,
    this.seasonYear,
    this.averageScore,
    this.description,
    this.genres,
    this.isAdult = false,
    this.chapters,
    this.volumes,
    this.countryOfOrigin,
    this.startYear,
    this.popularity,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(
      id: json['id'] as int,
      titleRomaji: json['title']['romaji'] as String,
      titleEnglish: json['title']['english'] as String?,
      titleNative: json['title']['native'] as String?,
      coverImage: json['coverImage']?['large'] as String?,
      bannerImage: json['bannerImage'] as String?,
      episodes: json['episodes'] as int?,
      status: json['status'] as String?,
      format: json['format'] as String?,
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      averageScore: json['averageScore']?.toDouble(),
      description: json['description'] as String?,
      isAdult: json['isAdult'] as bool? ?? false,
      genres: (json['genres'] as List?)?.cast<String>(),
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      countryOfOrigin: json['countryOfOrigin'] as String?,
      startYear: json['startDate']?['year'] as int?,
      popularity: json['popularity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': {
        'romaji': titleRomaji,
        'english': titleEnglish,
        'native': titleNative,
      },
      'coverImage': {'large': coverImage},
      'bannerImage': bannerImage,
      'episodes': episodes,
      'status': status,
      'format': format,
      'season': season,
      'seasonYear': seasonYear,
      'averageScore': averageScore,
      'description': description,
      'isAdult': isAdult,
      'genres': genres,
      'chapters': chapters,
      'volumes': volumes,
      'countryOfOrigin': countryOfOrigin,
      'startDate': startYear != null ? {'year': startYear} : null,
      'popularity': popularity,
    };
  }

  /// Convert to JSON for Supabase sync (simplified format for JSONB storage)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'title_romaji': titleRomaji,
      'title_english': titleEnglish,
      'title_native': titleNative,
      'cover_image': coverImage,
      'banner_image': bannerImage,
      'episodes': episodes,
      'status': status,
      'format': format,
      'season': season,
      'season_year': seasonYear,
      'average_score': averageScore,
      'description': description,
      'is_adult': isAdult,
      'genres': genres,
      'chapters': chapters,
      'volumes': volumes,
    };
  }
}

