import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/media_details.dart';
import 'auth_service.dart';

class TrendingService {
  final AuthService _authService;
  GraphQLClient? _client;

  TrendingService(this._authService);

  Future<void> _ensureInitialized() async {
    if (_client != null) return;
    
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    final httpLink = HttpLink('https://graphql.anilist.co');
    final authLink = AuthLink(getToken: () => 'Bearer $token');
    final link = authLink.concat(httpLink);
    
    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
  }

  /// Получить трендовые аниме
  Future<List<MediaDetails>> getTrendingAnime({int count = 5}) async {
    await _ensureInitialized();

    const query = r'''
      query ($page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          media(type: ANIME, sort: TRENDING_DESC) {
            id
            type
            title {
              romaji
              english
            }
            coverImage {
              large
              extraLarge
            }
            format
            status
            episodes
            averageScore
            popularity
            trending
          }
        }
      }
    ''';

    final result = await _client!.query(
      QueryOptions(
        document: gql(query),
        variables: {
          'page': 1,
          'perPage': count,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final mediaList = result.data?['Page']?['media'] as List?;
    if (mediaList == null) return [];

    return mediaList.map((json) => MediaDetails.fromJson(json)).toList();
  }

  /// Получить трендовую мангу
  Future<List<MediaDetails>> getTrendingManga({int count = 5}) async {
    await _ensureInitialized();

    const query = r'''
      query ($page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          media(type: MANGA, sort: TRENDING_DESC) {
            id
            type
            title {
              romaji
              english
            }
            coverImage {
              large
              extraLarge
            }
            format
            status
            chapters
            volumes
            averageScore
            popularity
            trending
          }
        }
      }
    ''';

    final result = await _client!.query(
      QueryOptions(
        document: gql(query),
        variables: {
          'page': 1,
          'perPage': count,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final mediaList = result.data?['Page']?['media'] as List?;
    if (mediaList == null) return [];

    return mediaList.map((json) => MediaDetails.fromJson(json)).toList();
  }

  /// Получить недавно добавленные аниме
  Future<List<MediaDetails>> getNewlyAddedAnime({int count = 5}) async {
    await _ensureInitialized();

    const query = r'''
      query ($page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          media(type: ANIME, sort: ID_DESC) {
            id
            type
            title {
              romaji
              english
            }
            coverImage {
              large
              extraLarge
            }
            format
            status
            episodes
            averageScore
            popularity
            startDate {
              year
              month
              day
            }
          }
        }
      }
    ''';

    final result = await _client!.query(
      QueryOptions(
        document: gql(query),
        variables: {
          'page': 1,
          'perPage': count,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final mediaList = result.data?['Page']?['media'] as List?;
    if (mediaList == null) return [];

    return mediaList.map((json) => MediaDetails.fromJson(json)).toList();
  }

  /// Получить недавно добавленную мангу
  Future<List<MediaDetails>> getNewlyAddedManga({int count = 5}) async {
    await _ensureInitialized();

    const query = r'''
      query ($page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          media(type: MANGA, sort: ID_DESC) {
            id
            type
            title {
              romaji
              english
            }
            coverImage {
              large
              extraLarge
            }
            format
            status
            chapters
            volumes
            averageScore
            popularity
            startDate {
              year
              month
              day
            }
          }
        }
      }
    ''';

    final result = await _client!.query(
      QueryOptions(
        document: gql(query),
        variables: {
          'page': 1,
          'perPage': count,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final mediaList = result.data?['Page']?['media'] as List?;
    if (mediaList == null) return [];

    return mediaList.map((json) => MediaDetails.fromJson(json)).toList();
  }
}
