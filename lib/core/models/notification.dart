// Enum для типов уведомлений
enum NotificationType {
  airing,
  activity,
  forum,
  follows,
  media,
}

// Модель уведомления AniList
class AniListNotification {
  final int id;
  final String type; // AIRING, ACTIVITY, FORUM, FOLLOWS, MEDIA, etc.
  final int? userId; // ID пользователя (для FOLLOWS, ACTIVITY)
  final String? userName; // Имя пользователя
  final String? userAvatar; // Аватар пользователя
  final int? mediaId; // ID медиа (для AIRING, MEDIA)
  final String? mediaTitle; // Название медиа
  final String? mediaImage; // Обложка медиа
  final int? episode; // Номер эпизода (для AIRING)
  final int? activityId; // ID активности (для ACTIVITY)
  final int? threadId; // ID треда форума (для FORUM)
  final String? threadTitle; // Название треда форума
  final String? context; // Дополнительный контекст (текст комментария, и т.д.)
  final String? reason; // Причина (для MediaDataChangeNotification, MediaMergeNotification)
  final DateTime createdAt; // Время создания
  bool isRead; // Прочитано ли (mutable)

  AniListNotification({
    required this.id,
    required this.type,
    this.userId,
    this.userName,
    this.userAvatar,
    this.mediaId,
    this.mediaTitle,
    this.mediaImage,
    this.episode,
    this.activityId,
    this.threadId,
    this.threadTitle,
    this.context,
    this.reason,
    required this.createdAt,
    this.isRead = false,
  });

