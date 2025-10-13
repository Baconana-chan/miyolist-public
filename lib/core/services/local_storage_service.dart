import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/anime_model.dart';
import '../models/media_list_entry.dart';
import '../models/user_settings.dart';
import '../models/media_details.dart';
import '../models/character_details.dart';
import '../models/staff_details.dart';
import '../models/studio_details.dart';
import '../models/sync_conflict.dart';

class LocalStorageService {
  /// Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(AnimeModelAdapter());
    Hive.registerAdapter(MediaListEntryAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(MediaDetailsAdapter());
    Hive.registerAdapter(MediaCharacterAdapter());
    Hive.registerAdapter(MediaRelationAdapter());
    Hive.registerAdapter(MediaTagAdapter());
    Hive.registerAdapter(MediaExternalLinkAdapter());
    Hive.registerAdapter(MediaStaffAdapter());
    Hive.registerAdapter(MediaRecommendationAdapter());
    Hive.registerAdapter(MediaStudioAdapter());
    Hive.registerAdapter(CharacterDetailsAdapter());
    Hive.registerAdapter(CharacterMediaAdapter());
    Hive.registerAdapter(StaffDetailsAdapter());
    Hive.registerAdapter(StaffMediaAdapter());
    Hive.registerAdapter(StaffCharacterAdapter());
    Hive.registerAdapter(SocialMediaLinkAdapter());
    Hive.registerAdapter(StudioDetailsAdapter());
    Hive.registerAdapter(StudioMediaAdapter());
    
    // Open boxes with error handling for schema changes
    try {
      await Hive.openBox<UserModel>(AppConstants.userBox);
      await Hive.openBox<MediaListEntry>(AppConstants.animeListBox);
      await Hive.openBox<MediaListEntry>(AppConstants.mangaListBox);
      await Hive.openBox(AppConstants.favoritesBox);
      await Hive.openBox(AppConstants.settingsBox);
      await Hive.openBox<MediaDetails>(AppConstants.mediaCacheBox);
      await Hive.openBox<CharacterDetails>(AppConstants.characterCacheBox);
      await Hive.openBox<StaffDetails>(AppConstants.staffCacheBox);
      await Hive.openBox<StudioDetails>(AppConstants.studioCacheBox);
    } catch (e) {
      // If there's an error opening boxes (likely due to schema changes),
      // delete the problematic cache boxes and retry
      print('Error opening Hive boxes: $e');
      print('Clearing cache boxes due to schema migration...');
      
      try {
        // Delete only cache boxes, preserve user data
        await Hive.deleteBoxFromDisk(AppConstants.mediaCacheBox);
        await Hive.deleteBoxFromDisk(AppConstants.characterCacheBox);
        await Hive.deleteBoxFromDisk(AppConstants.staffCacheBox);
        await Hive.deleteBoxFromDisk(AppConstants.studioCacheBox);
        
        // Retry opening all boxes
        await Hive.openBox<UserModel>(AppConstants.userBox);
        await Hive.openBox<MediaListEntry>(AppConstants.animeListBox);
        await Hive.openBox<MediaListEntry>(AppConstants.mangaListBox);
        await Hive.openBox(AppConstants.favoritesBox);
        await Hive.openBox(AppConstants.settingsBox);
        await Hive.openBox<MediaDetails>(AppConstants.mediaCacheBox);
        await Hive.openBox<CharacterDetails>(AppConstants.characterCacheBox);
        await Hive.openBox<StaffDetails>(AppConstants.staffCacheBox);
        await Hive.openBox<StudioDetails>(AppConstants.studioCacheBox);
        
        print('Cache boxes cleared and reopened successfully');
      } catch (retryError) {
        print('Failed to recover from schema migration: $retryError');
        rethrow;
      }
    }
  }

  /// Get user box
  Box<UserModel> get userBox => Hive.box<UserModel>(AppConstants.userBox);

  /// Get anime list box
  Box<MediaListEntry> get animeListBox =>
      Hive.box<MediaListEntry>(AppConstants.animeListBox);

  /// Get manga list box
  Box<MediaListEntry> get mangaListBox =>
      Hive.box<MediaListEntry>(AppConstants.mangaListBox);

  /// Get favorites box
  Box get favoritesBox => Hive.box(AppConstants.favoritesBox);

  /// Get settings box
  Box get settingsBox => Hive.box(AppConstants.settingsBox);

  /// Get media cache box
  Box<MediaDetails> get mediaCacheBox =>
      Hive.box<MediaDetails>(AppConstants.mediaCacheBox);

  /// Get character cache box
  Box<CharacterDetails> get characterCacheBox =>
      Hive.box<CharacterDetails>(AppConstants.characterCacheBox);

  /// Get staff cache box
  Box<StaffDetails> get staffCacheBox =>
      Hive.box<StaffDetails>(AppConstants.staffCacheBox);

