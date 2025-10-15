import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive/hive.dart';
import '../models/notification.dart';

class NotificationService {
  late final GraphQLClient _client;
  final Box _settingsBox;
  
  static const String _settingsKey = 'notification_settings';
  static const String _lastCheckKey = 'notification_last_check';

  NotificationService(String accessToken, this._settingsBox) {
    final httpLink = HttpLink(
      'https://graphql.anilist.co',
      defaultHeaders: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    final authLink = AuthLink(getToken: () => 'Bearer $accessToken');
    final link = authLink.concat(httpLink);

    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.mergeOptimistic,
        ),
      ),
    );
  }

  // Получить настройки уведомлений
  NotificationSettings getSettings() {
    final json = _settingsBox.get(_settingsKey) as Map?;
    if (json == null) return const NotificationSettings();
    return NotificationSettings.fromJson(Map<String, dynamic>.from(json));
  }

  // Сохранить настройки уведомлений
  Future<void> saveSettings(NotificationSettings settings) async {
    await _settingsBox.put(_settingsKey, settings.toJson());
  }

  // Получить время последней проверки уведомлений
  DateTime? getLastCheckTime() {
    final timestamp = _settingsBox.get(_lastCheckKey) as int?;
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Сохранить время последней проверки
  Future<void> saveLastCheckTime(DateTime time) async {
    await _settingsBox.put(_lastCheckKey, time.millisecondsSinceEpoch);
  }

  // Получить уведомления с AniList
  Future<List<AniListNotification>> fetchNotifications({
    int page = 1,
    int perPage = 25,
    List<String>? types,
    bool resetUnreadCount = false,
  }) async {
    const query = r'''
      query($page: Int, $perPage: Int, $type_in: [NotificationType], $resetNotificationCount: Boolean) {
        Page(page: $page, perPage: $perPage) {
          pageInfo {
            total
            currentPage
            lastPage
            hasNextPage
          }
          notifications(type_in: $type_in, resetNotificationCount: $resetNotificationCount) {
            ... on AiringNotification {
              id
              type
              episode
              contexts
              createdAt
              media {
                id
                type
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
              }
            }
            ... on FollowingNotification {
              id
              type
              context
              createdAt
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ActivityMessageNotification {
              id
              type
              context
              createdAt
              activityId
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ActivityMentionNotification {
              id
              type
              context
              createdAt
              activityId
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ActivityReplyNotification {
              id
              type
              context
              createdAt
              activityId
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ActivityReplyLikeNotification {
              id
              type
              context
              createdAt
              activityId
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ActivityLikeNotification {
              id
              type
              context
              createdAt
              activityId
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ThreadCommentMentionNotification {
              id
              type
              context
              createdAt
              commentId
              thread {
                id
                title
              }
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ThreadCommentReplyNotification {
              id
              type
              context
              createdAt
              commentId
              thread {
                id
                title
              }
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ThreadCommentSubscribedNotification {
              id
              type
              context
              createdAt
              commentId
              thread {
                id
                title
              }
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ThreadCommentLikeNotification {
              id
              type
              context
              createdAt
              commentId
              thread {
                id
                title
              }
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on ThreadLikeNotification {
              id
              type
              context
              createdAt
              thread {
                id
                title
              }
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            ... on RelatedMediaAdditionNotification {
              id
              type
              context
              createdAt
              media {
                id
                type
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
              }
            }
            ... on MediaDataChangeNotification {
              id
              type
              context
              reason
              createdAt
              media {
                id
                type
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
              }
            }
            ... on MediaMergeNotification {
              id
              type
              context
              reason
              createdAt
              media {
                id
                type
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
              }
              deletedMediaTitles
            }
            ... on MediaDeletionNotification {
              id
              type
              context
              reason
              deletedMediaTitle
              createdAt
            }
          }
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {
            'page': page,
            'perPage': perPage,
            if (types != null && types.isNotEmpty) 'type_in': types,
            'resetNotificationCount': resetUnreadCount,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Notification request timed out after 15 seconds');
          throw TimeoutException('Request timed out after 15 seconds');
        },
      );

      if (result.hasException) {
        print('Error fetching notifications: ${result.exception}');
        throw Exception('Failed to fetch notifications: ${result.exception}');
      }

      final notificationsData = result.data?['Page']?['notifications'] as List?;
      if (notificationsData == null) return [];

      final notifications = notificationsData
          .map((json) => AniListNotification.fromJson(json as Map<String, dynamic>))
          .toList();

      // Сохранить время последней проверки
      await saveLastCheckTime(DateTime.now());

      return notifications;
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Получить количество непрочитанных уведомлений
  Future<int> getUnreadCount() async {
    const query = r'''
      query {
        Viewer {
          unreadNotificationCount
        }
      }
    ''';

    final result = await _client.query(
      QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      print('Error fetching unread count: ${result.exception}');
      return 0;
    }

    return result.data?['Viewer']?['unreadNotificationCount'] as int? ?? 0;
  }

  // Сбросить счётчик непрочитанных (вызывается автоматически при загрузке с resetUnreadCount: true)
  Future<void> markAllAsRead() async {
    // Просто загружаем уведомления с флагом resetNotificationCount
    await fetchNotifications(resetUnreadCount: true, perPage: 1);
  }

  // Получить URL для открытия в браузере
  String getNotificationUrl(AniListNotification notification) {
    switch (notification.type) {
      case 'AIRING':
        if (notification.mediaId != null) {
          return 'https://anilist.co/anime/${notification.mediaId}';
        }
        break;
      case 'ACTIVITY_LIKE':
      case 'ACTIVITY_REPLY':
      case 'ACTIVITY_REPLY_LIKE':
      case 'ACTIVITY_MENTION':
        if (notification.activityId != null) {
          return 'https://anilist.co/activity/${notification.activityId}';
        }
        break;
      case 'THREAD_COMMENT_LIKE':
      case 'THREAD_COMMENT_REPLY':
      case 'THREAD_SUBSCRIBED':
      case 'THREAD_COMMENT_MENTION':
        if (notification.threadId != null) {
          return 'https://anilist.co/forum/thread/${notification.threadId}';
        }
        break;
      case 'FOLLOWING':
        if (notification.userId != null) {
          return 'https://anilist.co/user/${notification.userId}';
        }
        break;
      case 'RELATED_MEDIA_ADDITION':
        if (notification.mediaId != null) {
          return 'https://anilist.co/anime/${notification.mediaId}';
        }
        break;
    }
    return 'https://anilist.co/notifications';
  }

  // Проверить, нужно ли открывать в приложении
  bool shouldOpenInApp(AniListNotification notification) {
    // Только AIRING и RELATED_MEDIA_ADDITION открываем в приложении
    return notification.type == 'AIRING' || 
           notification.type == 'RELATED_MEDIA_ADDITION';
  }

  // Получить уведомления по типу (обёртка для fetchNotifications)
  Future<List<AniListNotification>> getNotifications({
    NotificationType? type,
    int page = 1,
    int perPage = 25,
  }) async {
    List<String>? types;
    if (type != null) {
      switch (type) {
        case NotificationType.airing:
          types = ['AIRING'];
          break;
        case NotificationType.activity:
          types = [
            'ACTIVITY_MESSAGE',
            'ACTIVITY_REPLY',
            'ACTIVITY_MENTION',
            'ACTIVITY_LIKE',
            'ACTIVITY_REPLY_LIKE',
            'ACTIVITY_REPLY_SUBSCRIBED',
          ];
          break;
        case NotificationType.forum:
          types = [
            'THREAD_COMMENT_MENTION',
            'THREAD_SUBSCRIBED',
            'THREAD_COMMENT_REPLY',
            'THREAD_LIKE',
            'THREAD_COMMENT_LIKE',
          ];
          break;
        case NotificationType.follows:
          types = ['FOLLOWING', 'ACTIVITY_MESSAGE'];
          break;
        case NotificationType.media:
          types = [
            'RELATED_MEDIA_ADDITION',
            'MEDIA_DATA_CHANGE',
            'MEDIA_MERGE',
            'MEDIA_DELETION',
          ];
          break;
      }
    }

    return await fetchNotifications(
      page: page,
      perPage: perPage,
      types: types,
    );
  }

  // Отметить уведомление как прочитанное
  Future<void> markAsRead(int notificationId) async {
    // В AniList API нет метода для отметки отдельного уведомления
    // Можно сохранить локально или использовать resetNotificationCount
    // Пока просто игнорируем
  }
}

