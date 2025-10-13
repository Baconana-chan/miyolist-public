import 'package:hive/hive.dart';

part 'staff_details.g.dart';

@HiveType(typeId: 15)
class StaffDetails extends HiveObject {
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
  final String? dateOfDeath;

  @HiveField(9)
  final List<String>? alternativeNames;

  @HiveField(10)
  final String? homeTown;

  @HiveField(11)
  final String? yearsActive;

  @HiveField(12)
  final List<StaffMedia>? staffMedia;

  @HiveField(13)
  final List<StaffCharacter>? characters;

  @HiveField(14)
  final List<SocialMediaLink>? socialMedia;

  @HiveField(15)
  final DateTime cachedAt;

  StaffDetails({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.favourites,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.dateOfDeath,
    this.alternativeNames,
    this.homeTown,
    this.yearsActive,
    this.staffMedia,
    this.characters,
    this.socialMedia,
    required this.cachedAt,
  });

  factory StaffDetails.fromJson(Map<String, dynamic> json) {
    return StaffDetails(
      id: json['id'] as int,
      name: json['name']?['full'] as String? ?? 'Unknown',
      imageUrl: json['image']?['large'] as String?,
      description: json['description'] as String?,
      favourites: json['favourites'] as int?,
      gender: json['gender'] as String?,
      age: json['age'] as String?,
      dateOfBirth: _formatDate(json['dateOfBirth']),
      dateOfDeath: _formatDate(json['dateOfDeath']),
      alternativeNames: (json['name']?['alternative'] as List?)?.cast<String>(),
      homeTown: json['homeTown'] as String?,
      yearsActive: _formatYearsActive(json['yearsActive']),
      staffMedia: (json['staffMedia']?['edges'] as List?)
          ?.map((e) => StaffMedia.fromJson(e))
          .toList(),
      characters: (json['characters']?['edges'] as List?)
          ?.map((e) => StaffCharacter.fromJson(e))
          .toList(),
      socialMedia: _parseSocialMedia(json['siteUrl'] as String?),
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

  static String? _formatYearsActive(List<dynamic>? years) {
    if (years == null || years.isEmpty) return null;
    final start = years[0];
    final end = years.length > 1 ? years[1] : null;
    if (end == null || end == 0) {
      return '$start - Present';
    }
    return '$start - $end';
  }

  static List<SocialMediaLink>? _parseSocialMedia(String? siteUrl) {
    if (siteUrl == null) return null;
    return [
      SocialMediaLink(
        platform: 'AniList',
        url: siteUrl,
        icon: 'web',
      ),
    ];
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
      'dateOfDeath': dateOfDeath,
      'alternativeNames': alternativeNames,
      'homeTown': homeTown,
      'yearsActive': yearsActive,
      'staffMedia': staffMedia?.map((e) => e.toJson()).toList(),
      'characters': characters?.map((e) => e.toJson()).toList(),
      'socialMedia': socialMedia?.map((e) => e.toJson()).toList(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  bool isCacheExpired({Duration maxAge = const Duration(days: 7)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

@HiveType(typeId: 16)
class StaffMedia extends HiveObject {
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
  final String? staffRole;

  StaffMedia({
    required this.id,
    required this.title,
    this.coverImage,
    this.type,
    this.format,
    this.staffRole,
  });

  factory StaffMedia.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    return StaffMedia(
      id: node['id'] as int,
      title: node['title']?['romaji'] as String? ?? 'Unknown',
      coverImage: node['coverImage']?['large'] as String?,
      type: node['type'] as String?,
      format: node['format'] as String?,
      staffRole: json['staffRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverImage': coverImage,
      'type': type,
      'format': format,
      'staffRole': staffRole,
    };
  }
}

@HiveType(typeId: 17)
class StaffCharacter extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? imageUrl;

  @HiveField(3)
  final String? role;

  @HiveField(4)
  final int? mediaId;

  @HiveField(5)
  final String? mediaTitle;

  StaffCharacter({
    required this.id,
    required this.name,
    this.imageUrl,
    this.role,
    this.mediaId,
    this.mediaTitle,
  });

  factory StaffCharacter.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    final media = json['media']?.isNotEmpty == true ? json['media'][0] : null;
    
    return StaffCharacter(
      id: node['id'] as int,
      name: node['name']?['full'] as String? ?? 'Unknown',
      imageUrl: node['image']?['large'] as String?,
      role: json['role'] as String?,
      mediaId: media?['id'] as int?,
      mediaTitle: media?['title']?['romaji'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'role': role,
      'mediaId': mediaId,
      'mediaTitle': mediaTitle,
    };
  }
}

@HiveType(typeId: 18)
class SocialMediaLink extends HiveObject {
  @HiveField(0)
  final String platform;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String icon;

  SocialMediaLink({
    required this.platform,
    required this.url,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'url': url,
      'icon': icon,
    };
  }
}
