import 'package:graphql_flutter/graphql_flutter.dart';
import '../constants/app_constants.dart';
import '../utils/rate_limiter.dart';
import '../models/media_details.dart';
import '../models/character_details.dart';
import '../models/staff_details.dart';
import '../models/studio_details.dart';
import 'auth_service.dart';

class AniListService {
  final AuthService _authService;
  final RateLimiter _rateLimiter;
  GraphQLClient? _client;
  bool _isInitialized = false;

  /// Constructor with optional dependency injection for testing
  /// 
  /// [authService] - Required authentication service
  /// [client] - Optional GraphQL client (for testing)
  /// [rateLimiter] - Optional rate limiter (for testing)
  AniListService(
    this._authService, {
    GraphQLClient? client,
    RateLimiter? rateLimiter,
  })  : _client = client,
        _rateLimiter = rateLimiter ?? RateLimiter(),
        _isInitialized = client != null;

  // Публичный доступ к AuthService для получения токена
  AuthService get authService => _authService;

  /// Initialize GraphQL client with access token
  Future<void> _ensureInitialized() async {
    if (_isInitialized && _client != null) {
      return;
    }
    
    print('🔧 Initializing AniList GraphQL client...');
    
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      print('❌ No access token found');
      throw Exception('No access token available');
    }
    
    print('✅ Access token found');
    
    final httpLink = HttpLink(AppConstants.anilistGraphQLUrl);
    
    final authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final link = authLink.concat(httpLink);

    _client = GraphQLClient(
      cache: GraphQLCache(),
      link: link,
    );
    
