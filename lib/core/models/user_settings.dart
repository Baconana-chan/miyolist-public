import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 3)
class UserSettings extends HiveObject {
  @HiveField(0)
  final bool isPublicProfile;
  
  @HiveField(1)
  final bool enableCloudSync;
  
  @HiveField(2)
  final bool enableSocialFeatures;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final DateTime? updatedAt;

  @HiveField(5)
  final int cacheSizeLimitMB; // Лимит размера кеша в мегабайтах

  @HiveField(6)
  final bool syncAnimeList; // Синхронизировать аниме список

  @HiveField(7)
  final bool syncMangaList; // Синхронизировать мангу список

  @HiveField(8)
  final bool syncFavorites; // Синхронизировать избранное

  @HiveField(9)
  final bool syncUserProfile; // Синхронизировать профиль пользователя

  @HiveField(10)
  final bool showAnimeTab; // Показывать вкладку "Anime"

  @HiveField(11)
  final bool showMangaTab; // Показывать вкладку "Manga"

  @HiveField(12)
  final bool showNovelTab; // Показывать вкладку "Novels"

  @HiveField(13)
  final String themeMode; // Режим темы ('dark', 'light', 'carrot')

  @HiveField(14)
  final String animeViewMode; // Режим отображения аниме ('grid', 'list', 'compact')

  @HiveField(15)
  final String mangaViewMode; // Режим отображения манги ('grid', 'list', 'compact')

  @HiveField(16)
  final String novelViewMode; // Режим отображения ранобэ ('grid', 'list', 'compact')

  @HiveField(17)
  final int imageCacheSizeLimitMB; // Лимит размера кэша изображений в мегабайтах

  @HiveField(18)
  final bool hasSeenWelcomeScreen; // Показывался ли welcome screen

  UserSettings({
    required this.isPublicProfile,
    required this.enableCloudSync,
    required this.enableSocialFeatures,
    required this.createdAt,
    this.updatedAt,
    this.cacheSizeLimitMB = 200, // По умолчанию 200 МБ
    this.syncAnimeList = true, // По умолчанию включено
    this.syncMangaList = true, // По умолчанию включено
    this.syncFavorites = true, // По умолчанию включено
    this.syncUserProfile = true, // По умолчанию включено
    this.showAnimeTab = true, // По умолчанию показывать
    this.showMangaTab = true, // По умолчанию показывать
    this.showNovelTab = true, // По умолчанию показывать
    this.themeMode = 'dark', // По умолчанию темная тема
    this.animeViewMode = 'grid', // По умолчанию grid
    this.mangaViewMode = 'grid', // По умолчанию grid
    this.novelViewMode = 'grid', // По умолчанию grid
    this.imageCacheSizeLimitMB = 500, // По умолчанию 500 МБ
    this.hasSeenWelcomeScreen = false, // По умолчанию не показывался
  });

  factory UserSettings.defaultPrivate() {
    return UserSettings(
      isPublicProfile: false,
      enableCloudSync: false,
      enableSocialFeatures: false,
      createdAt: DateTime.now(),
      cacheSizeLimitMB: 200,
      syncAnimeList: true,
      syncMangaList: true,
      syncFavorites: true,
      syncUserProfile: true,
      showAnimeTab: true,
      showMangaTab: true,
      showNovelTab: true,
      themeMode: 'dark',
      animeViewMode: 'grid',
      mangaViewMode: 'grid',
      novelViewMode: 'grid',
      imageCacheSizeLimitMB: 500,
      hasSeenWelcomeScreen: false,
    );
  }

  factory UserSettings.defaultPublic() {
    return UserSettings(
      isPublicProfile: true,
      enableCloudSync: true,
      enableSocialFeatures: true,
      createdAt: DateTime.now(),
      cacheSizeLimitMB: 200,
      syncAnimeList: true,
      syncMangaList: true,
      syncFavorites: true,
      syncUserProfile: true,
      showAnimeTab: true,
      showMangaTab: true,
      showNovelTab: true,
      themeMode: 'dark',
      animeViewMode: 'grid',
      mangaViewMode: 'grid',
      novelViewMode: 'grid',
      imageCacheSizeLimitMB: 500,
      hasSeenWelcomeScreen: false,
    );
  }

