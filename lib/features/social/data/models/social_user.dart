import 'package:hive/hive.dart';

part 'social_user.g.dart';

/// Represents a user in the social system (Following/Followers)
@HiveType(typeId: 24) // Next available typeId
class SocialUser extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? avatarLarge;

  @HiveField(3)
  final String? avatarMedium;

  @HiveField(4)
  final String? bannerImage;

  @HiveField(5)
  final String? about;

  @HiveField(6)
  final bool isFollowing;

  @HiveField(7)
  final bool isFollower;

  @HiveField(8)
  final UserStatistics? statistics;

  @HiveField(9)
  final int donatorTier; // 0 = none, 1-4 = donator tiers

  @HiveField(10)
  final String? donatorBadge; // Custom badge text

  SocialUser({
    required this.id,
    required this.name,
    this.avatarLarge,
    this.avatarMedium,
    this.bannerImage,
    this.about,
    this.isFollowing = false,
    this.isFollower = false,
    this.statistics,
    this.donatorTier = 0,
    this.donatorBadge,
  });

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarLarge: json['avatar']?['large'] as String?,
      avatarMedium: json['avatar']?['medium'] as String?,
      bannerImage: json['bannerImage'] as String?,
      about: json['about'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isFollower: json['isFollower'] as bool? ?? false,
      statistics: json['statistics'] != null
          ? UserStatistics.fromJson(json['statistics'] as Map<String, dynamic>)
          : null,
      donatorTier: json['donatorTier'] as int? ?? 0,
      donatorBadge: json['donatorBadge'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': {
        'large': avatarLarge,
        'medium': avatarMedium,
      },
      'bannerImage': bannerImage,
      'about': about,
      'isFollowing': isFollowing,
      'isFollower': isFollower,
      'statistics': statistics?.toJson(),
      'donatorTier': donatorTier,
      'donatorBadge': donatorBadge,
    };
  }

  SocialUser copyWith({
    int? id,
    String? name,
    String? avatarLarge,
    String? avatarMedium,
    String? bannerImage,
    String? about,
    bool? isFollowing,
    bool? isFollower,
    UserStatistics? statistics,
    int? donatorTier,
    String? donatorBadge,
  }) {
    return SocialUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarLarge: avatarLarge ?? this.avatarLarge,
      avatarMedium: avatarMedium ?? this.avatarMedium,
      bannerImage: bannerImage ?? this.bannerImage,
      about: about ?? this.about,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
      statistics: statistics ?? this.statistics,
      donatorTier: donatorTier ?? this.donatorTier,
      donatorBadge: donatorBadge ?? this.donatorBadge,
    );
  }
}

/// User statistics for social display
@HiveType(typeId: 25)
class UserStatistics extends HiveObject {
  @HiveField(0)
  final MediaStatistics? anime;

  @HiveField(1)
  final MediaStatistics? manga;