    _isInitialized = true;
    print('✅ AniList GraphQL client initialized');
  }

  /// Fetch authenticated user data
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    try {
      print('🔧 Ensuring AniList client is initialized...');
      await _ensureInitialized();
      
      print('📡 Sending GraphQL query to fetch user...');
      
      const query = r'''
        query {
          Viewer {
            id
            name
            avatar {
              large
            }
            bannerImage
            about
            createdAt
            updatedAt
            options {
              displayAdultContent
            }
          }
        }
      ''';

      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(document: gql(query)),
        );
      });

      if (result.hasException) {
        print('❌ GraphQL Error fetching user: ${result.exception}');
        return null;
      }

      print('✅ GraphQL query successful');
      return result.data?['Viewer'] as Map<String, dynamic>?;
    } catch (e, stackTrace) {
      print('❌ Exception in fetchCurrentUser: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch user's anime list
  Future<List<dynamic>?> fetchAnimeList(int userId) async {
    try {
      await _ensureInitialized();
      
      const query = r'''
      query($userId: Int, $type: MediaType) {
        MediaListCollection(userId: $userId, type: $type) {
          lists {
            entries {
              id
              mediaId
              status
              score
              progress
              repeat
              notes
              customLists
              startedAt {
                year
                month
                day
              }
              completedAt {
                year
                month
                day
              }
              updatedAt
              media {
                id
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
                bannerImage
                episodes
                chapters
                volumes
                status
                format
                season
                seasonYear
                averageScore
                description
                isAdult
                genres
              }
            }
          }
        }
      }
    ''';

      print('📡 Sending GraphQL query to fetch anime list...');
      
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(query),
            variables: {
              'userId': userId,
              'type': 'ANIME',
            },
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error fetching anime list: ${result.exception}');
        return null;
      }

      // Check if data exists
      if (result.data == null) {
        print('⚠️ No data returned from AniList');
        return [];
      }

      final mediaListCollection = result.data?['MediaListCollection'];
      if (mediaListCollection == null) {
        print('⚠️ MediaListCollection is null');
        return [];
      }

      final lists = mediaListCollection['lists'];
      if (lists == null) {
        print('⚠️ No anime lists found');
        return [];
      }

      if (lists is! List) {
        print('❌ lists is not a List, it is: ${lists.runtimeType}');
        return [];
      }

      final allEntries = <dynamic>[];
      for (var list in lists) {
        final entries = list['entries'];
        if (entries != null && entries is List) {
          allEntries.addAll(entries);
        }
      }

      print('✅ Anime list fetched: ${allEntries.length} entries');
      return allEntries;
    } catch (e, stackTrace) {
      print('❌ Error in fetchAnimeList: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch user's manga list
  Future<List<dynamic>?> fetchMangaList(int userId) async {
    try {
      await _ensureInitialized();
      
      const query = r'''
      query($userId: Int, $type: MediaType) {
        MediaListCollection(userId: $userId, type: $type) {
          lists {
            entries {
              id
              mediaId
              status
              score
              progress
              progressVolumes
              repeat
              notes
              customLists
              startedAt {
                year
                month
                day
              }
              completedAt {
                year
                month
                day
              }
              updatedAt
              media {
                id
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
                bannerImage
                chapters
                volumes
                status
                format
                averageScore
                description
                isAdult
                genres
              }
            }
          }
        }
      }
    ''';

      print('📡 Sending GraphQL query to fetch manga list...');
      
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(query),
            variables: {
              'userId': userId,
              'type': 'MANGA',
            },
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error fetching manga list: ${result.exception}');
        return null;
      }

      // Check if data exists
      if (result.data == null) {
        print('⚠️ No data returned from AniList');
        return [];
      }

      final mediaListCollection = result.data?['MediaListCollection'];
      if (mediaListCollection == null) {
        print('⚠️ MediaListCollection is null');
        return [];
      }

      final lists = mediaListCollection['lists'];
      if (lists == null) {
        print('⚠️ No manga lists found');
        return [];
      }

      if (lists is! List) {
        print('❌ lists is not a List, it is: ${lists.runtimeType}');
        return [];
      }

      final allEntries = <dynamic>[];
      for (var list in lists) {
        final entries = list['entries'];
        if (entries != null && entries is List) {
          allEntries.addAll(entries);
        }
      }

      print('✅ Manga list fetched: ${allEntries.length} entries');
      return allEntries;
    } catch (e, stackTrace) {
      print('❌ Error in fetchMangaList: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }  /// Update media list entry
  Future<Map<String, dynamic>?> updateMediaListEntry({
    int? entryId, // Nullable for new entries
    int? mediaId, // Required for new entries
    String? status,
    double? score,
    int? progress,
    int? progressVolumes,
    String? notes,
    List<String>? customLists,
  }) async {
    try {
      await _ensureInitialized();
      
      const mutation = r'''
      mutation(
        $entryId: Int,
        $mediaId: Int,
        $status: MediaListStatus,
        $score: Float,
        $progress: Int,
        $progressVolumes: Int,
        $notes: String,
        $customLists: [String]
      ) {
        SaveMediaListEntry(
          id: $entryId,
          mediaId: $mediaId,
          status: $status,
          score: $score,
          progress: $progress,
          progressVolumes: $progressVolumes,
          notes: $notes,
          customLists: $customLists
        ) {
          id
          status
          score
          progress
          progressVolumes
          notes
          customLists
          updatedAt
        }
      }
    ''';

      print('📡 Updating media list entry...');
      
      final result = await _rateLimiter.execute(() async {
        return await _client!.mutate(
          MutationOptions(
            document: gql(mutation),
            variables: {
              if (entryId != null) 'entryId': entryId,
              if (mediaId != null) 'mediaId': mediaId,
              if (status != null) 'status': status,
              if (score != null) 'score': score,
              if (progress != null) 'progress': progress,
              if (progressVolumes != null) 'progressVolumes': progressVolumes,
              if (notes != null) 'notes': notes,
              if (customLists != null) 'customLists': customLists,
            },
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error updating entry: ${result.exception}');
        return null;
      }

      print('✅ Media list entry updated');
      return result.data?['SaveMediaListEntry'];
    } catch (e, stackTrace) {
      print('❌ Error in updateMediaListEntry: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch user favorites
  Future<Map<String, dynamic>?> fetchUserFavorites(int userId) async {
    try {
      await _ensureInitialized();
      
      const query = r'''
      query($userId: Int) {
        User(id: $userId) {
          favourites {
            anime {
              nodes {
                id
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
              }
            }
            manga {
              nodes {
                id
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
              }
            }
            characters {
              nodes {
                id
                name {
                  full
                }
                image {
                  large
                }
              }
            }
            staff {
              nodes {
                id
                name {
                  full
                }
                image {
                  large
                }
              }
            }
            studios {
              nodes {
                id
                name
                isAnimationStudio
              }
              edges {
                isMain
                node {
                  id
                }
              }
            }
          }
        }
      }
    ''';

      print('📡 Fetching user favorites...');
      
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(query),
            variables: {'userId': userId},
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error fetching favorites: ${result.exception}');
        return null;
      }

      print('✅ User favorites fetched');
      return result.data?['User']?['favourites'];
    } catch (e, stackTrace) {
      print('❌ Error in fetchUserFavorites: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Search for media (anime/manga) by query
  Future<List<MediaDetails>> searchMedia(String query, String? type) async {
    await _ensureInitialized();

    const searchQuery = r'''
      query ($search: String, $type: MediaType) {
        Page(page: 1, perPage: 20) {
          media(search: $search, type: $type, sort: SEARCH_MATCH) {
            id
            type
            title {
              romaji
              english
              native
            }
            coverImage {
              extraLarge
              large
            }
            bannerImage
            episodes
            chapters
            volumes
            status
            format
            genres
            averageScore
            popularity
            season
            seasonYear
            source
            studios {
              nodes {
                id
                name
                isAnimationStudio
              }
              edges {
                isMain
                node {
                  id
                }
              }
            }
            startDate {
              year
              month
              day
            }
            endDate {
              year
              month
              day
            }
            trailer {
              id
            }
            synonyms
            duration
            description(asHtml: false)
          }
        }
      }
    ''';

    try {
      print('🔍 Searching media: "$query" (type: ${type ?? 'ALL'})');
      
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(searchQuery),
            variables: {
              'search': query,
              if (type != null) 'type': type,
            },
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error searching media: ${result.exception}');
        return [];
      }

      final mediaList = result.data?['Page']?['media'] as List<dynamic>?;
      if (mediaList == null || mediaList.isEmpty) {
        print('ℹ️ No results found');
        return [];
      }

      print('✅ Found ${mediaList.length} results');
      return mediaList
          .map((json) => MediaDetails.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('❌ Error in searchMedia: $e');
      print('📋 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get detailed information about a specific media
  Future<MediaDetails?> getMediaDetails(int mediaId) async {
    await _ensureInitialized();

    const mediaQuery = r'''
      query ($id: Int) {
        Media(id: $id) {
          id
          type
          title {
            romaji
            english
            native
          }
          description(asHtml: false)
          coverImage {
            extraLarge
            large
          }
          bannerImage
          episodes
          chapters
          volumes
          status
          format
          genres
          averageScore
          popularity
          favourites
          season
          seasonYear
          source
          studios {
            nodes {
              id
              name
              isAnimationStudio
            }
            edges {
              isMain
              node {
                id
              }
            }
          }
          startDate {
            year
            month
            day
          }
          endDate {
            year
            month
            day
          }
          trailer {
            id
            site
          }
          synonyms
          duration
          tags {
            id
            name
            description
            rank
            isMediaSpoiler
          }
          externalLinks {
            id
            url
            site
            type
            language
          }
          streamingEpisodes {
            title
            thumbnail
            url
            site
          }
          characters(sort: ROLE, perPage: 25) {
            edges {
              node {
                id
                name {
                  full
                  native
                }
                image {
                  large
                }
              }
              role
              voiceActors(language: JAPANESE, sort: RELEVANCE) {
                id
                name {
                  full
                  native
                }
                image {
                  large
                }
                languageV2
              }
            }
          }
          staff(sort: RELEVANCE, perPage: 25) {
            edges {
              node {
                id
                name {
                  full
                  native
                }
                image {
                  large
                }
              }
              role
            }
          }
          relations {
            edges {
              node {
                id
                type
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
                format
                status
              }
              relationType
            }
          }
          recommendations(sort: RATING_DESC, perPage: 10) {
            edges {
              node {
                id
                rating
                mediaRecommendation {
                  id
                  type
                  title {
                    romaji
                    english
                  }
                  coverImage {
                    large
                  }
                  format
                  averageScore
                }
              }
            }
          }
          stats {
            statusDistribution {
              status
              amount
            }
            scoreDistribution {
              score
              amount
            }
          }
        }
      }
    ''';

    try {
      print('🌐 Fetching media details (id: $mediaId)');
      
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(mediaQuery),
            variables: {'id': mediaId},
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error fetching media details: ${result.exception}');
        return null;
      }

      final mediaData = result.data?['Media'];
      if (mediaData == null) {
        print('ℹ️ Media not found');
        return null;
      }

      print('✅ Media details fetched');
      return MediaDetails.fromJson(mediaData as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ Error in getMediaDetails: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch character details
  Future<CharacterDetails?> getCharacterDetails(int characterId) async {
    try {
      await _ensureInitialized();
      await _rateLimiter.waitForSlot();

      print('🌐 Fetching character details (id: $characterId)');

      const query = r'''
        query ($id: Int!) {
          Character(id: $id) {
            id
            name {
              full
              native
              alternative
            }
            image {
              large
            }
            description
            gender
            age
            dateOfBirth {
              year
              month
              day
            }
            favourites
            media(page: 1, perPage: 50, sort: POPULARITY_DESC) {
              edges {
                node {
                  id
                  title {
                    romaji
                    english
                  }
                  coverImage {
                    large
                  }
                  type
                  format
                }
                characterRole
              }
            }
          }
        }
      ''';

      final result = await _client!.query(QueryOptions(
        document: gql(query),
        variables: {'id': characterId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      _rateLimiter.recordRequest();

      if (result.hasException) {
        print('❌ Error fetching character details: ${result.exception}');
        return null;
      }

      final characterData = result.data?['Character'];
      if (characterData == null) {
        print('ℹ️ Character not found');
        return null;
      }

      print('✅ Character details fetched');
      return CharacterDetails.fromJson(characterData as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ Error in getCharacterDetails: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch staff details
  Future<StaffDetails?> getStaffDetails(int staffId) async {
    try {
      await _ensureInitialized();
      await _rateLimiter.waitForSlot();

      print('🌐 Fetching staff details (id: $staffId)');

      const query = r'''
        query ($id: Int!) {
          Staff(id: $id) {
            id
            name {
              full
              native
              alternative
            }
            image {
              large
            }
            description
            gender
            age
            dateOfBirth {
              year
              month
              day
            }
            dateOfDeath {
              year
              month
              day
            }
            homeTown
            yearsActive
            favourites
            siteUrl
            staffMedia(page: 1, perPage: 50, sort: POPULARITY_DESC) {
              edges {
                node {
                  id
                  title {
                    romaji
                    english
                  }
                  coverImage {
                    large
                  }
                  type
                  format
                }
                staffRole
              }
            }
            characters(page: 1, perPage: 25, sort: FAVOURITES_DESC) {
              edges {
                node {
                  id
                  name {
                    full
                  }
                  image {
                    large
                  }
                }
                role
                media {
                  id
                  title {
                    romaji
                  }
                }
              }
            }
          }
        }
      ''';

      final result = await _client!.query(QueryOptions(
        document: gql(query),
        variables: {'id': staffId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      _rateLimiter.recordRequest();

      if (result.hasException) {
        print('❌ Error fetching staff details: ${result.exception}');
        return null;
      }

      final staffData = result.data?['Staff'];
      if (staffData == null) {
        print('ℹ️ Staff not found');
        return null;
      }

      print('✅ Staff details fetched');
      return StaffDetails.fromJson(staffData as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ Error in getStaffDetails: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch studio details
  Future<StudioDetails?> getStudioDetails(int studioId) async {
    try {
      await _ensureInitialized();
      await _rateLimiter.waitForSlot();

      print('🌐 Fetching studio details (id: $studioId)');

      const query = r'''
        query ($id: Int!) {
          Studio(id: $id) {
            id
            name
            isAnimationStudio
            favourites
            siteUrl
            media(page: 1, perPage: 50, sort: POPULARITY_DESC) {
              edges {
                node {
                  id
                  title {
                    romaji
                    english
                  }
                  coverImage {
                    large
                  }
                  type
                  format
                  seasonYear
                  season
                  averageScore
                }
                isMainStudio
              }
            }
          }
        }
      ''';

      final result = await _client!.query(QueryOptions(
        document: gql(query),
        variables: {'id': studioId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      _rateLimiter.recordRequest();

      if (result.hasException) {
        print('❌ Error fetching studio details: ${result.exception}');
        return null;
      }

      final studioData = result.data?['Studio'];
      if (studioData == null) {
        print('ℹ️ Studio not found');
        return null;
      }

      print('✅ Studio details fetched');
      return StudioDetails.fromJson(studioData as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('❌ Error in getStudioDetails: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Глобальный поиск (медиа, персонажи, стафф, студии)
  Future<List<Map<String, dynamic>>> globalSearch({
    required String query,
    String? type, // ANIME, MANGA, CHARACTER, STAFF, STUDIO, или null для всех
  }) async {
    await _ensureInitialized();
    await _rateLimiter.waitForSlot();

    try {
      String searchQuery;
      
      if (type == 'CHARACTER') {
        searchQuery = '''
          query(\$search: String) {
            Page(perPage: 20) {
              characters(search: \$search, sort: FAVOURITES_DESC) {
                id
                name {
                  full
                  native
                }
                image {
                  large
                }
              }
            }
          }
        ''';
      } else if (type == 'STAFF') {
        searchQuery = '''
          query(\$search: String) {
            Page(perPage: 20) {
              staff(search: \$search, sort: FAVOURITES_DESC) {
                id
                name {
                  full
                  native
                }
                image {
                  large
                }
              }
            }
          }
        ''';
      } else if (type == 'STUDIO') {
        searchQuery = '''
          query(\$search: String) {
            Page(perPage: 20) {
              studios(search: \$search, sort: FAVOURITES_DESC) {
                id
                name
                isAnimationStudio
              }
            }
          }
        ''';
      } else {
        // Поиск медиа (ANIME/MANGA или все)
        searchQuery = '''
          query(\$search: String, \$type: MediaType) {
            Page(perPage: 20) {
              media(search: \$search, type: \$type, sort: POPULARITY_DESC) {
                id
                type
                title {
                  romaji
                  english
                }
                format
                coverImage {
                  large
                }
                averageScore
              }
            }
          }
        ''';
      }

      final variables = <String, dynamic>{'search': query};
      if (type == 'ANIME' || type == 'MANGA') {
        variables['type'] = type;
      }

      final result = await _client!.query(
        QueryOptions(
          document: gql(searchQuery),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      _rateLimiter.recordRequest();

      if (result.hasException) {
        print('Error in globalSearch: ${result.exception}');
        return [];
      }

      final data = result.data?['Page'];
      if (data == null) return [];
      
      if (type == 'CHARACTER') {
        final characters = data['characters'] as List<dynamic>?;
        return characters?.map((c) => {
          'id': c['id'],
          'type': 'CHARACTER',
          'data': c,
        }).toList() ?? [];
      } else if (type == 'STAFF') {
        final staff = data['staff'] as List<dynamic>?;
        return staff?.map((s) => {
          'id': s['id'],
          'type': 'STAFF',
          'data': s,
        }).toList() ?? [];
      } else if (type == 'STUDIO') {
        final studios = data['studios'] as List<dynamic>?;
        return studios?.map((s) => {
          'id': s['id'],
          'type': 'STUDIO',
          'data': s,
        }).toList() ?? [];
      } else {
        final media = data['media'] as List<dynamic>?;
        return media?.map((m) => {
          'id': m['id'],
          'type': m['type'],
          'data': m,
        }).toList() ?? [];
      }
    } catch (e) {
      print('Error in globalSearch: $e');
      return [];
    }
  }
  
  /// Get basic media data by ID (for inline previews)
  Future<Map<String, dynamic>?> getMediaById(int mediaId) async {
    await _ensureInitialized();

    const query = r'''
      query ($id: Int) {
        Media(id: $id) {
          id
          type
          format
          status
          title {
            romaji
            english
            native
          }
          coverImage {
            large
            medium
          }
          averageScore
          startDate {
            year
          }
        }
      }
    ''';

    try {
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(query),
            variables: {'id': mediaId},
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error fetching media $mediaId: ${result.exception}');
        return null;
      }

      return result.data?['Media'] as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Exception in getMediaById: $e');
      return null;
    }
  }
  
  /// Get rate limiter statistics
  Map<String, dynamic> getRateLimiterStats() {
    return {
      'currentRequests': _rateLimiter.currentRequestCount,
      'remainingRequests': _rateLimiter.remainingRequests,
      'maxRequestsPerMinute': RateLimiter.maxRequestsPerMinute,
      'waitTimeMs': _rateLimiter.getWaitTimeMs(),
    };
  }

  /// Расширенный поиск с фильтрами и сортировкой
  Future<List<Map<String, dynamic>>> advancedSearch({
    required String query,
    String? type, // ANIME, MANGA, CHARACTER, STAFF, STUDIO
    List<String>? genres,
    int? year,
    String? season, // WINTER, SPRING, SUMMER, FALL
    String? format,
    String? status,
    int? scoreMin,
    int? scoreMax,
    int? episodesMin,
    int? episodesMax,
    int? chaptersMin,
    int? chaptersMax,
    String sortBy = 'POPULARITY_DESC',
  }) async {
    await _ensureInitialized();
    await _rateLimiter.waitForSlot();

    try {
      // Для персонажей, стафа и студий используем старый метод
      if (type == 'CHARACTER' || type == 'STAFF' || type == 'STUDIO') {
        return globalSearch(query: query, type: type);
      }

      // Расширенный поиск медиа с фильтрами
      const searchQuery = '''
        query(
          \$search: String,
          \$type: MediaType,
          \$genre_in: [String],
          \$seasonYear: Int,
          \$season: MediaSeason,
          \$format: MediaFormat,
          \$status: MediaStatus,
          \$averageScore_greater: Int,
          \$averageScore_lesser: Int,
          \$episodes_greater: Int,
          \$episodes_lesser: Int,
          \$chapters_greater: Int,
          \$chapters_lesser: Int,
          \$sort: [MediaSort]
        ) {
          Page(perPage: 50) {
            media(
              search: \$search,
              type: \$type,
              genre_in: \$genre_in,
              seasonYear: \$seasonYear,
              season: \$season,
              format: \$format,
              status: \$status,
              averageScore_greater: \$averageScore_greater,
              averageScore_lesser: \$averageScore_lesser,
              episodes_greater: \$episodes_greater,
              episodes_lesser: \$episodes_lesser,
              chapters_greater: \$chapters_greater,
              chapters_lesser: \$chapters_lesser,
              sort: \$sort
            ) {
              id
              type
              format
              status
              isAdult
              title {
                romaji
                english
                native
              }
              coverImage {
                large
                medium
              }
              averageScore
              popularity
              episodes
              chapters
              genres
              tags {
                name
                isAdult
              }
              season
              seasonYear
              startDate {
                year
                month
                day
              }
            }
          }
        }
      ''';

      final variables = <String, dynamic>{};
      
      // Базовые параметры
      if (query.isNotEmpty) variables['search'] = query;
      if (type != null && type != 'ALL') variables['type'] = type;
      
      // Фильтры
      if (genres != null && genres.isNotEmpty) variables['genre_in'] = genres;
      if (year != null) variables['seasonYear'] = year;
      if (season != null) variables['season'] = season;
      if (format != null) variables['format'] = format;
      if (status != null) variables['status'] = status;
      if (scoreMin != null) variables['averageScore_greater'] = scoreMin;
      if (scoreMax != null) variables['averageScore_lesser'] = scoreMax;
      if (episodesMin != null) variables['episodes_greater'] = episodesMin;
      if (episodesMax != null) variables['episodes_lesser'] = episodesMax;
      if (chaptersMin != null) variables['chapters_greater'] = chaptersMin;
      if (chaptersMax != null) variables['chapters_lesser'] = chaptersMax;
      
      // Сортировка
      variables['sort'] = [sortBy];

      final result = await _client!.query(
        QueryOptions(
          document: gql(searchQuery),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      _rateLimiter.recordRequest();

      if (result.hasException) {
        print('Error in advancedSearch: ${result.exception}');
        return [];
      }

      final data = result.data?['Page'];
      if (data == null) return [];

      final media = data['media'] as List<dynamic>?;
      return media?.map((m) => {
        'id': m['id'],
        'type': m['type'],
        'data': m,
      }).toList() ?? [];
    } catch (e) {
      print('Error in advancedSearch: $e');
      return [];
    }
  }
}
