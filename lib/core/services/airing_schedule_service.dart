import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/airing_episode.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';

/// Сервис для работы с расписанием выхода эпизодов
class AiringScheduleService {
  final AuthService _authService;
  final LocalStorageService _localStorageService;
  GraphQLClient? _client;
  
  AiringScheduleService(this._authService, this._localStorageService);
  
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
  
  /// Получить расписание выхода эпизодов для аниме из списка пользователя
  /// 
  /// Возвращает аниме со следующими статусами:
  /// - CURRENT (смотрю) - все эпизоды
  /// - REPEATING (пересматриваю) - все эпизоды
  /// - PLANNING (запланировано) - только первые эпизоды, выходящие в ближайшие 5 дней
  Future<List<AiringEpisode>> getUserAiringSchedule({
    int page = 1,
    int perPage = 50,
  }) async {
    await _ensureInitialized();
    
    // Сначала получаем ID пользователя
    const viewerQuery = '''
      query {
        Viewer {
          id
        }
      }
    ''';
    
    final viewerResult = await _client!.query(
      QueryOptions(
        document: gql(viewerQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    
    if (viewerResult.hasException) {
      print('Error fetching viewer: ${viewerResult.exception}');
      return [];
    }
    
    final userId = viewerResult.data?['Viewer']?['id'];
    if (userId == null) {
      print('User ID not found');
      return [];
    }
    
    // Теперь получаем список аниме пользователя со статусом CURRENT, REPEATING или PLANNING
    // Для PLANNING показываем только те, у которых первый эпизод выйдет в ближайшие 5 дней
    final listQuery = '''
      query(\$userId: Int) {
        watching: MediaListCollection(userId: \$userId, type: ANIME, status: CURRENT) {
          lists {
            entries {
              media {
                id
                nextAiringEpisode {
                  id
                  airingAt
                  timeUntilAiring
                  episode
                }
                title {
                  romaji
                  english
                }
                episodes
                isAdult
                coverImage {
                  large
                }
              }
            }
          }
        }
        repeating: MediaListCollection(userId: \$userId, type: ANIME, status: REPEATING) {
          lists {
            entries {
              media {
                id
                nextAiringEpisode {
                  id
                  airingAt
                  timeUntilAiring
                  episode
                }
                title {
                  romaji
                  english
                }
                episodes
                isAdult
                coverImage {
                  large
                }
              }
            }
          }
        }
        planning: MediaListCollection(userId: \$userId, type: ANIME, status: PLANNING) {
          lists {
            entries {
              media {
                id
                nextAiringEpisode {
                  id
                  airingAt
                  timeUntilAiring
                  episode
                }
                title {
                  romaji
                  english
                }
                episodes
                isAdult
                coverImage {
                  large
                }
              }
            }
          }
        }
      }
    ''';
    
    final result = await _client!.query(
      QueryOptions(
        document: gql(listQuery),
        variables: {
          'userId': userId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    
    if (result.hasException) {
      print('Error fetching airing schedule: ${result.exception}');
      return [];
    }
    
    final episodes = <AiringEpisode>[];
    final now = DateTime.now();
    final fiveDaysLater = now.add(Duration(days: 5));
    
    // Обрабатываем все три списка (CURRENT, REPEATING и PLANNING)
    final watching = result.data?['watching']?['lists'] as List<dynamic>?;
    final repeating = result.data?['repeating']?['lists'] as List<dynamic>?;
    final planning = result.data?['planning']?['lists'] as List<dynamic>?;
    
    void processEntries(List<dynamic>? lists, {bool filterByDate = false}) {
      if (lists == null) return;
      
      for (var list in lists) {
        final entries = list['entries'] as List<dynamic>?;
        if (entries == null) continue;
        
        for (var entry in entries) {
          final media = entry['media'] as Map<String, dynamic>?;
          if (media == null) continue;
          
          final nextAiring = media['nextAiringEpisode'] as Map<String, dynamic>?;
          if (nextAiring == null) continue; // Пропускаем если нет следующего эпизода
          
          // Фильтруем взрослый контент
          final isAdult = media['isAdult'] as bool? ?? false;
          if (isAdult && _localStorageService.shouldHideAdultContent()) {
            continue; // Пропускаем взрослый контент если включена фильтрация
          }
          
          final episode = nextAiring['episode'] as int;
          final airingAt = DateTime.fromMillisecondsSinceEpoch(
            (nextAiring['airingAt'] as int) * 1000,
          );
          
          // Для PLANNING: показываем только если это первый эпизод и выходит в ближайшие 5 дней
          if (filterByDate) {
            if (episode != 1) continue; // Только первый эпизод
            if (airingAt.isAfter(fiveDaysLater)) continue; // Только в ближайшие 5 дней
          }
          
          final title = media['title'] as Map<String, dynamic>;
          final coverImage = media['coverImage'] as Map<String, dynamic>?;
          
          episodes.add(AiringEpisode(
            id: nextAiring['id'] as int,
            mediaId: media['id'] as int,
            episode: nextAiring['episode'] as int,
            airingAt: DateTime.fromMillisecondsSinceEpoch(
              (nextAiring['airingAt'] as int) * 1000,
            ),
            timeUntilAiring: nextAiring['timeUntilAiring'] as int,
            title: (title['romaji'] ?? title['english'] ?? 'Unknown') as String,
            coverImageUrl: coverImage?['large'] as String?,
            totalEpisodes: media['episodes'] as int?,
            isAdult: isAdult,
          ));
        }
      }
    }
    
    processEntries(watching);
    processEntries(repeating);
    processEntries(planning, filterByDate: true); // Для PLANNING фильтруем по дате
    
    // Удаляем дубликаты по mediaId (аниме может быть в нескольких списках)
    final seenMediaIds = <int>{};
    final uniqueEpisodes = episodes.where((ep) {
      if (seenMediaIds.contains(ep.mediaId)) {
        return false; // Уже видели это аниме
      }
      seenMediaIds.add(ep.mediaId);
      return true;
    }).toList();
    
    // Сортируем по времени выхода (ближайшие первыми)
    uniqueEpisodes.sort((a, b) => a.airingAt.compareTo(b.airingAt));
    
    return uniqueEpisodes;
  }
  
  /// Получить эпизоды, выходящие сегодня
  Future<List<AiringEpisode>> getTodayEpisodes() async {
    final allEpisodes = await getUserAiringSchedule(perPage: 100);
    return allEpisodes.where((ep) => ep.isToday).toList();
  }
  
  /// Получить эпизоды, выходящие на этой неделе
  Future<List<AiringEpisode>> getThisWeekEpisodes() async {
    final allEpisodes = await getUserAiringSchedule(perPage: 100);
    return allEpisodes.where((ep) => ep.isThisWeek).toList();
  }
  
  /// Получить следующие N эпизодов
  Future<List<AiringEpisode>> getUpcomingEpisodes({int count = 10}) async {
    final allEpisodes = await getUserAiringSchedule(perPage: count);
    return allEpisodes.take(count).toList();
  }
}