  /// Get studio cache box
  Box<StudioDetails> get studioCacheBox =>
      Hive.box<StudioDetails>(AppConstants.studioCacheBox);

  /// Save user data
  Future<void> saveUser(UserModel user) async {
    await userBox.put('current_user', user);
  }

  /// Get saved user
  UserModel? getUser() {
    return userBox.get('current_user');
  }

  /// Save anime list
  Future<void> saveAnimeList(List<MediaListEntry> entries) async {
    await animeListBox.clear();
    for (var entry in entries) {
      await animeListBox.put(entry.id, entry);
    }
  }

  /// Get anime list
  List<MediaListEntry> getAnimeList() {
    return animeListBox.values.toList();
  }

  /// Save manga list
  Future<void> saveMangaList(List<MediaListEntry> entries) async {
    await mangaListBox.clear();
    for (var entry in entries) {
      await mangaListBox.put(entry.id, entry);
    }
  }

  /// Get manga list
  List<MediaListEntry> getMangaList() {
    return mangaListBox.values.toList();
  }

  /// Update single anime entry
  Future<void> updateAnimeEntry(MediaListEntry entry) async {
    await animeListBox.put(entry.id, entry);
  }

  /// Update single manga entry
  Future<void> updateMangaEntry(MediaListEntry entry) async {
    await mangaListBox.put(entry.id, entry);
  }

  /// Delete anime entry
  Future<void> deleteAnimeEntry(int entryId) async {
    await animeListBox.delete(entryId);
  }

  /// Delete manga entry
  Future<void> deleteMangaEntry(int entryId) async {
    await mangaListBox.delete(entryId);
  }

  /// Save favorites
  Future<void> saveFavorites(Map<String, dynamic> favorites) async {
    await favoritesBox.put('favorites', favorites);
  }