  UserStatistics({
    this.anime,
    this.manga,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      anime: json['anime'] != null
          ? MediaStatistics.fromJson(json['anime'] as Map<String, dynamic>)
          : null,
      manga: json['manga'] != null
          ? MediaStatistics.fromJson(json['manga'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anime': anime?.toJson(),
      'manga': manga?.toJson(),
    };
  }
}

/// Media statistics (anime or manga)
@HiveType(typeId: 26)
class MediaStatistics extends HiveObject {
  @HiveField(0)
  final int count;

  @HiveField(1)
  final int? episodesWatched;

  @HiveField(2)
  final int? chaptersRead;

  @HiveField(3)
  final double? meanScore;

  @HiveField(4)
  final int? minutesWatched;

  @HiveField(5)
  final int? volumesRead;

  MediaStatistics({
    required this.count,
    this.episodesWatched,
    this.chaptersRead,
    this.meanScore,
    this.minutesWatched,
    this.volumesRead,
  });

  factory MediaStatistics.fromJson(Map<String, dynamic> json) {
    return MediaStatistics(
      count: json['count'] as int? ?? 0,
      episodesWatched: json['episodesWatched'] as int?,
      chaptersRead: json['chaptersRead'] as int?,
      meanScore: (json['meanScore'] as num?)?.toDouble(),
      minutesWatched: json['minutesWatched'] as int?,
      volumesRead: json['volumesRead'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'episodesWatched': episodesWatched,
      'chaptersRead': chaptersRead,
      'meanScore': meanScore,
      'minutesWatched': minutesWatched,
      'volumesRead': volumesRead,
    };
  }
}

/// Public user profile (complete profile data)
class PublicUserProfile {
  final int id;
  final String name;
  final String? avatarLarge;
  final String? avatarMedium;
  final String? bannerImage;
  final String? about;
  final bool isFollowing;
  final bool isFollower;
  final bool isBlocked;
  final int donatorTier; // 0 = none, 1 = $1, 2 = $5, 3 = $10, 4 = $20+
  final String? donatorBadge; // Custom badge text
  final List<String>? moderatorRoles; // Moderator roles if any
  final UserStatistics? statistics;
  final UserFavourites? favourites;
  final String? profileColor;

  PublicUserProfile({
    required this.id,
    required this.name,
    this.avatarLarge,
    this.avatarMedium,
    this.bannerImage,
    this.about,
    this.isFollowing = false,
    this.isFollower = false,
    this.isBlocked = false,
    this.donatorTier = 0,
    this.donatorBadge,
    this.moderatorRoles,
    this.statistics,
    this.favourites,
    this.profileColor,
  });

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    return PublicUserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarLarge: json['avatar']?['large'] as String?,
      avatarMedium: json['avatar']?['medium'] as String?,
      bannerImage: json['bannerImage'] as String?,
      about: json['about'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isFollower: json['isFollower'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      donatorTier: json['donatorTier'] as int? ?? 0,
      donatorBadge: json['donatorBadge'] as String?,
      moderatorRoles: (json['moderatorRoles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      statistics: json['statistics'] != null
          ? UserStatistics.fromJson(json['statistics'] as Map<String, dynamic>)
          : null,
      favourites: json['favourites'] != null
          ? UserFavourites.fromJson(json['favourites'] as Map<String, dynamic>)
          : null,
      profileColor: json['options']?['profileColor'] as String?,
    );
  }
}

/// User favourites
class UserFavourites {
  final List<FavouriteMedia> anime;
  final List<FavouriteMedia> manga;
  final List<FavouriteCharacter> characters;
  final List<FavouriteStaff> staff;
  final List<FavouriteStudio> studios;

  UserFavourites({
    this.anime = const [],
    this.manga = const [],
    this.characters = const [],
    this.staff = const [],
    this.studios = const [],
  });

  factory UserFavourites.fromJson(Map<String, dynamic> json) {
    return UserFavourites(
      anime: (json['anime']?['nodes'] as List<dynamic>?)
              ?.map((e) => FavouriteMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      manga: (json['manga']?['nodes'] as List<dynamic>?)
              ?.map((e) => FavouriteMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      characters: (json['characters']?['nodes'] as List<dynamic>?)
              ?.map((e) => FavouriteCharacter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      staff: (json['staff']?['nodes'] as List<dynamic>?)
              ?.map((e) => FavouriteStaff.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studios: (json['studios']?['nodes'] as List<dynamic>?)
              ?.map((e) => FavouriteStudio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Favourite media (anime/manga)
class FavouriteMedia {
  final int id;
  final String? titleRomaji;
  final String? titleEnglish;
  final String? titleNative;
  final String? titleUserPreferred;
  final String? coverImageLarge;
  final String? coverImageMedium;
  final String? format;
  final String? type;

  FavouriteMedia({
    required this.id,
    this.titleRomaji,
    this.titleEnglish,
    this.titleNative,
    this.titleUserPreferred,
    this.coverImageLarge,
    this.coverImageMedium,
    this.format,
    this.type,
  });

  factory FavouriteMedia.fromJson(Map<String, dynamic> json) {
    return FavouriteMedia(
      id: json['id'] as int,
      titleRomaji: json['title']?['romaji'] as String?,
      titleEnglish: json['title']?['english'] as String?,
      titleNative: json['title']?['native'] as String?,
      titleUserPreferred: json['title']?['userPreferred'] as String?,
      coverImageLarge: json['coverImage']?['large'] as String?,
      coverImageMedium: json['coverImage']?['medium'] as String?,
      format: json['format'] as String?,
      type: json['type'] as String?,
    );
  }
}

/// Favourite character
class FavouriteCharacter {
  final int id;
  final String? nameFull;
  final String? nameNative;
  final String? imageLarge;
  final String? imageMedium;

  FavouriteCharacter({
    required this.id,
    this.nameFull,
    this.nameNative,
    this.imageLarge,
    this.imageMedium,
  });

  factory FavouriteCharacter.fromJson(Map<String, dynamic> json) {
    return FavouriteCharacter(
      id: json['id'] as int,
      nameFull: json['name']?['full'] as String?,
      nameNative: json['name']?['native'] as String?,
      imageLarge: json['image']?['large'] as String?,
      imageMedium: json['image']?['medium'] as String?,
    );
  }
}

/// Favourite staff
class FavouriteStaff {
  final int id;
  final String? nameFull;
  final String? nameNative;
  final String? imageLarge;
  final String? imageMedium;

  FavouriteStaff({
    required this.id,
    this.nameFull,
    this.nameNative,
    this.imageLarge,
    this.imageMedium,
  });

  factory FavouriteStaff.fromJson(Map<String, dynamic> json) {
    return FavouriteStaff(
      id: json['id'] as int,
      nameFull: json['name']?['full'] as String?,
      nameNative: json['name']?['native'] as String?,
      imageLarge: json['image']?['large'] as String?,
      imageMedium: json['image']?['medium'] as String?,
    );
  }
}

/// Favourite studio
class FavouriteStudio {
  final int id;
  final String name;
  final bool isAnimationStudio;

  FavouriteStudio({
    required this.id,
    required this.name,
    this.isAnimationStudio = false,
  });

  factory FavouriteStudio.fromJson(Map<String, dynamic> json) {
    return FavouriteStudio(
      id: json['id'] as int,
      name: json['name'] as String,
      isAnimationStudio: json['isAnimationStudio'] as bool? ?? false,
    );
  }
}
