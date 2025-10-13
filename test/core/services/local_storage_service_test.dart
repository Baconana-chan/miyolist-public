import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:miyolist/core/services/local_storage_service.dart';
import 'package:miyolist/core/models/user_model.dart';
import 'package:miyolist/core/models/media_list_entry.dart';
import 'package:miyolist/core/models/user_settings.dart';
import 'package:miyolist/core/models/anime_model.dart';
import 'package:miyolist/core/models/media_details.dart';
import 'package:miyolist/core/models/character_details.dart';
import 'package:miyolist/core/models/staff_details.dart';
import 'package:miyolist/core/models/studio_details.dart';
import 'package:miyolist/core/constants/app_constants.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService localStorageService;
  late String testDir;

  setUpAll(() async {
    // Create test directory
    testDir = '${Directory.current.path}/test/.hive_test';
    await Directory(testDir).create(recursive: true);
    
    // Initialize Hive with test directory
    Hive.init(testDir);
    
    // Register all required adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MediaListEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AnimeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(MediaDetailsAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(CharacterDetailsAdapter());
    }
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(StaffDetailsAdapter());
    }
    if (!Hive.isAdapterRegistered(33)) {
      Hive.registerAdapter(StudioDetailsAdapter());
    }
  });

  setUp(() async {
    // Delete all boxes before each test
    try {
      await Hive.deleteBoxFromDisk(AppConstants.userBox);
      await Hive.deleteBoxFromDisk(AppConstants.animeListBox);
      await Hive.deleteBoxFromDisk(AppConstants.mangaListBox);
      await Hive.deleteBoxFromDisk(AppConstants.settingsBox);
      await Hive.deleteBoxFromDisk(AppConstants.favoritesBox);
      await Hive.deleteBoxFromDisk(AppConstants.mediaCacheBox);
      await Hive.deleteBoxFromDisk(AppConstants.characterCacheBox);
      await Hive.deleteBoxFromDisk(AppConstants.staffCacheBox);
      await Hive.deleteBoxFromDisk(AppConstants.studioCacheBox);
    } catch (e) {
      // Ignore errors if boxes don't exist
    }
    
    // Initialize service
    await LocalStorageService.init();
    localStorageService = LocalStorageService();
  });

  tearDownAll(() async {
    // Close all boxes and clean up
    await Hive.close();
    try {
      await Directory(testDir).delete(recursive: true);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('LocalStorageService - User Management', () {
    test('saveUser should store user data', () async {
      // Arrange
      final user = UserModel(
        id: 12345,
        name: 'TestUser',
        avatar: 'https://example.com/avatar.jpg',
        bannerImage: null,
        about: 'Test user bio',
        displayAdultContent: false,
      );

      // Act
      await localStorageService.saveUser(user);
      final retrieved = await localStorageService.getUser();

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(12345));
      expect(retrieved.name, equals('TestUser'));
      expect(retrieved.avatar, equals('https://example.com/avatar.jpg'));
    });

    test('getUser should return null when no user saved', () async {
      // Act
      final user = await localStorageService.getUser();

      // Assert
      expect(user, isNull);
    });

    test('deleteUser should remove user data', () async {
      // Arrange
      final user = UserModel(
        id: 12345,
        name: 'TestUser',
        avatar: null,
        bannerImage: null,
        about: null,
        displayAdultContent: false,
      );
      await localStorageService.saveUser(user);

      // Act
      await localStorageService.clearAll();
      final retrieved = localStorageService.getUser();

      // Assert
      expect(retrieved, isNull);
    });
  });

  group('LocalStorageService - Anime List', () {
    test('saveAnimeList should store anime entries', () async {
      // Arrange
      final entries = [
        _createTestEntry(id: 1, mediaId: 101),
        _createTestEntry(id: 2, mediaId: 102),
        _createTestEntry(id: 3, mediaId: 103),
      ];

      // Act
      await localStorageService.saveAnimeList(entries);
      final retrieved = await localStorageService.getAnimeList();

      // Assert
      expect(retrieved.length, equals(3));
      expect(retrieved[0].id, equals(1));
      expect(retrieved[1].id, equals(2));
      expect(retrieved[2].id, equals(3));
    });

    test('getAnimeList should return empty list when no data', () async {
      // Act
      final entries = await localStorageService.getAnimeList();

      // Assert
      expect(entries, isEmpty);
    });

    test('updateAnimeEntry should modify existing entry', () async {
      // Arrange
      final entry = _createTestEntry(id: 1, mediaId: 101, progress: 5);
      await localStorageService.saveAnimeList([entry]);

      // Act
      final updated = _createTestEntry(id: 1, mediaId: 101, progress: 10);
      await localStorageService.updateAnimeEntry(updated);
      final retrieved = await localStorageService.getAnimeList();

      // Assert
      expect(retrieved.length, equals(1));
      expect(retrieved[0].progress, equals(10));
    });

    test('deleteAnimeEntry should remove entry', () async {
      // Arrange
      final entries = [
        _createTestEntry(id: 1, mediaId: 101),
        _createTestEntry(id: 2, mediaId: 102),
      ];
      await localStorageService.saveAnimeList(entries);

      // Act
      await localStorageService.deleteAnimeEntry(1);
      final retrieved = await localStorageService.getAnimeList();

      // Assert
      expect(retrieved.length, equals(1));
      expect(retrieved[0].id, equals(2));
    });

    test('clearAnimeList should remove all entries', () async {
      // Arrange
      final entries = [
        _createTestEntry(id: 1, mediaId: 101),
        _createTestEntry(id: 2, mediaId: 102),
      ];
      await localStorageService.saveAnimeList(entries);

      // Act
      await localStorageService.animeListBox.clear();
      final retrieved = await localStorageService.getAnimeList();

      // Assert
      expect(retrieved, isEmpty);
    });
  });

  group('LocalStorageService - Manga List', () {
    test('saveMangaList should store manga entries', () async {
      // Arrange
      final entries = [
        _createTestEntry(id: 1, mediaId: 201),
        _createTestEntry(id: 2, mediaId: 202),
      ];

      // Act
      await localStorageService.saveMangaList(entries);
      final retrieved = await localStorageService.getMangaList();

      // Assert
      expect(retrieved.length, equals(2));
      expect(retrieved[0].id, equals(1));
      expect(retrieved[1].id, equals(2));
    });

    test('getMangaList should return empty list when no data', () async {
      // Act
      final entries = await localStorageService.getMangaList();

      // Assert
      expect(entries, isEmpty);
    });
  });

  group('LocalStorageService - Settings', () {
    test('saveUserSettings should store settings', () async {
      // Arrange
      final settings = UserSettings.defaultPrivate();

      // Act
      await localStorageService.saveUserSettings(settings);
      final retrieved = await localStorageService.getUserSettings();

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.isPublicProfile, isFalse);
    });

    test('getUserSettings should return null when no settings', () async {
      // Act
      final settings = await localStorageService.getUserSettings();

      // Assert
      expect(settings, isNull);
    });

    test('saveUserSettings should update existing settings', () async {
      // Arrange
      final settings1 = UserSettings.defaultPrivate();
      await localStorageService.saveUserSettings(settings1);

      // Act
      final settings2 = settings1.copyWith(isPublicProfile: true);
      await localStorageService.saveUserSettings(settings2);
      final retrieved = await localStorageService.getUserSettings();

      // Assert
      expect(retrieved!.isPublicProfile, isTrue);
    });
  });

  group('LocalStorageService - Data Integrity', () {
    test('should handle concurrent operations', () async {
      // Arrange
      final animeEntries = List.generate(
        50,
        (i) => _createTestEntry(id: i, mediaId: 1000 + i),
      );
      final mangaEntries = List.generate(
        50,
        (i) => _createTestEntry(id: i + 50, mediaId: 2000 + i),
      );

      // Act - Run multiple operations concurrently
      await Future.wait([
        localStorageService.saveAnimeList(animeEntries),
        localStorageService.saveMangaList(mangaEntries),
      ]);

      final animeList = await localStorageService.getAnimeList();
      final mangaList = await localStorageService.getMangaList();

      // Assert
      expect(animeList.length, equals(50));
      expect(mangaList.length, equals(50));
    });

    test('should persist data across service instances', () async {
      // Arrange
      final entry = _createTestEntry(id: 1, mediaId: 101);
      await localStorageService.saveAnimeList([entry]);

      // Act - Create new service instance
      final newService = LocalStorageService();
      final retrieved = await newService.getAnimeList();

      // Assert
      expect(retrieved.length, equals(1));
      expect(retrieved[0].id, equals(1));
    });
  });
}

// Helper function
MediaListEntry _createTestEntry({
  required int id,
  required int mediaId,
  int progress = 0,
}) {
  return MediaListEntry(
    id: id,
    mediaId: mediaId,
    status: 'CURRENT',
    progress: progress,
    score: 0.0,
    repeat: 0,
    notes: '',
    startedAt: null,
    completedAt: null,
    updatedAt: DateTime.now(),
    media: null,
  );
}
