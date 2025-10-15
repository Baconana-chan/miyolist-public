import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/push_notification_settings.dart';
import '../models/airing_episode.dart';

/// Сервис для управления push-уведомлениями
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _settingsBoxName = 'push_notification_settings';
  static const String _historyBoxName = 'notification_history';
  
  Box<PushNotificationSettings>? _settingsBox;
  Box? _historyBox;

  bool _initialized = false;

  /// Callback для обновления прогресса (устанавливается извне)
  Future<void> Function(int mediaId, int episode)? onMarkEpisodeWatched;

  /// Callback для добавления аниме в Planning (устанавливается извне)
  Future<void> Function(int mediaId)? onAddToPlanning;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Инициализация timezone
      tz.initializeTimeZones();

      // Открыть Hive боксы
      _settingsBox = await Hive.openBox<PushNotificationSettings>(_settingsBoxName);
      _historyBox = await Hive.openBox(_historyBoxName);

      // Настройки для Linux/macOS
      const initializationSettingsLinux = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      // Настройки для Android
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        linux: initializationSettingsLinux,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      print('✅ Push notification service initialized');
    } catch (e) {
      print('❌ Error initializing push notification service: $e');
    }
  }

  /// Обработчик нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    print('📱 Action ID: ${response.actionId}');
    
    // Обработка действий (Mark as Watched, Snooze)
    if (response.actionId != null) {
      _handleNotificationAction(response.actionId!, response.payload);
      return;
    }
    
    // TODO: Navigate to relevant page based on payload
    // Payload format: "type:id" (e.g., "anime:12345", "activity:67890")
  }

  /// Обработчик действий уведомлений
  Future<void> _handleNotificationAction(String actionId, String? payload) async {
    if (payload == null) return;

    try {
      // Парсим payload: "anime:mediaId:episode:title"
      final parts = payload.split(':');
      if (parts.length < 3 || parts[0] != 'anime') return;

      final mediaId = int.parse(parts[1]);
      final episode = int.parse(parts[2]);
      final animeTitle = parts.length >= 4 ? parts.sublist(3).join(':') : 'Anime #$mediaId';

      if (actionId == 'mark_watched') {
        // Пометить эпизод как просмотренный
        print('✅ Marking episode $episode as watched for anime $mediaId');
        await _markEpisodeAsWatched(mediaId, episode, animeTitle);
      } else if (actionId.startsWith('snooze_')) {
        // Отложить уведомление
        final minutes = int.parse(actionId.split('_')[1]);
        print('⏰ Snoozing notification for $minutes minutes');
        await _snoozeNotification(mediaId, episode, animeTitle, minutes);
      } else if (actionId == 'add_planning') {
        // Добавить в Planning
        print('📋 Adding anime $mediaId to Planning');
        await _addToPlanning(mediaId, animeTitle);
      } else if (actionId == 'open_details') {
        // Открыть детали аниме
        print('📖 Opening details for anime $mediaId');
        // TODO: Навигация к странице аниме
      }
    } catch (e) {
      print('❌ Error handling notification action: $e');
    }
  }

  /// Пометить эпизод как просмотренный
  Future<void> _markEpisodeAsWatched(int mediaId, int episode, String animeTitle) async {
    try {
      if (onMarkEpisodeWatched != null) {
        // Используем callback для обновления через AniListService
        await onMarkEpisodeWatched!(mediaId, episode);
        
        // Показать подтверждение
        await showActivityNotification(
          title: '✅ Episode Marked as Watched',
          message: 'Episode $episode of "$animeTitle" has been updated on AniList',
        );
      } else {
        // Fallback если callback не установлен
        print('⚠️ Warning: onMarkEpisodeWatched callback not set');
        await showActivityNotification(
          title: 'ℹ️ Action Registered',
          message: 'Episode $episode of "$animeTitle" marked (sync pending)',
        );
      }
    } catch (e) {
      print('❌ Error marking episode as watched: $e');
      await showActivityNotification(
        title: '❌ Error',
        message: 'Failed to mark episode as watched',
      );
    }
  }

  /// Отложить уведомление
  Future<void> _snoozeNotification(int mediaId, int episode, String animeTitle, int minutes) async {
    try {
      final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
      
      // Запланировать новое уведомление
      await scheduleNotification(
        id: mediaId + episode * 100000,
        title: '📺 Episode Reminder',
        message: 'Episode $episode of "$animeTitle" is ready to watch',
        scheduledDate: snoozeTime,
        payload: 'anime:$mediaId:$episode:$animeTitle',
        includeActions: true,
      );
      
      // Показать подтверждение
      final minutesText = minutes >= 60 
          ? '${minutes ~/ 60}hr ${minutes % 60 > 0 ? '${minutes % 60}min' : ''}'.trim()
          : '${minutes}min';
      
      await showActivityNotification(
        title: '⏰ Reminder Set',
        message: '"$animeTitle" Episode $episode - reminder in $minutesText',
      );
      
      print('✅ Notification snoozed for $minutes minutes');
    } catch (e) {
      print('❌ Error snoozing notification: $e');
    }
  }

  /// Добавить аниме в Planning
  Future<void> _addToPlanning(int mediaId, String animeTitle) async {
    try {
      if (onAddToPlanning != null) {
        // Используем callback для добавления через AniListService
        await onAddToPlanning!(mediaId);
        
        // Показать подтверждение
        await showActivityNotification(
          title: '📋 Added to Planning',
          message: '"$animeTitle" has been added to your Planning list',
        );
      } else {
        // Fallback если callback не установлен
        print('⚠️ Warning: onAddToPlanning callback not set');
        await showActivityNotification(
          title: 'ℹ️ Action Registered',
          message: '"$animeTitle" will be added to Planning (sync pending)',
        );
      }
      
      print('✅ Added anime $mediaId to Planning');
    } catch (e) {
      print('❌ Error adding to planning: $e');
      await showActivityNotification(
        title: '❌ Error',
        message: 'Failed to add to Planning',
      );
    }
  }

  /// Получить настройки
  PushNotificationSettings getSettings() {
    if (_settingsBox == null || _settingsBox!.isEmpty) {
      return PushNotificationSettings();
    }
    return _settingsBox!.values.first;
  }

  /// Сохранить настройки
  Future<void> saveSettings(PushNotificationSettings settings) async {
    if (_settingsBox == null) {
      await initialize();
    }
    await _settingsBox!.clear();
    await _settingsBox!.add(settings);
  }

  /// Показать уведомление о новом эпизоде
  Future<void> showEpisodeNotification({
    required int animeId,
    required String animeTitle,
    required int episode,
    String? imageUrl,
  }) async {
    final settings = getSettings();
    if (!settings.enabled || !settings.episodeNotificationsEnabled) return;
    if (settings.isInQuietHours()) return;

    // Проверить настройки для конкретного аниме
    final animeSettings = settings.getAnimeSettings(animeId);
    if (!animeSettings.enabled) return;

    try {
      final notificationId = animeId + episode * 100000;

      // Linux notification details
      const linuxDetails = LinuxNotificationDetails();

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'episode_notifications',
        'Episode Notifications',
        channelDescription: 'Notifications for new anime episodes',
        importance: Importance.high,
        priority: Priority.high,
        playSound: settings.soundEnabled,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
      );

      await _notifications.show(
        notificationId,
        '📺 New Episode Released!',
        'Episode $episode of $animeTitle is now available',
        notificationDetails,
        payload: 'anime:$animeId',
      );

      // Сохранить в историю
      await _saveToHistory(
        type: 'episode',
        title: animeTitle,
        message: 'Episode $episode',
        animeId: animeId,
      );

      print('✅ Episode notification shown: $animeTitle - Episode $episode');
    } catch (e) {
      print('❌ Error showing episode notification: $e');
    }
  }

  /// Показать уведомление об активности
  Future<void> showActivityNotification({
    required String title,
    required String message,
    int? activityId,
  }) async {
    final settings = getSettings();
    if (!settings.enabled || !settings.activityNotificationsEnabled) return;
    if (settings.isInQuietHours()) return;

    try {
      final notificationId = activityId ?? DateTime.now().millisecondsSinceEpoch;

      const linuxDetails = LinuxNotificationDetails();

      final androidDetails = AndroidNotificationDetails(
        'activity_notifications',
        'Activity Notifications',
        channelDescription: 'Notifications for AniList activity',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: settings.soundEnabled,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
      );

      await _notifications.show(
        notificationId,
        title,
        message,
        notificationDetails,
        payload: activityId != null ? 'activity:$activityId' : null,
      );

      // Сохранить в историю
      await _saveToHistory(
        type: 'activity',
        title: title,
        message: message,
        activityId: activityId,
      );

      print('✅ Activity notification shown: $title');
    } catch (e) {
      print('❌ Error showing activity notification: $e');
    }
  }

  /// Запланировать уведомление на определенное время
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledDate,
    String? payload,
    bool includeActions = true,
  }) async {
    final settings = getSettings();
    if (!settings.enabled) return;

    try {
      const linuxDetails = LinuxNotificationDetails();

      final androidDetails = AndroidNotificationDetails(
        'scheduled_notifications',
        'Scheduled Notifications',
        channelDescription: 'Scheduled push notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: settings.soundEnabled,
        icon: '@mipmap/ic_launcher',
        // Добавляем действия (action buttons)
        actions: includeActions && payload != null && payload.startsWith('anime:')
            ? [
                const AndroidNotificationAction(
                  'mark_watched',
                  '✅ Watched',
                  showsUserInterface: false,
                ),
                const AndroidNotificationAction(
                  'snooze_15',
                  '⏰ 15min',
                  showsUserInterface: false,
                ),
                const AndroidNotificationAction(
                  'snooze_30',
                  '⏰ 30min',
                  showsUserInterface: false,
                ),
                const AndroidNotificationAction(
                  'snooze_60',
                  '⏰ 1hr',
                  showsUserInterface: false,
                ),
                const AndroidNotificationAction(
                  'snooze_120',
                  '⏰ 2hr',
                  showsUserInterface: false,
                ),
                const AndroidNotificationAction(
                  'snooze_180',
                  '⏰ 3hr',
                  showsUserInterface: false,
                ),
                const AndroidNotificationAction(
                  'add_planning',
                  '📋 Add to Planning',
                  showsUserInterface: false,
                ),
                const AndroidNotificationAction(
                  'open_details',
                  '📖 Open Details',
                  showsUserInterface: true,
                ),
              ]
            : null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        message,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('✅ Notification scheduled for $scheduledDate (with actions: $includeActions)');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Отменить уведомление
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Получить активные уведомления
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (Platform.isAndroid) {
      return await _notifications.pendingNotificationRequests();
    }
    return [];
  }

  /// Сохранить уведомление в историю
  Future<void> _saveToHistory({
    required String type,
    required String title,
    required String message,
    int? animeId,
    int? activityId,
  }) async {
    if (_historyBox == null) return;

    final historyEntry = {
      'type': type,
      'title': title,
      'message': message,
      'animeId': animeId,
      'activityId': activityId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _historyBox!.add(historyEntry);

    // Ограничить историю 100 записями
    if (_historyBox!.length > 100) {
      await _historyBox!.deleteAt(0);
    }
  }

  /// Получить историю уведомлений
  List<Map<String, dynamic>> getNotificationHistory() {
    if (_historyBox == null) return [];
    
    return _historyBox!.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
        .reversed
        .toList();
  }

  /// Очистить историю уведомлений
  Future<void> clearNotificationHistory() async {
    await _historyBox?.clear();
  }

  /// Проверить, разрешены ли уведомления на системном уровне
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    return true; // Windows не имеет API проверки
  }

  /// Запросить разрешение на уведомления (Android 13+)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// Проверить и обновить состояние канала уведомлений
  Future<void> updateNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    // Создать каналы уведомлений
    const episodeChannel = AndroidNotificationChannel(
      'episode_notifications',
      'Episode Notifications',
      description: 'Notifications for new anime episodes',
      importance: Importance.high,
      playSound: true,
    );

    const activityChannel = AndroidNotificationChannel(
      'activity_notifications',
      'Activity Notifications',
      description: 'Notifications for AniList activity',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await android.createNotificationChannel(episodeChannel);
    await android.createNotificationChannel(activityChannel);

    print('✅ Notification channels updated');
  }

  /// Синхронизация уведомлений с расписанием Airing Schedule
  /// 
  /// Автоматически планирует уведомления для всех эпизодов из календаря
  /// на основе настроек пользователя (timing delay)
  Future<void> syncWithAiringSchedule(List<AiringEpisode> airingEpisodes) async {
    if (!_initialized) await initialize();

    final settings = getSettings();
    if (!settings.enabled || !settings.episodeNotificationsEnabled) {
      print('❌ Episode notifications disabled, skipping sync');
      return;
    }

    print('🔄 Syncing ${airingEpisodes.length} episodes with push notifications...');

    int scheduled = 0;
    int skipped = 0;

    for (var episode in airingEpisodes) {
      try {
        // Проверяем настройки для конкретного аниме
        final animeSettings = settings.getAnimeSettings(episode.mediaId);
        if (!animeSettings.enabled) {
          skipped++;
          continue; // Пропускаем если уведомления отключены для этого аниме
        }

        // Получаем задержку уведомления
        final timing = animeSettings.customTiming ?? settings.episodeTiming;
        final notificationTime = _calculateNotificationTime(episode.airingAt, timing);

        // Планируем уведомление с действиями
        await scheduleNotification(
          id: episode.mediaId + episode.episode * 100000,
          title: '📺 New Episode Released!',
          message: 'Episode ${episode.episode} of ${episode.title} is now available',
          scheduledDate: notificationTime,
          payload: 'anime:${episode.mediaId}:${episode.episode}:${episode.title}',
          includeActions: true, // Включить кнопки действий
        );

        scheduled++;
      } catch (e) {
        print('⚠️ Error scheduling notification for episode: $e');
        skipped++;
      }
    }

    print('✅ Sync complete: $scheduled scheduled, $skipped skipped');
  }

  /// Вычислить время уведомления на основе времени выхода и настроек
  DateTime _calculateNotificationTime(
    DateTime airingAt,
    EpisodeNotificationTiming timing,
  ) {
    switch (timing) {
      case EpisodeNotificationTiming.onAir:
        return airingAt;
      case EpisodeNotificationTiming.oneHourAfter:
        return airingAt.add(const Duration(hours: 1));
      case EpisodeNotificationTiming.threeHoursAfter:
        return airingAt.add(const Duration(hours: 3));
      case EpisodeNotificationTiming.sixHoursAfter:
        return airingAt.add(const Duration(hours: 6));
      case EpisodeNotificationTiming.twelveHoursAfter:
        return airingAt.add(const Duration(hours: 12));
      case EpisodeNotificationTiming.twentyFourHoursAfter:
        return airingAt.add(const Duration(hours: 24));
    }
  }

  /// Отменить все запланированные уведомления для эпизодов
  Future<void> cancelAllEpisodeNotifications() async {
    if (!_initialized) await initialize();

    // Отменяем все уведомления в диапазоне ID для эпизодов (1000000-9999999)
    for (int id = 1000000; id < 10000000; id++) {
      await _notifications.cancel(id);
    }

    print('✅ All episode notifications cancelled');
  }

  /// Закрыть сервис
  Future<void> dispose() async {
    await _settingsBox?.close();
    await _historyBox?.close();
    _initialized = false;
  }
}
