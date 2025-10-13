import 'package:hive/hive.dart';

part 'character_details.g.dart';

@HiveType(typeId: 13)
class CharacterDetails extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? imageUrl;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final int? favourites;

  @HiveField(5)
  final String? gender;

  @HiveField(6)
  final String? age;

  @HiveField(7)
  final String? dateOfBirth;

  @HiveField(8)
  final List<String>? alternativeNames;

  @HiveField(9)
  final List<CharacterMedia>? media;

  @HiveField(10)
  final DateTime cachedAt;

  CharacterDetails({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.favourites,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.alternativeNames,
    this.media,
    required this.cachedAt,
  });

  factory CharacterDetails.fromJson(Map<String, dynamic> json) {
    return CharacterDetails(
      id: json['id'] as int,
      name: json['name']?['full'] as String? ?? 'Unknown',
      imageUrl: json['image']?['large'] as String?,
      description: json['description'] as String?,
      favourites: json['favourites'] as int?,
      gender: json['gender'] as String?,
      age: json['age'] as String?,
      dateOfBirth: _formatDate(json['dateOfBirth']),
      alternativeNames: (json['name']?['alternative'] as List?)?.cast<String>(),
      media: (json['media']?['edges'] as List?)
          ?.map((e) => CharacterMedia.fromJson(e))
          .toList(),
      cachedAt: DateTime.now(),
    );
  }

  static String? _formatDate(Map<String, dynamic>? date) {
    if (date == null) return null;
    final day = date['day'];
    final month = date['month'];
    final year = date['year'];
    if (day != null && month != null && year != null) {
      return '$day/$month/$year';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'favourites': favourites,
      'gender': gender,
      'age': age,
      'dateOfBirth': dateOfBirth,
      'alternativeNames': alternativeNames,
      'media': media?.map((e) => e.toJson()).toList(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  bool isCacheExpired({Duration maxAge = const Duration(days: 7)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

@HiveType(typeId: 14)
class CharacterMedia extends HiveObject {
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
  final String? characterRole;

  CharacterMedia({
    required this.id,
    required this.title,
    this.coverImage,
    this.type,
    this.format,
    this.characterRole,
  });

  factory CharacterMedia.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    return CharacterMedia(
      id: node['id'] as int,
      title: node['title']?['romaji'] as String? ?? 'Unknown',
      coverImage: node['coverImage']?['large'] as String?,
      type: node['type'] as String?,
      format: node['format'] as String?,
      characterRole: json['characterRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverImage': coverImage,
      'type': type,
      'format': format,
      'characterRole': characterRole,
    };
  }
}
