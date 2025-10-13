import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:miyolist/core/services/media_search_service.dart';
import 'package:miyolist/core/services/local_storage_service.dart';
import 'package:miyolist/core/services/supabase_service.dart';
import 'package:miyolist/core/services/anilist_service.dart';
import 'package:miyolist/core/models/media_details.dart';

// Generate mocks
@GenerateMocks([LocalStorageService, SupabaseService, AniListService])
import 'media_search_service_test.mocks.dart';

void main() {
  late MediaSearchService searchService;
  late MockLocalStorageService mockLocalStorage;
  late MockSupabaseService mockSupabase;
  late MockAniListService mockAniList;

  setUp(() {
    mockLocalStorage = MockLocalStorageService();
    mockSupabase = MockSupabaseService();
    mockAniList = MockAniListService();

    searchService = MediaSearchService(
      localStorage: mockLocalStorage,
      supabase: mockSupabase,
      anilist: mockAniList,
    );
  });

  group('MediaSearchService - Three-Level Search', () {
    test('should return results from local cache first', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(id: 1, titleRomaji: 'Demon Slayer'),
        _createTestMedia(id: 2, titleRomaji: 'Demon King'),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(query: 'Demon');

      // Assert
      expect(results.length, equals(2));
      verify(mockLocalStorage.getAllCachedMedia()).called(1);
      verifyNever(mockSupabase.searchMedia(any, any));
      verifyNever(mockAniList.searchMedia(any, any));
    });

    test('should search in Supabase if local cache is empty', () async {
      // Arrange
      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(<MediaDetails>[]);

      final supabaseResults = [
        _createTestMedia(id: 1, titleRomaji: 'Attack on Titan'),
      ];

      when(mockSupabase.searchMedia(any, any))
          .thenAnswer((_) => Future.value(supabaseResults));

      when(mockLocalStorage.saveMediaDetails(any))
          .thenAnswer((_) => Future.value());

      // Act
      final results = await searchService.searchMedia(query: 'Attack');

      // Assert
      expect(results.length, equals(1));
      verify(mockLocalStorage.getAllCachedMedia()).called(1);
      verify(mockSupabase.searchMedia(any, any)).called(1);
      verifyNever(mockAniList.searchMedia(any, any));
    });

    test('should search in AniList if cache and Supabase are empty', () async {
      // Arrange
      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(<MediaDetails>[]);

      when(mockSupabase.searchMedia(any, any))
          .thenAnswer((_) => Future.value(<MediaDetails>[]));

      final anilistResults = [
        _createTestMedia(id: 1, titleRomaji: 'One Piece'),
      ];

      when(mockAniList.searchMedia(any, any))
          .thenAnswer((_) => Future.value(anilistResults));

      when(mockLocalStorage.saveMediaDetails(any))
          .thenAnswer((_) => Future.value());

      when(mockSupabase.cacheMediaDetails(any))
          .thenAnswer((_) => Future.value());

      // Act
      final results = await searchService.searchMedia(query: 'One Piece');

      // Assert
      expect(results.length, equals(1));
      verify(mockLocalStorage.getAllCachedMedia()).called(1);
      verify(mockSupabase.searchMedia(any, any)).called(1);
      verify(mockAniList.searchMedia(any, any)).called(1);
    });
  });

  group('MediaSearchService - Type Filtering', () {
    test('should filter by anime type', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(id: 1, titleRomaji: 'Naruto', type: 'ANIME'),
        _createTestMedia(id: 2, titleRomaji: 'Naruto', type: 'MANGA'),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(
        query: 'Naruto',
        type: 'ANIME',
      );

      // Assert
      expect(results.length, equals(1));
      expect(results.first.type, equals('ANIME'));
    });

    test('should filter by manga type', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(id: 1, titleRomaji: 'Tokyo Ghoul', type: 'ANIME'),
        _createTestMedia(id: 2, titleRomaji: 'Tokyo Ghoul', type: 'MANGA'),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(
        query: 'Tokyo Ghoul',
        type: 'MANGA',
      );

      // Assert
      expect(results.length, equals(1));
      expect(results.first.type, equals('MANGA'));
    });

    test('should return all types when type is null', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(id: 1, titleRomaji: 'Bleach', type: 'ANIME'),
        _createTestMedia(id: 2, titleRomaji: 'Bleach', type: 'MANGA'),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(query: 'Bleach');

      // Assert
      expect(results.length, equals(2));
    });
  });

  group('MediaSearchService - Title Matching', () {
    test('should match romaji title', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(
          id: 1,
          titleRomaji: 'Shingeki no Kyojin',
          titleEnglish: 'Attack on Titan',
        ),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(query: 'Shingeki');

      // Assert
      expect(results.length, equals(1));
    });

    test('should match english title', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(
          id: 1,
          titleRomaji: 'Kimetsu no Yaiba',
          titleEnglish: 'Demon Slayer',
        ),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(query: 'Demon');

      // Assert
      expect(results.length, equals(1));
    });

    test('should match native title', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(
          id: 1,
          titleRomaji: 'Naruto',
          titleNative: 'ナルト',
        ),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(query: 'ナルト');

      // Assert
      expect(results.length, equals(1));
    });

    test('should perform case-insensitive search', () async {
      // Arrange
      final cachedMedia = [
        _createTestMedia(id: 1, titleRomaji: 'One Punch Man'),
        _createTestMedia(id: 2, titleRomaji: 'One Piece'),
        _createTestMedia(id: 3, titleRomaji: 'Hunter x Hunter'),
      ];

      when(mockLocalStorage.getAllCachedMedia())
          .thenReturn(cachedMedia);

      // Act
      final results = await searchService.searchMedia(query: 'one');

      // Assert
      expect(results.length, equals(2));
    });
  });

  group('MediaSearchService - Media Details', () {
    test('should return cached media details if not expired', () async {
      // Arrange
      final cachedMedia = _createTestMedia(
        id: 1,
        titleRomaji: 'Steins;Gate',
        cacheTimestamp: DateTime.now(),
      );

      when(mockLocalStorage.getMediaDetails(1))
          .thenReturn(cachedMedia);

      // Act
      final result = await searchService.getMediaDetails(1);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(1));
      verify(mockLocalStorage.getMediaDetails(1)).called(1);
      verifyNever(mockAniList.getMediaDetails(any));
    });

    test('should fetch from AniList if cache is expired', () async {
      // Arrange
      final expiredMedia = _createTestMedia(
        id: 1,
        titleRomaji: 'Code Geass',
        cacheTimestamp: DateTime.now().subtract(Duration(days: 8)),
      );

      when(mockLocalStorage.getMediaDetails(1))
          .thenReturn(expiredMedia);

      final freshMedia = _createTestMedia(
        id: 1,
        titleRomaji: 'Code Geass',
        cacheTimestamp: DateTime.now(),
      );

      when(mockAniList.getMediaDetails(1))
          .thenAnswer((_) => Future.value(freshMedia));

      when(mockLocalStorage.saveMediaDetails(any))
          .thenAnswer((_) => Future.value());

      when(mockSupabase.cacheMediaDetails(any))
          .thenAnswer((_) => Future.value());

      // Act
      final result = await searchService.getMediaDetails(1);

      // Assert
      expect(result, isNotNull);
      verify(mockAniList.getMediaDetails(1)).called(1);
      verify(mockLocalStorage.saveMediaDetails(any)).called(1);
    });

    test('should fetch from AniList if not in cache', () async {
      // Arrange
      when(mockLocalStorage.getMediaDetails(1))
          .thenReturn(null);

      final freshMedia = _createTestMedia(
        id: 1,
        titleRomaji: 'Fullmetal Alchemist',
      );

      when(mockAniList.getMediaDetails(1))
          .thenAnswer((_) => Future.value(freshMedia));

      when(mockLocalStorage.saveMediaDetails(any))
          .thenAnswer((_) => Future.value());

      when(mockSupabase.cacheMediaDetails(any))
          .thenAnswer((_) => Future.value());

      // Act
      final result = await searchService.getMediaDetails(1);

      // Assert
      expect(result, isNotNull);
      verify(mockAniList.getMediaDetails(1)).called(1);
    });

    test('should return null if AniList returns null', () async {
      // Arrange
      when(mockLocalStorage.getMediaDetails(999))
          .thenReturn(null);

      when(mockAniList.getMediaDetails(999))
          .thenAnswer((_) => Future.value(null));

      // Act
      final result = await searchService.getMediaDetails(999);

      // Assert
      expect(result, isNull);
    });
  });
}

/// Helper function to create test media
MediaDetails _createTestMedia({
  required int id,
  required String titleRomaji,
  String? titleEnglish,
  String? titleNative,
  String type = 'ANIME',
  DateTime? cacheTimestamp,
}) {
  return MediaDetails(
    id: id,
    titleRomaji: titleRomaji,
    titleEnglish: titleEnglish,
    titleNative: titleNative,
    description: 'Test description',
    coverImage: 'https://test.com/cover.jpg',
    bannerImage: null,
    type: type,
    format: 'TV',
    status: 'FINISHED',
    episodes: 12,
    chapters: null,
    volumes: null,
    averageScore: 85,
    popularity: 10000,
    genres: ['Action', 'Adventure'],
    tags: [],
    relations: [],
    characters: [],
    staff: [],
    studios: [],
    externalLinks: [],
    recommendations: [],
    cachedAt: cacheTimestamp ?? DateTime.now(),
  );
}
