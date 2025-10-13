import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:gql/language.dart';
import 'package:gql/ast.dart';
import 'package:miyolist/core/services/anilist_service.dart';
import 'package:miyolist/core/services/auth_service.dart';
import 'package:miyolist/core/utils/rate_limiter.dart';

// Generate mocks
@GenerateMocks([AuthService, GraphQLClient, RateLimiter])
import 'anilist_service_test.mocks.dart';

// Helper function to create a mock DocumentNode for testing
DocumentNode _createMockDocument() {
  return parseString('query { dummy }');
}

void main() {
  late AniListService anilistService;
  late MockAuthService mockAuthService;
  late MockGraphQLClient mockGraphQLClient;
  late MockRateLimiter mockRateLimiter;

  setUp(() {
    mockAuthService = MockAuthService();
    mockGraphQLClient = MockGraphQLClient();
    mockRateLimiter = MockRateLimiter();

    // Setup rate limiter to execute callbacks immediately
    when(mockRateLimiter.execute(any)).thenAnswer((invocation) {
      final callback = invocation.positionalArguments[0] as Future Function();
      return callback();
    });

    anilistService = AniListService(
      mockAuthService,
      client: mockGraphQLClient,
      rateLimiter: mockRateLimiter,
    );
  });

  group('AniListService - Initialization', () {
    test('should be initialized when client is provided', () {
      // Assert
      expect(anilistService, isNotNull);
      expect(anilistService.authService, equals(mockAuthService));
    });

    test('should handle missing token gracefully', () async {
      // Arrange
      final serviceWithoutClient = AniListService(mockAuthService);
      when(mockAuthService.getAccessToken())
          .thenAnswer((_) => Future.value(null));

      // Act
      final result = await serviceWithoutClient.fetchCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('AniListService - User Data', () {
    test('fetchCurrentUser should return user data on success', () async {
      // Arrange
      final userData = {
        'Viewer': {
          'id': 12345,
          'name': 'TestUser',
          'avatar': {'large': 'https://example.com/avatar.jpg'},
          'bannerImage': 'https://example.com/banner.jpg',
          'about': 'Test bio',
          'createdAt': 1234567890,
          'updatedAt': 1234567890,
          'options': {'displayAdultContent': false},
        }
      };

      final queryResult = QueryResult(
        data: userData,
        source: QueryResultSource.network,
        options: QueryOptions(document: _createMockDocument()),
      );

      when(mockGraphQLClient.query(any))
          .thenAnswer((_) => Future.value(queryResult));

      // Act
      final result = await anilistService.fetchCurrentUser();

      // Assert
      expect(result, isNotNull);
      expect(result?['id'], equals(12345));
      expect(result?['name'], equals('TestUser'));
      verify(mockGraphQLClient.query(any)).called(1);
    });

    test('fetchCurrentUser should return null on GraphQL error', () async {
      // Arrange
      final queryResult = QueryResult(
        source: QueryResultSource.network,
        options: QueryOptions(document: _createMockDocument()),
        exception: OperationException(
          graphqlErrors: [GraphQLError(message: 'Test error')],
        ),
      );

      when(mockGraphQLClient.query(any))
          .thenAnswer((_) => Future.value(queryResult));

      // Act
      final result = await anilistService.fetchCurrentUser();

      // Assert
      expect(result, isNull);
      verify(mockGraphQLClient.query(any)).called(1);
    });

    test('fetchCurrentUser should return null on exception', () async {
      // Arrange
      when(mockGraphQLClient.query(any))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await anilistService.fetchCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('AniListService - Anime List', () {
    test('fetchAnimeList should return anime list on success', () async {
      // Arrange
      final animeListData = {
        'MediaListCollection': {
          'lists': [
            {
              'entries': [
                {
                  'id': 1,
                  'mediaId': 101,
                  'status': 'CURRENT',
                  'progress': 5,
                  'score': 8.5,
                }
              ]
            }
          ]
        }
      };

      final queryResult = QueryResult(
        data: animeListData,
        source: QueryResultSource.network,
        options: QueryOptions(document: _createMockDocument()),
      );

      when(mockGraphQLClient.query(any))
          .thenAnswer((_) => Future.value(queryResult));

      // Act
      final result = await anilistService.fetchAnimeList(12345);

      // Assert
      expect(result, isNotNull);
      expect(result, isList);
      verify(mockGraphQLClient.query(any)).called(1);
    });

    test('fetchAnimeList should return null on error', () async {
      // Arrange
      final queryResult = QueryResult(
        source: QueryResultSource.network,
        options: QueryOptions(document: _createMockDocument()),
        exception: OperationException(
          graphqlErrors: [GraphQLError(message: 'Test error')],
        ),
      );

      when(mockGraphQLClient.query(any))
          .thenAnswer((_) => Future.value(queryResult));

      // Act
      final result = await anilistService.fetchAnimeList(12345);

      // Assert
      expect(result, isNull);
    });
  });

  group('AniListService - Manga List', () {
    test('fetchMangaList should return manga list on success', () async {
      // Arrange
      final mangaListData = {
        'MediaListCollection': {
          'lists': [
            {
              'entries': [
                {
                  'id': 2,
                  'mediaId': 102,
                  'status': 'READING',
                  'progress': 10,
                  'score': 9.0,
                }
              ]
            }
          ]
        }
      };

      final queryResult = QueryResult(
        data: mangaListData,
        source: QueryResultSource.network,
        options: QueryOptions(document: _createMockDocument()),
      );

      when(mockGraphQLClient.query(any))
          .thenAnswer((_) => Future.value(queryResult));

      // Act
      final result = await anilistService.fetchMangaList(12345);

      // Assert
      expect(result, isNotNull);
      expect(result, isList);
      verify(mockGraphQLClient.query(any)).called(1);
    });
  });

  group('AniListService - Rate Limiting', () {
    test('should use rate limiter for API calls', () async {
      // Arrange
      final userData = {
        'Viewer': {'id': 12345, 'name': 'TestUser'}
      };

      final queryResult = QueryResult(
        data: userData,
        source: QueryResultSource.network,
        options: QueryOptions(document: _createMockDocument()),
      );

      when(mockGraphQLClient.query(any))
          .thenAnswer((_) => Future.value(queryResult));

      // Act
      await anilistService.fetchCurrentUser();

      // Assert
      verify(mockRateLimiter.execute(any)).called(1);
    });
  });

  group('AniListService - Error Handling', () {
    test('should handle network timeout gracefully', () async {
      // Arrange
      when(mockGraphQLClient.query(any))
          .thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        throw Exception('Timeout');
      });

      // Act
      final result = await anilistService.fetchCurrentUser();

      // Assert
      expect(result, isNull);
    });

    test('should handle invalid response format', () async {
      // Arrange
      final invalidData = {
        'InvalidKey': 'invalid_value',
      };

      final queryResult = QueryResult(
        data: invalidData,
        source: QueryResultSource.network,
        options: QueryOptions(document: _createMockDocument()),
      );

      when(mockGraphQLClient.query(any))
          .thenAnswer((_) => Future.value(queryResult));

      // Act
      final result = await anilistService.fetchCurrentUser();

      // Assert
      // Должен вернуть null при отсутствии ожидаемого ключа
      expect(result, isNull);
    });
  });
}

/// Примечание:
/// 
/// ✅ **Рефакторинг завершён успешно!**
/// 
/// AniListService теперь поддерживает dependency injection:
/// - GraphQLClient можно внедрить через конструктор
/// - RateLimiter можно внедрить для контроля rate limiting
/// - Легко мокировать для unit tests
/// 
/// **Покрытие тестов**:
/// - ✅ Initialization logic
/// - ✅ User data fetching
/// - ✅ Anime list fetching
/// - ✅ Manga list fetching
/// - ✅ Rate limiting integration
/// - ✅ Error handling (network, GraphQL errors, timeouts)
/// 
/// **Что ещё можно добавить**:
/// - searchMedia tests
/// - getMediaDetails tests
/// - updateMediaListEntry tests (mutations)
/// - Character/Staff/Studio detail tests
/// - Global search tests
/// - Advanced search tests
/// 
/// **Текущее покрытие**: ~40% основных методов AniListService
