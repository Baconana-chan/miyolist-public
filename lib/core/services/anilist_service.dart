import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../constants/app_constants.dart';
import '../utils/rate_limiter.dart';
import '../models/media_details.dart';
import '../models/character_details.dart';
import '../models/staff_details.dart';
import '../models/studio_details.dart';
import 'auth_service.dart';
import 'activity_tracking_service.dart';
import '../models/activity_entry.dart';

class AniListService {
  final AuthService _authService;
  final RateLimiter _rateLimiter;
  final ActivityTrackingService _activityTracker = ActivityTrackingService();
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

  // Публичный доступ к GraphQL client для социальных функций
  GraphQLClient get client {
    if (_client == null) {
      throw Exception('AniList client not initialized. Call _ensureInitialized() first.');
    }
    return _client!;
  }

  /// Public method to ensure the client is initialized
  /// Can be called externally when needed
  Future<void> ensureInitialized() async {
    await _ensureInitialized();
  }

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
    
    final httpLink = HttpLink(
      AppConstants.anilistGraphQLUrl,
      defaultHeaders: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
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
  }

  /// Fetch ALL media lists (anime + manga) in a single optimized query
  Future<Map<String, List<dynamic>>> fetchAllMediaLists(int userId) async {
    try {
      await _ensureInitialized();
      
      const query = r'''
      query($userId: Int) {
        anime: MediaListCollection(userId: $userId, type: ANIME) {
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
        manga: MediaListCollection(userId: $userId, type: MANGA) {
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

      print('📡 Sending optimized GraphQL query to fetch all media lists...');
      
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(query),
            variables: {
              'userId': userId,
            },
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error fetching media lists: ${result.exception}');
        return {'anime': [], 'manga': []};
      }

      if (result.data == null) {
        print('⚠️ No data returned from AniList');
        return {'anime': [], 'manga': []};
      }

      // Parse anime list
      final animeEntries = <dynamic>[];
      final animeCollection = result.data?['anime'];
      if (animeCollection != null) {
        final animeLists = animeCollection['lists'];
        if (animeLists is List) {
          for (var list in animeLists) {
            final entries = list['entries'];
            if (entries != null && entries is List) {
              animeEntries.addAll(entries);
            }
          }
        }
      }

      // Parse manga list
      final mangaEntries = <dynamic>[];
      final mangaCollection = result.data?['manga'];
      if (mangaCollection != null) {
        final mangaLists = mangaCollection['lists'];
        if (mangaLists is List) {
          for (var list in mangaLists) {
            final entries = list['entries'];
            if (entries != null && entries is List) {
              mangaEntries.addAll(entries);
            }
          }
        }
      }

      print('✅ All media lists fetched: ${animeEntries.length} anime + ${mangaEntries.length} manga = ${animeEntries.length + mangaEntries.length} total entries');
      
      return {
        'anime': animeEntries,
        'manga': mangaEntries,
      };
    } catch (e, stackTrace) {
      print('❌ Error in fetchAllMediaLists: $e');
      print('📋 Stack trace: $stackTrace');
      return {'anime': [], 'manga': []};
    }
  }

  /// Update media list entry
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
      
      // Get current entry for activity logging
      Map<String, dynamic>? oldEntry;
      if (entryId != null || mediaId != null) {
        oldEntry = await getMediaListEntry(mediaId ?? 0);
      }
      
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
          media {
            id
            title {
              romaji
              english
            }
            type
          }
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
      final updatedEntry = result.data?['SaveMediaListEntry'];
      
      // Log activity
      if (updatedEntry != null) {
        final media = updatedEntry['media'];
        final mediaTitle = media?['title']?['english'] ?? 
                          media?['title']?['romaji'] ?? 
                          'Unknown';
        final mediaType = media?['type'];
        final actualMediaId = media?['id'] ?? mediaId;
        
        // Determine activity type and details
        if (oldEntry == null && status != null) {
          // New entry added
          await _activityTracker.logActivity(
            activityType: ActivityEntry.typeAdded,
            mediaId: actualMediaId!,
            mediaTitle: mediaTitle,
            mediaType: mediaType,
            details: {'status': status},
          );
        } else if (progress != null && oldEntry?['progress'] != progress) {
          // Progress updated
          await _activityTracker.logActivity(
            activityType: ActivityEntry.typeProgress,
            mediaId: actualMediaId!,
            mediaTitle: mediaTitle,
            mediaType: mediaType,
            details: {
              'oldProgress': oldEntry?['progress'] ?? 0,
              'newProgress': progress,
            },
          );
        } else if (status != null && oldEntry?['status'] != status) {
          // Status changed
          await _activityTracker.logActivity(
            activityType: ActivityEntry.typeStatus,
            mediaId: actualMediaId!,
            mediaTitle: mediaTitle,
            mediaType: mediaType,
            details: {
              'oldStatus': oldEntry?['status'] ?? 'None',
              'newStatus': status,
            },
          );
        } else if (score != null && oldEntry?['score'] != score) {
          // Score updated
          await _activityTracker.logActivity(
            activityType: ActivityEntry.typeScore,
            mediaId: actualMediaId!,
            mediaTitle: mediaTitle,
            mediaType: mediaType,
            details: {
              'oldScore': oldEntry?['score'] ?? 0,
              'newScore': score,
            },
          );
        } else if (notes != null && oldEntry?['notes'] != notes) {
          // Notes updated
          await _activityTracker.logActivity(
            activityType: ActivityEntry.typeNotes,
            mediaId: actualMediaId!,
            mediaTitle: mediaTitle,
            mediaType: mediaType,
          );
        }
      }
      
      return updatedEntry;
    } catch (e, stackTrace) {
      print('❌ Error in updateMediaListEntry: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Получить запись пользователя для конкретного медиа
  Future<Map<String, dynamic>?> getMediaListEntry(int mediaId) async {
    try {
      await _ensureInitialized();

      const query = r'''
      query($mediaId: Int) {
        Media(id: $mediaId) {
          mediaListEntry {
            id
            status
            progress
            progressVolumes
            score
            notes
            customLists
          }
        }
      }
      ''';

      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(query),
            variables: {'mediaId': mediaId},
            fetchPolicy: FetchPolicy.noCache, // Всегда получаем свежие данные
          ),
        );
      });

      if (result.hasException) {
        print('❌ Error getting media list entry: ${result.exception}');
        return null;
      }

      return result.data?['Media']?['mediaListEntry'];
    } catch (e) {
      print('❌ Error in getMediaListEntry: $e');
      return null;
    }
  }

  /// Быстрое увеличение прогресса на 1 эпизод
  Future<bool> incrementEpisodeProgress(int mediaId) async {
    try {
      // Получаем текущую запись пользователя
      final currentEntry = await getMediaListEntry(mediaId);
      
      if (currentEntry == null) {
        print('⚠️ No media list entry found, creating new one');
        // Создаем новую запись со статусом CURRENT и прогрессом 1
        final result = await updateMediaListEntry(
          mediaId: mediaId,
          status: 'CURRENT',
          progress: 1,
        );
        return result != null;
      }

      final currentProgress = currentEntry['progress'] as int? ?? 0;
      final newProgress = currentProgress + 1;

      // Обновляем прогресс
      final result = await updateMediaListEntry(
        entryId: currentEntry['id'] as int,
        progress: newProgress,
      );

      if (result != null) {
        print('✅ Episode progress incremented to $newProgress');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error in incrementEpisodeProgress: $e');
      return false;
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
            isAdult
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

  /// Import activity history from AniList
  /// Fetches user's list updates for the past [days] and logs them to local activity tracker
  Future<int> importActivityHistory({int days = 30}) async {
    try {
      await _ensureInitialized();
      
      print('📥 Importing activity history from AniList (last $days days)...');
      
      // Get user ID
      final userData = await fetchCurrentUser();
      if (userData == null) {
        print('❌ Could not fetch user data');
        return 0;
      }
      
      print('📋 User data received: ${userData.keys}');
      final userId = userData['id'];
      if (userId == null) {
        print('❌ User ID not found in data: $userData');
        return 0;
      }
      
      print('✅ User ID: $userId');
      
      // Calculate timestamp for filtering (X days ago)
      final sinceTimestamp = DateTime.now()
          .subtract(Duration(days: days))
          .millisecondsSinceEpoch ~/ 1000;
      
      // Query for list activity
      const query = r'''
        query($userId: Int, $page: Int, $perPage: Int, $createdAt_greater: Int) {
          Page(page: $page, perPage: $perPage) {
            activities(userId: $userId, type: MEDIA_LIST, createdAt_greater: $createdAt_greater, sort: ID_DESC) {
              ... on ListActivity {
                id
                createdAt
                status
                progress
                media {
                  id
                  title {
                    romaji
                    english
                  }
                  type
                  format
                }
              }
            }
            pageInfo {
              hasNextPage
              currentPage
            }
          }
        }
      ''';
      
      int importedCount = 0;
      int currentPage = 1;
      bool hasNextPage = true;
      
      while (hasNextPage && currentPage <= 5) { // Limit to 5 pages (500 activities max)
        print('📄 Fetching page $currentPage...');
        
        final result = await _rateLimiter.execute(() async {
          return await _client!.query(
            QueryOptions(
              document: gql(query),
              variables: {
                'userId': userId,
                'page': currentPage,
                'perPage': 100,
                'createdAt_greater': sinceTimestamp,
              },
            ),
          );
        });
        
        if (result.hasException) {
          print('⚠️ Error fetching page $currentPage: ${result.exception}');
          break;
        }
        
        final activities = result.data?['Page']?['activities'] as List<dynamic>?;
        if (activities == null || activities.isEmpty) {
          print('📭 No more activities found');
          break;
        }
        
        // Process activities
        for (final activity in activities) {
          try {
            final mediaId = activity['media']?['id'];
            final mediaTitle = activity['media']?['title']?['romaji'] ?? 
                              activity['media']?['title']?['english'] ?? 
                              'Unknown';
            final mediaType = activity['media']?['type'] ?? 'ANIME';
            final status = activity['status'];
            final progress = activity['progress'];
            final createdAt = activity['createdAt'];
            
            if (mediaId == null || createdAt == null) continue;
            
            // Determine activity type based on status and progress
            String activityType = 'list_update';
            Map<String, dynamic>? activityDetails;
            
            if (status != null) {
              activityType = 'status_change';
              activityDetails = {'status': status};
            } else if (progress != null) {
              activityType = 'progress_update';
              activityDetails = {'progress': progress};
            }
            
            // Create activity entry with original timestamp
            final timestamp = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
            
            // Create entry directly and add to box
            final entry = ActivityEntry(
              id: createdAt * 1000, // Use AniList timestamp as unique ID
              timestamp: timestamp,
              activityType: activityType,
              mediaId: mediaId,
              mediaTitle: mediaTitle,
              mediaType: mediaType,
              details: activityDetails,
            );
            
            // Add to activity tracker's box
            await _activityTracker.init();
            final box = _activityTracker.getBox();
            if (box != null) {
              await box.add(entry);
            }
            
            importedCount++;
          } catch (e) {
            print('⚠️ Error processing activity: $e');
          }
        }
        
        // Check for next page
        final pageInfo = result.data?['Page']?['pageInfo'];
        hasNextPage = pageInfo?['hasNextPage'] ?? false;
        currentPage++;
        
        print('✅ Imported ${activities.length} activities from page ${currentPage - 1}');
      }
      
      print('✅ Activity import complete: $importedCount activities imported');
      return importedCount;
      
    } catch (e) {
      print('❌ Error importing activity history: $e');
      return 0;
    }
  }

  /// Fetch extended media statistics (studios, staff, voice actors) for user's list
  /// This is optimized for statistics page - only fetches necessary fields
  Future<Map<String, dynamic>> fetchMediaStatisticsDetails(int userId) async {
    try {
      await _ensureInitialized();
      
      print('📊 Fetching extended statistics data (studios, staff, VA)...');
      
      const query = r'''
        query($userId: Int) {
          MediaListCollection(userId: $userId, type: ANIME) {
            lists {
              entries {
                mediaId
                media {
                  id
                  studios(isMain: true) {
                    nodes {
                      id
                      name
                    }
                  }
                  characters(perPage: 10, sort: ROLE) {
                    edges {
                      role
                      node {
                        id
                        name {
                          full
                        }
                        image {
                          large
                        }
                      }
                      voiceActors(language: JAPANESE, sort: FAVOURITES_DESC) {
                        id
                        name {
                          full
                        }
                        image {
                          large
                        }
                      }
                    }
                  }
                  staff(perPage: 10, sort: RELEVANCE) {
                    edges {
                      role
                      node {
                        id
                        name {
                          full
                        }
                        image {
                          large
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';
      
      // Add timeout to prevent indefinite waiting
      final result = await _rateLimiter.execute(() async {
        return await _client!.query(
          QueryOptions(
            document: gql(query),
            variables: {'userId': userId},
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('GraphQL request timed out after 30 seconds');
        },
      );
      
      if (result.hasException) {
        print('❌ Error fetching statistics details: ${result.exception}');
        return {};
      }
      
      if (result.data == null) {
        print('⚠️ No data returned');
        return {};
      }
      
      // Parse data
      final collection = result.data?['MediaListCollection'];
      if (collection == null) {
        return {};
      }
      
      final studios = <String, int>{};
      final voiceActors = <String, Map<String, dynamic>>{};
      final staff = <String, Map<String, dynamic>>{};
      
      final lists = collection['lists'] as List<dynamic>?;
      if (lists != null) {
        for (final list in lists) {
          final entries = list['entries'] as List<dynamic>?;
          if (entries != null) {
            for (final entry in entries) {
              final media = entry['media'];
              if (media == null) continue;
              
              final mediaId = media['id'];
              
              // Process studios
              final studiosData = media['studios']?['nodes'] as List<dynamic>?;
              if (studiosData != null) {
                for (final studio in studiosData) {
                  final name = studio['name'] as String?;
                  if (name != null) {
                    studios[name] = (studios[name] ?? 0) + 1;
                  }
                }
              }
              
              // Process voice actors
              final characters = media['characters']?['edges'] as List<dynamic>?;
              if (characters != null) {
                for (final charEdge in characters) {
                  final role = charEdge['role'] as String?;
                  final character = charEdge['node'];
                  final vas = charEdge['voiceActors'] as List<dynamic>?;
                  
                  if (vas != null && character != null) {
                    for (final va in vas) {
                      final vaId = va['id'].toString();
                      final vaName = va['name']?['full'] as String?;
                      final vaImage = va['image']?['large'] as String?;
                      
                      if (vaName != null) {
                        if (!voiceActors.containsKey(vaId)) {
                          voiceActors[vaId] = {
                            'id': va['id'],
                            'name': vaName,
                            'image': vaImage,
                            'animeCount': 0,
                            'characters': <Map<String, dynamic>>[],
                          };
                        }
                        
                        voiceActors[vaId]!['animeCount'] = (voiceActors[vaId]!['animeCount'] as int) + 1;
                        (voiceActors[vaId]!['characters'] as List).add({
                          'id': character['id'],
                          'name': character['name']?['full'],
                          'image': character['image']?['large'],
                          'role': role,
                          'mediaId': mediaId,
                        });
                      }
                    }
                  }
                }
              }
              
              // Process staff
              final staffData = media['staff']?['edges'] as List<dynamic>?;
              if (staffData != null) {
                for (final staffEdge in staffData) {
                  final role = staffEdge['role'] as String?;
                  final staffNode = staffEdge['node'];
                  
                  if (staffNode != null) {
                    final staffId = staffNode['id'].toString();
                    final staffName = staffNode['name']?['full'] as String?;
                    final staffImage = staffNode['image']?['large'] as String?;
                    
                    if (staffName != null) {
                      if (!staff.containsKey(staffId)) {
                        staff[staffId] = {
                          'id': staffNode['id'],
                          'name': staffName,
                          'image': staffImage,
                          'animeCount': 0,
                          'roles': <String, int>{},
                          'anime': <Map<String, dynamic>>[],
                        };
                      }
                      
                      staff[staffId]!['animeCount'] = (staff[staffId]!['animeCount'] as int) + 1;
                      
                      if (role != null) {
                        final roles = staff[staffId]!['roles'] as Map<String, int>;
                        roles[role] = (roles[role] ?? 0) + 1;
                      }
                      
                      (staff[staffId]!['anime'] as List).add({
                        'mediaId': mediaId,
                        'role': role,
                      });
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      print('✅ Statistics details fetched: ${studios.length} studios, ${voiceActors.length} VAs, ${staff.length} staff');
      
      return {
        'studios': studios,
        'voiceActors': voiceActors.values.toList(),
        'staff': staff.values.toList(),
      };
      
    } catch (e, stackTrace) {
      print('❌ Error in fetchMediaStatisticsDetails: $e');
      print('📋 Stack trace: $stackTrace');
      return {};
    }
  }
}