  /// Get favorites
  Map<String, dynamic>? getFavorites() {
    final data = favoritesBox.get('favorites');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  /// Save last sync timestamp
  Future<void> saveLastSyncTime(DateTime time) async {
    await settingsBox.put(AppConstants.lastSyncKey, time.toIso8601String());
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    final timeString = settingsBox.get(AppConstants.lastSyncKey) as String?;
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  /// Save user privacy settings
  Future<void> saveUserSettings(UserSettings settings) async {
    await settingsBox.put('user_settings', settings.toJson());
  }

  /// Get user privacy settings
  UserSettings? getUserSettings() {
    final data = settingsBox.get('user_settings');
    if (data == null) return null;
    return UserSettings.fromJson(Map<String, dynamic>.from(data));
  }

  /// Check if user has public profile
  bool isPublicProfile() {
    final settings = getUserSettings();
    return settings?.isPublicProfile ?? false;
  }

  /// Check if cloud sync is enabled
  bool isCloudSyncEnabled() {
    final settings = getUserSettings();
    return settings?.enableCloudSync ?? false;
  }

  /// Save conflict resolution strategy
  Future<void> saveConflictResolutionStrategy(ConflictResolutionStrategy strategy) async {
    await settingsBox.put('conflict_resolution_strategy', strategy.name);
  }

  /// Get conflict resolution strategy
  ConflictResolutionStrategy? getConflictResolutionStrategy() {
    final strategyName = settingsBox.get('conflict_resolution_strategy') as String?;
    if (strategyName == null) return null;
    
    return ConflictResolutionStrategy.values.firstWhere(
      (s) => s.name == strategyName,
      orElse: () => ConflictResolutionStrategy.lastWriteWins,
    );
  }

  /// Clear all data (for logout)
  Future<void> clearAll() async {
    await userBox.clear();
    await animeListBox.clear();
    await mangaListBox.clear();
    await favoritesBox.clear();
    await settingsBox.clear();
  }

  /// Save media details to cache
  Future<void> saveMediaDetails(MediaDetails media) async {
    await mediaCacheBox.put(media.id, media);
  }

  /// Get media details from cache
  MediaDetails? getMediaDetails(int mediaId) {
    return mediaCacheBox.get(mediaId);
  }

  /// Get all cached media
  List<MediaDetails> getAllCachedMedia() {
    return mediaCacheBox.values.toList();
  }

  /// Save character details to cache
  Future<void> saveCharacterDetails(CharacterDetails character) async {
    await characterCacheBox.put(character.id, character);
  }

  /// Get character details from cache
  CharacterDetails? getCharacterDetails(int characterId) {
    return characterCacheBox.get(characterId);
  }

  /// Get all cached characters
  List<CharacterDetails> getAllCachedCharacters() {
    return characterCacheBox.values.toList();
  }

  /// Save staff details to cache
  Future<void> saveStaffDetails(StaffDetails staff) async {
    await staffCacheBox.put(staff.id, staff);
  }

  /// Get staff details from cache
  StaffDetails? getStaffDetails(int staffId) {
    return staffCacheBox.get(staffId);
  }

  /// Get all cached staff
  List<StaffDetails> getAllCachedStaff() {
    return staffCacheBox.values.toList();
  }

  /// Save studio details to cache
  Future<void> saveStudioDetails(StudioDetails studio) async {
    await studioCacheBox.put(studio.id, studio);
  }

  /// Get studio details from cache
  StudioDetails? getStudioDetails(int studioId) {
    return studioCacheBox.get(studioId);
  }

  /// Get all cached studios
  List<StudioDetails> getAllCachedStudios() {
    return studioCacheBox.values.toList();
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache({Duration maxAge = const Duration(days: 7)}) async {
    // Clear expired media cache
    final expiredMedia = mediaCacheBox.values
        .where((media) => media.isCacheExpired(maxAge: maxAge))
        .map((media) => media.id)
        .toList();
    
    for (final id in expiredMedia) {
      await mediaCacheBox.delete(id);
    }
    
    // Clear expired character cache
    final expiredCharacters = characterCacheBox.values
        .where((char) => char.isCacheExpired(maxAge: maxAge))
        .map((char) => char.id)
        .toList();
    
    for (final id in expiredCharacters) {
      await characterCacheBox.delete(id);
    }
    
    // Clear expired staff cache
    final expiredStaff = staffCacheBox.values
        .where((staff) => staff.isCacheExpired(maxAge: maxAge))
        .map((staff) => staff.id)
        .toList();
    
    for (final id in expiredStaff) {
      await staffCacheBox.delete(id);
    }
    
    // Clear expired studio cache
    final expiredStudios = studioCacheBox.values
        .where((studio) => studio.isCacheExpired(maxAge: maxAge))
        .map((studio) => studio.id)
        .toList();
    
    for (final id in expiredStudios) {
      await studioCacheBox.delete(id);
    }
    
    final totalExpired = expiredMedia.length + expiredCharacters.length + 
                        expiredStaff.length + expiredStudios.length;
    print('🗑️ Cleared $totalExpired expired cache entries');
  }

  /// Get total database size in bytes
  Future<int> getDatabaseSizeInBytes() async {
    int totalSize = 0;

    try {
      // Получаем путь к директории Hive
      final hivePath = Hive.box(AppConstants.settingsBox).path;
      if (hivePath != null) {
        final directory = Directory(hivePath).parent;
        
        // Перечисляем все файлы Hive в директории
        final files = directory.listSync().where((file) {
          final name = file.path.split(Platform.pathSeparator).last;
          return name.endsWith('.hive') || name.endsWith('.lock');
        });

        // Суммируем размеры всех файлов
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
    } catch (e) {
      print('❌ Error calculating database size: $e');
    }

    return totalSize;
  }

  /// Get database size in megabytes
  Future<double> getDatabaseSizeInMB() async {
    final bytes = await getDatabaseSizeInBytes();
    return bytes / (1024 * 1024);
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final sizeInBytes = await getDatabaseSizeInBytes();
    final sizeInMB = sizeInBytes / (1024 * 1024);

    return {
      'totalSizeBytes': sizeInBytes,
      'totalSizeMB': sizeInMB,
      'userBoxEntries': userBox.length,
      'animeListEntries': animeListBox.length,
      'mangaListEntries': mangaListBox.length,
      'mediaCacheEntries': mediaCacheBox.length,
      'characterCacheEntries': characterCacheBox.length,
      'staffCacheEntries': staffCacheBox.length,
      'studioCacheEntries': studioCacheBox.length,
      'favoritesEntries': favoritesBox.length,
      'settingsEntries': settingsBox.length,
    };
  }

  /// Check if database size exceeds limit
  Future<bool> isDatabaseSizeExceeded() async {
    final settings = getUserSettings();
    if (settings == null) return false;

    final currentSizeMB = await getDatabaseSizeInMB();
    return currentSizeMB > settings.cacheSizeLimitMB;
  }

  /// Clear old cache entries if size limit is exceeded
  Future<void> enforceSizeLimit() async {
    if (!await isDatabaseSizeExceeded()) return;

    print('⚠️ Database size limit exceeded, clearing old cache...');
    
    // Сначала очищаем просроченный кеш
    await clearExpiredCache(maxAge: const Duration(days: 7));
    
    // Если всё ещё превышен лимит, очищаем более старый кеш
    if (await isDatabaseSizeExceeded()) {
      await clearExpiredCache(maxAge: const Duration(days: 3));
    }
    
    // Если всё ещё превышен лимит, очищаем весь кеш медиа, персонажей, стаффа и студий
    if (await isDatabaseSizeExceeded()) {
      print('⚠️ Clearing all cache to reduce size');
      await mediaCacheBox.clear();
      await characterCacheBox.clear();
      await staffCacheBox.clear();
      await studioCacheBox.clear();
    }

    final newSizeMB = await getDatabaseSizeInMB();
    print('✅ Database size reduced to ${newSizeMB.toStringAsFixed(2)} MB');
  }
}

