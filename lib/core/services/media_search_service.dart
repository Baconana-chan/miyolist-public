import '../models/media_details.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';
import 'anilist_service.dart';

class MediaSearchService {
  final LocalStorageService _localStorage;
  final SupabaseService _supabase;
  final AniListService _anilist;

  MediaSearchService({
    required LocalStorageService localStorage,
    required SupabaseService supabase,
    required AniListService anilist,
  })  : _localStorage = localStorage,
        _supabase = supabase,
        _anilist = anilist;

  /// Поиск медиа с трёхуровневой стратегией:
  /// 1. Сначала поиск в локальном кеше (Hive)
  /// 2. Если не найдено - поиск в Supabase
  /// 3. Если и там нет - запрос к AniList и кеширование результата
  Future<List<MediaDetails>> searchMedia({
    required String query,
    String? type, // 'ANIME', 'MANGA', или null для всех типов
  }) async {
    // 1. Проверяем локальный кеш
    final localResults = await _searchInLocalCache(query, type);
    if (localResults.isNotEmpty) {
      print('🔍 Found ${localResults.length} results in local cache');
      return localResults;
    }

    // 2. Проверяем Supabase
    try {
      final supabaseResults = await _searchInSupabase(query, type);
      if (supabaseResults.isNotEmpty) {
        print('🔍 Found ${supabaseResults.length} results in Supabase');
        // Сохраняем в локальный кеш
        for (final media in supabaseResults) {
          await _localStorage.saveMediaDetails(media);
        }
        return supabaseResults;
      }
    } catch (e) {
      print('⚠️ Supabase search error: $e');
    }

    // 3. Запрос к AniList
    print('🔍 Searching in AniList API...');
    final anilistResults = await _searchInAniList(query, type);
    
    // Кешируем результаты
    for (final media in anilistResults) {
      // Сохраняем в локальный кеш
      await _localStorage.saveMediaDetails(media);
      
      // Сохраняем в Supabase (в фоне, не ждём)
      _supabase.cacheMediaDetails(media).catchError((e) {
        print('⚠️ Failed to cache in Supabase: $e');
      });
    }

    return anilistResults;
  }

  /// Получение детальной информации о медиа
  Future<MediaDetails?> getMediaDetails(int mediaId) async {
    // 1. Проверяем локальный кеш
    final cached = await _localStorage.getMediaDetails(mediaId);
    if (cached != null && !cached.isCacheExpired()) {
      print('📦 Using cached media details (id: $mediaId)');
      return cached;
    }

    // 2. Запрос к AniList
    print('🌐 Fetching media details from AniList (id: $mediaId)');
    final media = await _anilist.getMediaDetails(mediaId);
    
    if (media != null) {
      // Сохраняем в локальный кеш
      await _localStorage.saveMediaDetails(media);
      
      // Сохраняем в Supabase (в фоне)
      _supabase.cacheMediaDetails(media).catchError((e) {
        print('⚠️ Failed to cache in Supabase: $e');
      });
    }

    return media;
  }

  Future<List<MediaDetails>> _searchInLocalCache(String query, String? type) async {
    final allMedia = await _localStorage.getAllCachedMedia();
    final lowerQuery = query.toLowerCase();
    
    return allMedia.where((media) {
      // Фильтр по типу
      if (type != null && media.type != type) {
        return false;
      }

      // Поиск по названиям и синонимам
      final matchesRomaji = media.titleRomaji?.toLowerCase().contains(lowerQuery) ?? false;
      final matchesEnglish = media.titleEnglish?.toLowerCase().contains(lowerQuery) ?? false;
      final matchesNative = media.titleNative?.toLowerCase().contains(lowerQuery) ?? false;
      final matchesSynonyms = media.synonyms?.any(
        (s) => s.toLowerCase().contains(lowerQuery),
      ) ?? false;

      return matchesRomaji || matchesEnglish || matchesNative || matchesSynonyms;
    }).toList();
  }

  Future<List<MediaDetails>> _searchInSupabase(String query, String? type) async {
    return await _supabase.searchMedia(query, type);
  }

  Future<List<MediaDetails>> _searchInAniList(String query, String? type) async {
    return await _anilist.searchMedia(query, type);
  }
}
