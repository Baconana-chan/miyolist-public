import 'package:hive/hive.dart';
import 'anime_model.dart';

part 'media_details.g.dart';

@HiveType(typeId: 6)
class MediaDetails extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String type; // ANIME, MANGA

  @HiveField(2)
  final String? titleRomaji;

  @HiveField(3)
  final String? titleEnglish;

  @HiveField(4)
  final String? titleNative;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? coverImage;

  @HiveField(7)
  final String? bannerImage;

  @HiveField(8)
  final int? episodes;

  @HiveField(9)
  final int? chapters;

  @HiveField(10)
  final int? volumes;

  @HiveField(11)
  final String? status; // FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED

  @HiveField(12)
  final String? format; // TV, MOVIE, OVA, MANGA, NOVEL, etc.

  @HiveField(13)
  final List<String>? genres;

  @HiveField(14)
  final double? averageScore;

  @HiveField(15)
  final int? popularity;

  @HiveField(16)
  final String? season; // WINTER, SPRING, SUMMER, FALL

  @HiveField(17)
  final int? seasonYear;

  @HiveField(18)
  final String? source; // ORIGINAL, MANGA, LIGHT_NOVEL, etc.

  @HiveField(19)
  final List<MediaStudio>? studios;

  @HiveField(20)
  final DateTime? startDate;

  @HiveField(21)
  final DateTime? endDate;

  @HiveField(22)
  final String? trailer;

  @HiveField(23)
  final List<String>? synonyms;

  @HiveField(24)
  final DateTime cachedAt;

  @HiveField(25)
  final int? duration; // длительность эпизода в минутах

  @HiveField(26)
  final List<MediaCharacter>? characters;

  @HiveField(27)
  final List<MediaRelation>? relations;

  @HiveField(28)
  final int? favourites; // количество добавивших в избранное

  @HiveField(29)
  final List<MediaTag>? tags;

  @HiveField(30)
  final List<MediaExternalLink>? externalLinks;

  @HiveField(31)
  final List<MediaStaff>? staff;

  @HiveField(32)
  final List<MediaRecommendation>? recommendations;

  @HiveField(33)
  final Map<String, int>? statusDistribution;

  MediaDetails({
    required this.id,
    required this.type,
    this.titleRomaji,
    this.titleEnglish,
    this.titleNative,
    this.description,
    this.coverImage,
    this.bannerImage,
    this.episodes,
    this.chapters,
    this.volumes,
    this.status,
    this.format,
    this.genres,
    this.averageScore,
    this.popularity,
    this.season,
    this.seasonYear,
    this.source,
    this.studios,
    this.startDate,
    this.endDate,
    this.trailer,
    this.synonyms,
    required this.cachedAt,
    this.duration,
    this.characters,
    this.relations,
    this.favourites,
    this.tags,
    this.externalLinks,
    this.staff,
    this.recommendations,
    this.statusDistribution,
  });

  factory MediaDetails.fromJson(Map<String, dynamic> json) {
    return MediaDetails(
      id: json['id'] as int,
      type: json['type'] as String,
      titleRomaji: json['title']?['romaji'] as String?,
      titleEnglish: json['title']?['english'] as String?,
      titleNative: json['title']?['native'] as String?,
      description: json['description'] as String?,
      coverImage: json['coverImage']?['extraLarge'] as String?,
      bannerImage: json['bannerImage'] as String?,
      episodes: json['episodes'] as int?,
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      status: json['status'] as String?,
      format: json['format'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      popularity: json['popularity'] as int?,
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      source: json['source'] as String?,
      studios: _parseStudios(json['studios']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      trailer: json['trailer']?['id'] as String?,
      synonyms: (json['synonyms'] as List<dynamic>?)?.cast<String>(),
      cachedAt: DateTime.now(),
      duration: json['duration'] as int?,
      characters: (json['characters']?['edges'] as List<dynamic>?)
          ?.map((e) => MediaCharacter.fromJson(e))
          .toList(),
      relations: (json['relations']?['edges'] as List<dynamic>?)
          ?.map((e) => MediaRelation.fromJson(e))
          .toList(),
      favourites: json['favourites'] as int?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => MediaTag.fromJson(e))
          .toList(),
      externalLinks: (json['externalLinks'] as List<dynamic>?)
          ?.map((e) => MediaExternalLink.fromJson(e))
          .toList(),
      staff: (json['staff']?['edges'] as List<dynamic>?)
          ?.map((e) => MediaStaff.fromJson(e))
          .toList(),
      recommendations: (json['recommendations']?['nodes'] as List<dynamic>?)
          ?.map((e) => MediaRecommendation.fromJson(e))
          .toList(),
      statusDistribution: json['stats']?['statusDistribution'] != null
          ? Map<String, int>.from(
              (json['stats']['statusDistribution'] as List<dynamic>)
                  .asMap()
                  .map((_, e) => MapEntry(
                      e['status'] as String, e['amount'] as int)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': {
        'romaji': titleRomaji,
        'english': titleEnglish,
        'native': titleNative,
      },
      'description': description,
      'coverImage': {'extraLarge': coverImage},
      'bannerImage': bannerImage,
      'episodes': episodes,
      'chapters': chapters,
      'volumes': volumes,
      'status': status,
      'format': format,
      'genres': genres,
      'averageScore': averageScore,
      'popularity': popularity,
      'season': season,
      'seasonYear': seasonYear,
      'source': source,
      'studios': {'nodes': studios?.map((s) => s.toJson()).toList()},
      'startDate': _dateToMap(startDate),
      'endDate': _dateToMap(endDate),
      'trailer': trailer != null ? {'id': trailer} : null,
      'synonyms': synonyms,
      'duration': duration,
      'characters': characters?.map((c) => c.toJson()).toList(),
      'relations': relations?.map((r) => r.toJson()).toList(),
      'favourites': favourites,
      'tags': tags?.map((t) => t.toJson()).toList(),
      'externalLinks': externalLinks?.map((e) => e.toJson()).toList(),
      'staff': staff?.map((s) => s.toJson()).toList(),
      'recommendations': recommendations?.map((r) => r.toJson()).toList(),
      'stats': statusDistribution != null
          ? {
              'statusDistribution': statusDistribution!.entries
                  .map((e) => {'status': e.key, 'amount': e.value})
                  .toList()
            }
          : null,
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'type': type,
      'title_romaji': titleRomaji,
      'title_english': titleEnglish,
      'title_native': titleNative,
      'description': description,
      'cover_image': coverImage,
      'banner_image': bannerImage,
      'episodes': episodes,
      'chapters': chapters,
      'volumes': volumes,
      'status': status,
      'format': format,
      'genres': genres,
      'average_score': averageScore,
      'popularity': popularity,
      'season': season,
      'season_year': seasonYear,
      'source': source,
      'studios': studios?.map((s) => s.toJson()).toList(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'trailer': trailer,
      'synonyms': synonyms,
      'cached_at': cachedAt.toIso8601String(),
      'duration': duration,
    };
  }

  static DateTime? _parseDate(Map<String, dynamic>? date) {
    if (date == null) return null;
    final year = date['year'] as int?;
    final month = date['month'] as int?;
    final day = date['day'] as int?;
    if (year == null) return null;
    return DateTime(year, month ?? 1, day ?? 1);
  }

  static List<MediaStudio>? _parseStudios(dynamic studiosData) {
    if (studiosData == null) return null;

    List<MediaStudio> studios = [];

    // Handle GraphQL format with edges (includes isMain field)
    if (studiosData is Map && studiosData.containsKey('edges')) {
      final edges = studiosData['edges'] as List<dynamic>?;
      if (edges != null) {
        for (var edge in edges) {
          if (edge is Map<String, dynamic>) {
            final node = edge['node'] as Map<String, dynamic>?;
            final isMain = edge['isMain'] as bool? ?? true;
            
            if (node != null) {
              // Find full studio data from nodes
              final nodes = studiosData['nodes'] as List<dynamic>?;
              if (nodes != null) {
                final studioData = nodes.firstWhere(
                  (n) => n['id'] == node['id'],
                  orElse: () => node,
                );
                if (studioData is Map<String, dynamic>) {
                  studios.add(MediaStudio(
                    id: studioData['id'] as int,
                    name: studioData['name'] as String,
                    isAnimationStudio: studioData['isAnimationStudio'] as bool? ?? false,
                    isMain: isMain,
                  ));
                }
              }
            }
          }
        }
        return studios.isEmpty ? null : studios;
      }
    }

    // Handle old format without edges
    List<dynamic> studiosList;

    if (studiosData is Map && studiosData.containsKey('nodes')) {
      // GraphQL format: { nodes: [...] }
      studiosList = studiosData['nodes'] as List<dynamic>;
    } else if (studiosData is List) {
      // Direct list format
      studiosList = studiosData;
    } else {
      return null;
    }

    return studiosList.map((item) {
      // Handle already parsed MediaStudio objects
      if (item is MediaStudio) {
        return item;
      }
      // Handle Map format
      if (item is Map<String, dynamic>) {
        return MediaStudio.fromJson(item);
      }
      // Skip invalid items
      return null;
    }).whereType<MediaStudio>().toList();
  }

  static Map<String, dynamic>? _dateToMap(DateTime? date) {
    if (date == null) return null;
    return {
      'year': date.year,
      'month': date.month,
      'day': date.day,
    };
  }

  /// Convert MediaDetails to AnimeModel for MediaListEntry
  AnimeModel toAnimeModel() {
    return AnimeModel(
      id: id,
      titleRomaji: titleRomaji ?? '',
      titleEnglish: titleEnglish,
      titleNative: titleNative,
      coverImage: coverImage,
      format: format,
      episodes: episodes,
      chapters: chapters,
      volumes: volumes,
      status: status,
      averageScore: averageScore?.toDouble(),
    );
  }

  String get displayTitle => titleEnglish ?? titleRomaji ?? titleNative ?? 'Unknown';

  bool get isAnime => type == 'ANIME';
  bool get isManga => type == 'MANGA';

  String get statusText {
    switch (status) {
      case 'FINISHED':
        return 'Finished';
      case 'RELEASING':
        return 'Releasing';
      case 'NOT_YET_RELEASED':
        return 'Not Yet Released';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  String get formatText {
    switch (format) {
      case 'TV':
        return 'TV';
      case 'TV_SHORT':
        return 'TV Short';
      case 'MOVIE':
        return 'Movie';
      case 'SPECIAL':
        return 'Special';
      case 'OVA':
        return 'OVA';
      case 'ONA':
        return 'ONA';
      case 'MUSIC':
        return 'Music';
      case 'MANGA':
        return 'Manga';
      case 'NOVEL':
        return 'Light Novel';
      case 'ONE_SHOT':
        return 'One Shot';
      default:
        return format ?? 'Unknown';
    }
  }

  bool isCacheExpired({Duration maxAge = const Duration(days: 7)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

@HiveType(typeId: 7)
class MediaCharacter extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? image;

  @HiveField(3)
  final String? role; // MAIN, SUPPORTING, BACKGROUND

  MediaCharacter({
    required this.id,
    this.name,
    this.image,
    this.role,
  });

  factory MediaCharacter.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    return MediaCharacter(
      id: node['id'] as int,
      name: node['name']?['full'] as String?,
      image: node['image']?['large'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node': {
        'id': id,
        'name': {'full': name},
        'image': {'large': image},
      },
      'role': role,
    };
  }
}

@HiveType(typeId: 8)
class MediaRelation extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String? type; // ANIME, MANGA

  @HiveField(2)
  final String? title;

  @HiveField(3)
  final String? coverImage;

  @HiveField(4)
  final String? relationType; // SEQUEL, PREQUEL, SIDE_STORY, etc.

  MediaRelation({
    required this.id,
    this.type,
    this.title,
    this.coverImage,
    this.relationType,
  });

  factory MediaRelation.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    return MediaRelation(
      id: node['id'] as int,
      type: node['type'] as String?,
      title: node['title']?['romaji'] as String?,
      coverImage: node['coverImage']?['large'] as String?,
      relationType: json['relationType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node': {
        'id': id,
        'type': type,
        'title': {'romaji': title},
        'coverImage': {'large': coverImage},
      },
      'relationType': relationType,
    };
  }

  String get relationTypeText {
    switch (relationType) {
      case 'ADAPTATION':
        return 'Adaptation';
      case 'PREQUEL':
        return 'Prequel';
      case 'SEQUEL':
        return 'Sequel';
      case 'PARENT':
        return 'Parent';
      case 'SIDE_STORY':
        return 'Side Story';
      case 'CHARACTER':
        return 'Character';
      case 'SUMMARY':
        return 'Summary';
      case 'ALTERNATIVE':
        return 'Alternative';
      case 'SPIN_OFF':
        return 'Spin-off';
      case 'OTHER':
        return 'Other';
      default:
        return relationType ?? 'Related';
    }
  }
}

@HiveType(typeId: 9)
class MediaTag extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final int? rank;

  @HiveField(4)
  final bool? isMediaSpoiler;

  MediaTag({
    required this.id,
    required this.name,
    this.description,
    this.rank,
    this.isMediaSpoiler,
  });

  factory MediaTag.fromJson(Map<String, dynamic> json) {
    return MediaTag(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      rank: json['rank'] as int?,
      isMediaSpoiler: json['isMediaSpoiler'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rank': rank,
      'isMediaSpoiler': isMediaSpoiler,
    };
  }
}

@HiveType(typeId: 10)
class MediaExternalLink extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String site;

  @HiveField(3)
  final String? type; // INFO, STREAMING, SOCIAL

  @HiveField(4)
  final String? language;

  MediaExternalLink({
    required this.id,
    required this.url,
    required this.site,
    this.type,
    this.language,
  });

  factory MediaExternalLink.fromJson(Map<String, dynamic> json) {
    return MediaExternalLink(
      id: json['id'] as int,
      url: json['url'] as String,
      site: json['site'] as String,
      type: json['type'] as String?,
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'site': site,
      'type': type,
      'language': language,
    };
  }

  bool get isStreaming => type == 'STREAMING';
}

@HiveType(typeId: 11)
class MediaStaff extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? image;

  @HiveField(3)
  final String? role;

  MediaStaff({
    required this.id,
    this.name,
    this.image,
    this.role,
  });

  factory MediaStaff.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    return MediaStaff(
      id: node['id'] as int,
      name: node['name']?['full'] as String?,
      image: node['image']?['large'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node': {
        'id': id,
        'name': {'full': name},
        'image': {'large': image},
      },
      'role': role,
    };
  }
}

@HiveType(typeId: 12)
class MediaRecommendation extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String? type;

  @HiveField(2)
  final String? title;

  @HiveField(3)
  final String? coverImage;

  @HiveField(4)
  final int? rating;

  @HiveField(5)
  final double? averageScore;

  MediaRecommendation({
    required this.id,
    this.type,
    this.title,
    this.coverImage,
    this.rating,
    this.averageScore,
  });

  factory MediaRecommendation.fromJson(Map<String, dynamic> json) {
    final rec = json['mediaRecommendation'];
    if (rec == null) return MediaRecommendation(id: -1);
    
    return MediaRecommendation(
      id: rec['id'] as int,
      type: rec['type'] as String?,
      title: rec['title']?['romaji'] as String? ?? rec['title']?['english'] as String?,
      coverImage: rec['coverImage']?['large'] as String?,
      rating: json['rating'] as int?,
      averageScore: (rec['averageScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaRecommendation': {
        'id': id,
        'type': type,
        'title': {'romaji': title},
        'coverImage': {'large': coverImage},
        'averageScore': averageScore,
      },
      'rating': rating,
    };
  }
}

@HiveType(typeId: 21)
class MediaStudio extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2, defaultValue: false)
  final bool isAnimationStudio;

  @HiveField(3, defaultValue: true)
  final bool isMain;

  MediaStudio({
    required this.id,
    required this.name,
    this.isAnimationStudio = false, // Значение по умолчанию для обратной совместимости
    this.isMain = true, // По умолчанию true для обратной совместимости
  });

  factory MediaStudio.fromJson(Map<String, dynamic> json) {
    return MediaStudio(
      id: json['id'] as int,
      name: json['name'] as String,
      isAnimationStudio: json['isAnimationStudio'] as bool? ?? false,
      isMain: json['isMain'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isAnimationStudio': isAnimationStudio,
      'isMain': isMain,
    };
  }
}
