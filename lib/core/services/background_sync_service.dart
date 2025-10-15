import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/media_details.dart';
import '../models/push_notification_settings.dart';
import 'push_notification_service.dart';
import 'anilist_service.dart';
import 'airing_schedule_service.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';

/// Callback для фоновых задач (должен быть top-level функцией)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 Background task started: $task');

    try {
      // Инициализация Hive для фонового процесса
      await Hive.initFlutter();

      // Выполнить проверку новых эпизодов
      await BackgroundSyncService().checkForNewEpisodes();

      print('✅ Background task completed: $task');
      return Future.value(true);
    } catch (e) {
      print('❌ Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Сервис для фоновой синхронизации и проверки новых эпизодов
class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  static const String _taskName = 'episodeCheckTask';
  static const String _lastCheckKey = 'last_episode_check';

  bool _initialized = false;
  late Box _settingsBox;

  /// Инициализация фонового сервиса
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Инициализация Workmanager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Установить в true для отладки
      );

      _settingsBox = await Hive.openBox('background_sync_settings');
      _initialized = true;

      print('✅ Background sync service initialized');
    } catch (e) {
      print('❌ Error initializing background sync service: $e');
    }
  }

  /// Запустить периодические проверки
  Future<void> startPeriodicChecks({int intervalMinutes = 30}) async {
    if (!_initialized) await initialize();

    try {
      // Отменить существующие задачи
      await Workmanager().cancelByUniqueName(_taskName);

      // Зарегистрировать периодическую задачу
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: Duration(minutes: intervalMinutes),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      print('✅ Periodic episode checks started (every $intervalMinutes minutes)');
    } catch (e) {
      print('❌ Error starting periodic checks: $e');
    }
  }

  /// Остановить периодические проверки
  Future<void> stopPeriodicChecks() async {
    try {
      await Workmanager().cancelByUniqueName(_taskName);
      print('⏹️ Periodic episode checks stopped');
    } catch (e) {
      print('❌ Error stopping periodic checks: $e');
    }
  }

  /// Проверить новые эпизоды (вызывается из фонового процесса)
  Future<void> checkForNewEpisodes() async {
    try {
      final pushNotificationService = PushNotificationService();
      await pushNotificationService.initialize();

      final settings = pushNotificationService.getSettings();
      if (!settings.enabled || !settings.episodeNotificationsEnabled) {
        print('📭 Episode notifications are disabled');
        return;
      }

      // Получить время последней проверки
      final lastCheck = getLastCheckTime();
      final now = DateTime.now();

      print('🔍 Checking for new episodes since $lastCheck');

      // 🔔 Используем существующий AiringScheduleService для получения расписания
      try {
        // Инициализируем необходимые сервисы
        final authService = AuthService();
        final localStorageService = LocalStorageService();
        
        // Создаем AiringScheduleService
        final airingService = AiringScheduleService(authService, localStorageService);
        
        // Получаем все эпизоды из календаря (сегодня + предстоящие)
        final todayEpisodes = await airingService.getTodayEpisodes();
        final upcomingEpisodes = await airingService.getUpcomingEpisodes(count: 50);
        final allEpisodes = [...todayEpisodes, ...upcomingEpisodes];
        
        print('📅 Found ${allEpisodes.length} episodes in calendar');
        
        // Синхронизируем с push-уведомлениями
        await pushNotificationService.syncWithAiringSchedule(allEpisodes);
        
        print('✅ Successfully synced ${allEpisodes.length} episodes with notifications');
      } catch (e) {
        print('⚠️ Error fetching airing schedule: $e');
      }
      
      // Сохранить время проверки
      await saveLastCheckTime(now);

      print('✅ Episode check completed');
    } catch (e) {
      print('❌ Error checking for new episodes: $e');
    }
  }

  /// Проверить один конкретный аниме
  Future<void> checkAnimeForNewEpisodes({
    required int animeId,
    required String animeTitle,
    required int lastWatchedEpisode,
    required DateTime airingAt,
  }) async {
    try {
      final pushNotificationService = PushNotificationService();
      final settings = pushNotificationService.getSettings();

      final animeSettings = settings.getAnimeSettings(animeId);
      if (!animeSettings.enabled) return;

      // Определить время уведомления с учетом задержки
      final timing = animeSettings.customTiming ?? settings.episodeTiming;
      final notificationTime = airingAt.add(timing.delay);

      // Если время уведомления уже прошло, отправить сразу
      if (notificationTime.isBefore(DateTime.now())) {
        await pushNotificationService.showEpisodeNotification(
          animeId: animeId,
          animeTitle: animeTitle,
          episode: lastWatchedEpisode + 1,
        );
      } else {
        // Запланировать уведомление
        await pushNotificationService.scheduleNotification(
          id: animeId + (lastWatchedEpisode + 1) * 100000,
          title: '📺 New Episode Released!',
          message: 'Episode ${lastWatchedEpisode + 1} of $animeTitle is now available',
          scheduledDate: notificationTime,
          payload: 'anime:$animeId',
        );
      }
    } catch (e) {
      print('❌ Error checking anime $animeId: $e');
    }
  }

  /// Получить время последней проверки
  DateTime? getLastCheckTime() {
    final timestamp = _settingsBox.get(_lastCheckKey) as int?;
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Сохранить время последней проверки
  Future<void> saveLastCheckTime(DateTime time) async {
    await _settingsBox.put(_lastCheckKey, time.millisecondsSinceEpoch);
  }

  /// Получить статистику фоновых задач
  Map<String, dynamic> getStats() {
    final lastCheck = getLastCheckTime();
    return {
      'lastCheck': lastCheck?.toIso8601String(),
      'timeSinceLastCheck': lastCheck != null
          ? DateTime.now().difference(lastCheck).inMinutes
          : null,
      'isEnabled': _initialized,
    };
  }

  /// Закрыть сервис
  Future<void> dispose() async {
    await stopPeriodicChecks();
    await _settingsBox.close();
    _initialized = false;
  }
}