  factory AniListNotification.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    
    // Safe parsing of createdAt - handle both int and null
    DateTime createdAt;
    final createdAtValue = json['createdAt'];
    if (createdAtValue != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (createdAtValue as int) * 1000,
      );
    } else {
      createdAt = DateTime.now(); // Fallback to current time
    }
    
    return AniListNotification(
      id: json['id'] as int,
      type: type ?? 'UNKNOWN',
      userId: json['user']?['id'] as int?,
      userName: json['user']?['name'] as String?,
      userAvatar: json['user']?['avatar']?['large'] as String?,
      mediaId: json['media']?['id'] as int?,
      mediaTitle: json['media']?['title']?['romaji'] as String? ?? 
                  json['media']?['title']?['english'] as String?,
      mediaImage: json['media']?['coverImage']?['large'] as String?,
      episode: json['episode'] as int?,
      activityId: json['activityId'] as int?,
      threadId: json['thread']?['id'] as int?,
      threadTitle: json['thread']?['title'] as String?,
      context: json['context'] as String?,
      reason: json['reason'] as String?,
      createdAt: createdAt,
      isRead: false, // AniList не возвращает это поле в списке, только при просмотре
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'mediaId': mediaId,
      'mediaTitle': mediaTitle,
      'mediaImage': mediaImage,
      'episode': episode,
      'activityId': activityId,
      'threadId': threadId,
      'threadTitle': threadTitle,
      'context': context,
      'reason': reason,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'isRead': isRead,
    };
  }

  // Получить заголовок уведомления
  String getTitle() {
    return getTypeName();
  }

  // Получить текст уведомления
  String getText() {
    return getFormattedText();
  }

  // Получить URL для уведомления
  String? get url {
    if (activityId != null) {
      return 'https://anilist.co/activity/$activityId';
    } else if (threadId != null) {
      return 'https://anilist.co/forum/thread/$threadId';
    } else if (userId != null) {
      return 'https://anilist.co/user/$userId';
    }
    return null;
  }

  // Получить обложку медиа
  String? get coverImage => mediaImage;

  // Получить иконку для типа уведомления
  String getTypeIcon() {
    switch (type) {
      case 'AIRING':
        return '📺';
      case 'ACTIVITY_LIKE':
      case 'ACTIVITY_REPLY':
      case 'ACTIVITY_REPLY_LIKE':
      case 'ACTIVITY_MENTION':
      case 'ACTIVITY_MESSAGE':
        return '❤️';
      case 'THREAD_COMMENT_LIKE':
      case 'THREAD_COMMENT_REPLY':
      case 'THREAD_SUBSCRIBED':
      case 'THREAD_COMMENT_MENTION':
      case 'THREAD_LIKE':
        return '💬';
      case 'FOLLOWING':
        return '👤';
      case 'RELATED_MEDIA_ADDITION':
        return '🎬';
      default:
        return '🔔';
    }
  }

  // Получить человекочитаемое название типа
  String getTypeName() {
    switch (type) {
      case 'AIRING':
        return 'Airing';
      case 'ACTIVITY_LIKE':
      case 'ACTIVITY_REPLY':
      case 'ACTIVITY_REPLY_LIKE':
      case 'ACTIVITY_MENTION':
      case 'ACTIVITY_MESSAGE':
        return 'Activity';
      case 'THREAD_COMMENT_LIKE':
      case 'THREAD_COMMENT_REPLY':
      case 'THREAD_SUBSCRIBED':
      case 'THREAD_COMMENT_MENTION':
      case 'THREAD_LIKE':
        return 'Forum';
      case 'FOLLOWING':
        return 'Follows';
      case 'RELATED_MEDIA_ADDITION':
      case 'MEDIA_DATA_CHANGE':
      case 'MEDIA_MERGE':
      case 'MEDIA_DELETION':
        return 'Media';
      default:
        return 'Other';
    }
  }

  // Форматировать уведомление для отображения
  String getFormattedText() {
    switch (type) {
      case 'AIRING':
        return 'Episode $episode of ${mediaTitle ?? 'Unknown'} aired.';
      case 'ACTIVITY_LIKE':
        return '${userName ?? 'Someone'} liked your activity.';
      case 'ACTIVITY_REPLY':
        return '${userName ?? 'Someone'} replied to your activity.';
      case 'ACTIVITY_REPLY_LIKE':
        return '${userName ?? 'Someone'} liked your reply.';
      case 'ACTIVITY_MENTION':
        return '${userName ?? 'Someone'} mentioned you in an activity.';
      case 'ACTIVITY_MESSAGE':
        return '${userName ?? 'Someone'} sent you a message.';
      case 'THREAD_COMMENT_LIKE':
        return '${userName ?? 'Someone'} liked your comment.';
      case 'THREAD_COMMENT_REPLY':
        return '${userName ?? 'Someone'} replied to your comment in ${threadTitle ?? 'a thread'}.';
      case 'THREAD_SUBSCRIBED':
        return '${userName ?? 'Someone'} commented in your subscribed forum thread ${threadTitle ?? ''}.';
      case 'THREAD_COMMENT_MENTION':
        return '${userName ?? 'Someone'} mentioned you in ${threadTitle ?? 'a thread'}.';
      case 'THREAD_LIKE':
        return '${userName ?? 'Someone'} liked your forum thread${threadTitle != null ? ', $threadTitle' : ''}.';
      case 'FOLLOWING':
        return '${userName ?? 'Someone'} started following you.';
      case 'RELATED_MEDIA_ADDITION':
        return '${mediaTitle ?? 'A title'} was recently added to the site.';
      case 'MEDIA_DATA_CHANGE':
        final reasonText = reason != null ? '\nReason: $reason' : '';
        return '${mediaTitle ?? 'A title'} received site data changes.$reasonText';
      case 'MEDIA_MERGE':
        final reasonText = reason != null ? '\nReason: $reason' : '';
        return '${mediaTitle ?? 'A title'} was merged with another media.$reasonText';
      case 'MEDIA_DELETION':
        final reasonText = reason != null ? '\nReason: $reason' : '';
        return '${mediaTitle ?? 'A title'} was deleted from the site.$reasonText';
      default:
        return context ?? 'New notification';
    }
  }

  // Копирование с изменениями
  AniListNotification copyWith({
    bool? isRead,
  }) {
    return AniListNotification(
      id: id,
      type: type,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      mediaId: mediaId,
      mediaTitle: mediaTitle,
      mediaImage: mediaImage,
      episode: episode,
      activityId: activityId,
      threadId: threadId,
      threadTitle: threadTitle,
      context: context,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Настройки уведомлений
class NotificationSettings {
  final bool enabledAiring;
  final bool enabledActivity;
  final bool enabledForum;
  final bool enabledFollows;
  final bool enabledMedia;

  const NotificationSettings({
    this.enabledAiring = true,
    this.enabledActivity = true,
    this.enabledForum = true,
    this.enabledFollows = true,
    this.enabledMedia = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabledAiring: json['enabledAiring'] as bool? ?? true,
      enabledActivity: json['enabledActivity'] as bool? ?? true,
      enabledForum: json['enabledForum'] as bool? ?? true,
      enabledFollows: json['enabledFollows'] as bool? ?? true,
      enabledMedia: json['enabledMedia'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabledAiring': enabledAiring,
      'enabledActivity': enabledActivity,
      'enabledForum': enabledForum,
      'enabledFollows': enabledFollows,
      'enabledMedia': enabledMedia,
    };
  }

  NotificationSettings copyWith({
    bool? enabledAiring,
    bool? enabledActivity,
    bool? enabledForum,
    bool? enabledFollows,
    bool? enabledMedia,
  }) {
    return NotificationSettings(
      enabledAiring: enabledAiring ?? this.enabledAiring,
      enabledActivity: enabledActivity ?? this.enabledActivity,
      enabledForum: enabledForum ?? this.enabledForum,
      enabledFollows: enabledFollows ?? this.enabledFollows,
      enabledMedia: enabledMedia ?? this.enabledMedia,
    );
  }

  // Получить список включенных типов для GraphQL запроса
  List<String> getEnabledTypes() {
    final types = <String>[];
    
    if (enabledAiring) types.add('AIRING');
    if (enabledActivity) {
      types.addAll([
        'ACTIVITY_LIKE',
        'ACTIVITY_REPLY',
        'ACTIVITY_REPLY_LIKE',
        'ACTIVITY_MENTION',
      ]);
    }
    if (enabledForum) {
      types.addAll([
        'THREAD_COMMENT_LIKE',
        'THREAD_COMMENT_REPLY',
        'THREAD_SUBSCRIBED',
        'THREAD_COMMENT_MENTION',
      ]);
    }
    if (enabledFollows) types.add('FOLLOWING');
    if (enabledMedia) types.add('RELATED_MEDIA_ADDITION');
    
    return types;
  }
}
