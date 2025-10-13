import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/media_details.dart';
import '../models/sync_conflict.dart';

class SupabaseService {
  SupabaseClient? _client;
  bool _isInitialized = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Supabase
  Future<void> init() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  SupabaseClient get client {
    if (!_isInitialized || _client == null) {
      throw StateError('SupabaseService not initialized. Call init() first.');
    }
    return _client!;
  }

  /// Sync user data to Supabase
  Future<void> syncUserData(Map<String, dynamic> userData) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Skipping sync.');
      return;
    }
    
    try {
      await _client!.from('users').upsert(userData);
      print('✅ User data synced to Supabase');
    } catch (e) {
      print('❌ Error syncing user data: $e');
      // Do not rethrow - cloud sync is optional
    }
  }

  /// Sync anime list to Supabase with metadata
  Future<void> syncAnimeList(
    int userId, 
    List<Map<String, dynamic>> animeList, 
    {SyncMetadata? metadata}
  ) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Skipping anime list sync.');
      return;
    }
    
    try {
      // Delete existing entries for this user
      await _client!
          .from('anime_lists')
          .delete()
          .eq('user_id', userId);

      // Insert new entries with metadata
      if (animeList.isNotEmpty) {
        final syncMetadataJson = metadata?.toJson() ?? 
            SyncMetadata.current(SyncSource.app).toJson();
            
        final entries = animeList.map((entry) {
          return {
            ...entry,
            'user_id': userId,
            'synced_at': DateTime.now().toIso8601String(),
            'sync_metadata': syncMetadataJson,
          };
        }).toList();

        await _client!.from('anime_lists').insert(entries);
      }
      print('✅ Anime list synced to Supabase');
    } catch (e) {
      print('❌ Error syncing anime list: $e');
      // Do not rethrow - cloud sync is optional
    }
  }

  /// Sync manga list to Supabase with metadata
  Future<void> syncMangaList(
    int userId, 
    List<Map<String, dynamic>> mangaList,
    {SyncMetadata? metadata}
  ) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Skipping manga list sync.');
      return;
    }
    
    try {
      // Delete existing entries for this user
      await _client!
          .from('manga_lists')
          .delete()
          .eq('user_id', userId);

      // Insert new entries with metadata
      if (mangaList.isNotEmpty) {
        final syncMetadataJson = metadata?.toJson() ?? 
            SyncMetadata.current(SyncSource.app).toJson();
            
        final entries = mangaList.map((entry) {
          return {
            ...entry,
            'user_id': userId,
            'synced_at': DateTime.now().toIso8601String(),
            'sync_metadata': syncMetadataJson,
          };
        }).toList();

        await _client!.from('manga_lists').insert(entries);
      }
      print('✅ Manga list synced to Supabase');
    } catch (e) {
      print('❌ Error syncing manga list: $e');
      // Do not rethrow - cloud sync is optional
    }
  }

  /// Fetch user data from Supabase
  Future<Map<String, dynamic>?> fetchUserData(int userId) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Cannot fetch user data.');
      return null;
    }
    
    try {
      final response = await _client!
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching user data: $e');
      return null;
    }
  }

  /// Fetch anime list from Supabase
  Future<List<Map<String, dynamic>>> fetchAnimeList(int userId) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Cannot fetch anime list.');
      return [];
    }
    
    try {
      final response = await _client!
          .from('anime_lists')
          .select()
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching anime list: $e');
      return [];
    }
  }

  /// Fetch manga list from Supabase
  Future<List<Map<String, dynamic>>> fetchMangaList(int userId) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Cannot fetch manga list.');
      return [];
    }
    
    try {
      final response = await _client!
          .from('manga_lists')
          .select()
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching manga list: $e');
      return [];
    }
  }

  /// Update single anime entry in Supabase with metadata
  Future<void> updateAnimeEntry(
    int userId, 
    Map<String, dynamic> entry,
    {SyncMetadata? metadata}
  ) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Skipping anime entry update.');
      return;
    }
    
    try {
      final syncMetadataJson = metadata?.toJson() ?? 
          SyncMetadata.current(SyncSource.app).toJson();
          
      await _client!.from('anime_lists').upsert({
        ...entry,
        'user_id': userId,
        'synced_at': DateTime.now().toIso8601String(),
        'sync_metadata': syncMetadataJson,
      });
      print('✅ Anime entry updated in Supabase');
    } catch (e) {
      print('❌ Error updating anime entry: $e');
      // Do not rethrow - cloud sync is optional
    }
  }

  /// Update single manga entry in Supabase with metadata
  Future<void> updateMangaEntry(
    int userId, 
    Map<String, dynamic> entry,
    {SyncMetadata? metadata}
  ) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Skipping manga entry update.');
      return;
    }
    
    try {
      final syncMetadataJson = metadata?.toJson() ?? 
          SyncMetadata.current(SyncSource.app).toJson();
          
      await _client!.from('manga_lists').upsert({
        ...entry,
        'user_id': userId,
        'synced_at': DateTime.now().toIso8601String(),
        'sync_metadata': syncMetadataJson,
      });
      print('✅ Manga entry updated in Supabase');
    } catch (e) {
      print('❌ Error updating manga entry: $e');
      // Do not rethrow - cloud sync is optional
    }
  }

  /// Sync favorites to Supabase
  Future<void> syncFavorites(int userId, Map<String, dynamic> favorites) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Skipping favorites sync.');
      return;
    }
    
    try {
      await _client!.from('favorites').upsert({
        'user_id': userId,
        'data': favorites,
        'synced_at': DateTime.now().toIso8601String(),
      });
      print('✅ Favorites synced to Supabase');
    } catch (e) {
      print('❌ Error syncing favorites: $e');
      // Do not rethrow - cloud sync is optional
    }
  }

  /// Cache media details in Supabase
  Future<void> cacheMediaDetails(MediaDetails media) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Skipping media cache.');
      return;
    }
    
    try {
      await _client!.from('media_cache').upsert(media.toSupabaseJson());
      print('✅ Media cached in Supabase (id: ${media.id})');
    } catch (e) {
      print('❌ Error caching media: $e');
      // Do not rethrow - cloud caching is optional
    }
  }

  /// Search media in Supabase cache
  Future<List<MediaDetails>> searchMedia(String query, String? type) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Cannot search cache.');
      return [];
    }
    
    try {
      // Используем полнотекстовый поиск по всем названиям
      var queryBuilder = _client!
          .from('media_cache')
          .select()
          .or('title_romaji.ilike.%$query%,title_english.ilike.%$query%,title_native.ilike.%$query%');
      
      if (type != null) {
        queryBuilder = queryBuilder.eq('type', type);
      }
      
      final response = await queryBuilder.limit(20);
      
      print('✅ Found ${response.length} results in Supabase cache');
      
      return (response as List<dynamic>)
          .map((json) => _mediaDetailsFromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error searching media in cache: $e');
      return [];
    }
  }

  /// Get media details from Supabase cache
  Future<MediaDetails?> getMediaFromCache(int mediaId) async {
    if (!_isInitialized || _client == null) {
      print('⚠️ Supabase not initialized. Cannot get from cache.');
      return null;
    }
    
    try {
      final response = await _client!
          .from('media_cache')
          .select()
          .eq('id', mediaId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      return _mediaDetailsFromSupabase(response);
    } catch (e) {
      print('❌ Error getting media from cache: $e');
      return null;
    }
  }

  /// Convert Supabase JSON to MediaDetails
  MediaDetails _mediaDetailsFromSupabase(Map<String, dynamic> json) {
    return MediaDetails(
      id: json['id'] as int,
      type: json['type'] as String,
      titleRomaji: json['title_romaji'] as String?,
      titleEnglish: json['title_english'] as String?,
      titleNative: json['title_native'] as String?,
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String?,
      bannerImage: json['banner_image'] as String?,
      episodes: json['episodes'] as int?,
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      status: json['status'] as String?,
      format: json['format'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      averageScore: (json['average_score'] as num?)?.toDouble(),
      popularity: json['popularity'] as int?,
      season: json['season'] as String?,
      seasonYear: json['season_year'] as int?,
      source: json['source'] as String?,
      studios: (json['studios'] as List<dynamic>?)
          ?.map((s) => MediaStudio(
                id: s['id'] as int? ?? 0,
                name: s['name'] as String? ?? '',
                isAnimationStudio: s['isAnimationStudio'] as bool? ?? false,
              ))
          .toList(),
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      trailer: json['trailer'] as String?,
      synonyms: (json['synonyms'] as List<dynamic>?)?.cast<String>(),
      cachedAt: json['cached_at'] != null
          ? DateTime.parse(json['cached_at'] as String)
          : DateTime.now(),
      duration: json['duration'] as int?,
    );
  }
}