  UserSettings copyWith({
    bool? isPublicProfile,
    bool? enableCloudSync,
    bool? enableSocialFeatures,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cacheSizeLimitMB,
    bool? syncAnimeList,
    bool? syncMangaList,
    bool? syncFavorites,
    bool? syncUserProfile,
    bool? showAnimeTab,
    bool? showMangaTab,
    bool? showNovelTab,
    String? themeMode,
    String? animeViewMode,
    String? mangaViewMode,
    String? novelViewMode,
    int? imageCacheSizeLimitMB,
    bool? hasSeenWelcomeScreen,
  }) {
    return UserSettings(
      isPublicProfile: isPublicProfile ?? this.isPublicProfile,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      enableSocialFeatures: enableSocialFeatures ?? this.enableSocialFeatures,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cacheSizeLimitMB: cacheSizeLimitMB ?? this.cacheSizeLimitMB,
      syncAnimeList: syncAnimeList ?? this.syncAnimeList,
      syncMangaList: syncMangaList ?? this.syncMangaList,
      syncFavorites: syncFavorites ?? this.syncFavorites,
      syncUserProfile: syncUserProfile ?? this.syncUserProfile,
      showAnimeTab: showAnimeTab ?? this.showAnimeTab,
      showMangaTab: showMangaTab ?? this.showMangaTab,
      showNovelTab: showNovelTab ?? this.showNovelTab,
      themeMode: themeMode ?? this.themeMode,
      animeViewMode: animeViewMode ?? this.animeViewMode,
      mangaViewMode: mangaViewMode ?? this.mangaViewMode,
      novelViewMode: novelViewMode ?? this.novelViewMode,
      imageCacheSizeLimitMB: imageCacheSizeLimitMB ?? this.imageCacheSizeLimitMB,
      hasSeenWelcomeScreen: hasSeenWelcomeScreen ?? this.hasSeenWelcomeScreen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPublicProfile': isPublicProfile,
      'enableCloudSync': enableCloudSync,
      'enableSocialFeatures': enableSocialFeatures,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'cacheSizeLimitMB': cacheSizeLimitMB,
      'syncAnimeList': syncAnimeList,
      'syncMangaList': syncMangaList,
      'syncFavorites': syncFavorites,
      'syncUserProfile': syncUserProfile,
      'showAnimeTab': showAnimeTab,
      'showMangaTab': showMangaTab,
      'showNovelTab': showNovelTab,
      'themeMode': themeMode,
      'animeViewMode': animeViewMode,
      'mangaViewMode': mangaViewMode,
      'novelViewMode': novelViewMode,
      'imageCacheSizeLimitMB': imageCacheSizeLimitMB,
      'hasSeenWelcomeScreen': hasSeenWelcomeScreen,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      isPublicProfile: json['isPublicProfile'] as bool,
      enableCloudSync: json['enableCloudSync'] as bool,
      enableSocialFeatures: json['enableSocialFeatures'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      cacheSizeLimitMB: json['cacheSizeLimitMB'] as int? ?? 200,
      syncAnimeList: json['syncAnimeList'] as bool? ?? true,
      syncMangaList: json['syncMangaList'] as bool? ?? true,
      syncFavorites: json['syncFavorites'] as bool? ?? true,
      syncUserProfile: json['syncUserProfile'] as bool? ?? true,
      showAnimeTab: json['showAnimeTab'] as bool? ?? true,
      showMangaTab: json['showMangaTab'] as bool? ?? true,
      showNovelTab: json['showNovelTab'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'dark',
      animeViewMode: json['animeViewMode'] as String? ?? 'grid',
      mangaViewMode: json['mangaViewMode'] as String? ?? 'grid',
      novelViewMode: json['novelViewMode'] as String? ?? 'grid',
      imageCacheSizeLimitMB: json['imageCacheSizeLimitMB'] as int? ?? 500,
      hasSeenWelcomeScreen: json['hasSeenWelcomeScreen'] as bool? ?? false,
    );
  }
}
