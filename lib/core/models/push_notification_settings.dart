import 'package:hive/hive.dart';

part 'push_notification_settings.g.dart';

/// Настройки push-уведомлений
@HiveType(typeId: 24)
class PushNotificationSettings extends HiveObject {
  // Глобальные настройки
  @HiveField(0)
  bool enabled;

  // Уведомления о выходе эпизодов
  @HiveField(1)
  bool episodeNotificationsEnabled;

  @HiveField(2)
  EpisodeNotificationTiming episodeTiming;

  // Уведомления об активности
  @HiveField(3)
  bool activityNotificationsEnabled;

  // Звук уведомлений
  @HiveField(4)
  bool soundEnabled;

  @HiveField(5)
  String? customSoundPath;

  // Тихие часы (Do Not Disturb)
  @HiveField(6)
  bool quietHoursEnabled;

  @HiveField(7)
  int quietHoursStart; // Час начала (0-23)

  @HiveField(8)
  int quietHoursEnd; // Час окончания (0-23)

  // Настройки по конкретным аниме
  @HiveField(9)
  Map<int, AnimeNotificationSettings> perAnimeSettings;

  // Частота проверки (в минутах)
  @HiveField(10)
  int checkIntervalMinutes;

  PushNotificationSettings({
    this.enabled = true,
    this.episodeNotificationsEnabled = true,
    this.episodeTiming = EpisodeNotificationTiming.onAir,
    this.activityNotificationsEnabled = true,
    this.soundEnabled = true,
    this.customSoundPath,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22, // 10 PM
    this.quietHoursEnd = 8, // 8 AM
    Map<int, AnimeNotificationSettings>? perAnimeSettings,
    this.checkIntervalMinutes = 30,
  }) : perAnimeSettings = perAnimeSettings ?? {};

  /// Проверить, находимся ли в тихих часах
  bool isInQuietHours() {
    if (!quietHoursEnabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;

    if (quietHoursStart < quietHoursEnd) {
      // Обычный диапазон (например, 22:00 - 08:00 следующего дня)
      return currentHour >= quietHoursStart && currentHour < quietHoursEnd;
    } else {
      // Диапазон через полночь (например, 22:00 - 08:00)
      return currentHour >= quietHoursStart || currentHour < quietHoursEnd;
    }
  }

  /// Получить настройки для конкретного аниме
  AnimeNotificationSettings getAnimeSettings(int animeId) {
    return perAnimeSettings[animeId] ?? AnimeNotificationSettings();
  }

  /// Установить настройки для конкретного аниме
  void setAnimeSettings(int animeId, AnimeNotificationSettings settings) {
    perAnimeSettings[animeId] = settings;
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'episodeNotificationsEnabled': episodeNotificationsEnabled,
      'episodeTiming': episodeTiming.name,
      'activityNotificationsEnabled': activityNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'customSoundPath': customSoundPath,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'perAnimeSettings': perAnimeSettings.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'checkIntervalMinutes': checkIntervalMinutes,
    };
  }

  factory PushNotificationSettings.fromJson(Map<String, dynamic> json) {
    return PushNotificationSettings(
      enabled: json['enabled'] ?? true,
      episodeNotificationsEnabled: json['episodeNotificationsEnabled'] ?? true,
      episodeTiming: EpisodeNotificationTiming.values.firstWhere(
        (e) => e.name == json['episodeTiming'],
        orElse: () => EpisodeNotificationTiming.onAir,
      ),
      activityNotificationsEnabled: json['activityNotificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      customSoundPath: json['customSoundPath'],
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 8,
      perAnimeSettings: (json['perAnimeSettings'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    int.parse(key),
                    AnimeNotificationSettings.fromJson(value),
                  )) ??
          {},
      checkIntervalMinutes: json['checkIntervalMinutes'] ?? 30,
    );
  }
}

/// Время отправки уведомления о выходе эпизода
@HiveType(typeId: 25)
enum EpisodeNotificationTiming {
  @HiveField(0)
  onAir, // Сразу при выходе

  @HiveField(1)
  oneHourAfter, // Через 1 час

  @HiveField(2)
  threeHoursAfter, // Через 3 часа

  @HiveField(3)
  sixHoursAfter, // Через 6 часов

  @HiveField(4)
  twelveHoursAfter, // Через 12 часов

  @HiveField(5)
  twentyFourHoursAfter, // Через 24 часа
}

extension EpisodeNotificationTimingExtension on EpisodeNotificationTiming {
  String get displayName {
    switch (this) {
      case EpisodeNotificationTiming.onAir:
        return 'On Air';
      case EpisodeNotificationTiming.oneHourAfter:
        return '1 Hour After';
      case EpisodeNotificationTiming.threeHoursAfter:
        return '3 Hours After';
      case EpisodeNotificationTiming.sixHoursAfter:
        return '6 Hours After';
      case EpisodeNotificationTiming.twelveHoursAfter:
        return '12 Hours After';
      case EpisodeNotificationTiming.twentyFourHoursAfter:
        return '24 Hours After';
    }
  }

  Duration get delay {
    switch (this) {
      case EpisodeNotificationTiming.onAir:
        return Duration.zero;
      case EpisodeNotificationTiming.oneHourAfter:
        return const Duration(hours: 1);
      case EpisodeNotificationTiming.threeHoursAfter:
        return const Duration(hours: 3);
      case EpisodeNotificationTiming.sixHoursAfter:
        return const Duration(hours: 6);
      case EpisodeNotificationTiming.twelveHoursAfter:
        return const Duration(hours: 12);
      case EpisodeNotificationTiming.twentyFourHoursAfter:
        return const Duration(hours: 24);
    }
  }
}

/// Настройки уведомлений для конкретного аниме
@HiveType(typeId: 26)
class AnimeNotificationSettings {
  @HiveField(0)
  bool enabled;

  @HiveField(1)
  EpisodeNotificationTiming? customTiming;

  @HiveField(2)
  bool customSoundEnabled;

  @HiveField(3)
  String? customSoundPath;

  AnimeNotificationSettings({
    this.enabled = true,
    this.customTiming,
    this.customSoundEnabled = false,
    this.customSoundPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'customTiming': customTiming?.name,
      'customSoundEnabled': customSoundEnabled,
      'customSoundPath': customSoundPath,
    };
  }

  factory AnimeNotificationSettings.fromJson(Map<String, dynamic> json) {
    return AnimeNotificationSettings(
      enabled: json['enabled'] ?? true,
      customTiming: json['customTiming'] != null
          ? EpisodeNotificationTiming.values.firstWhere(
              (e) => e.name == json['customTiming'],
              orElse: () => EpisodeNotificationTiming.onAir,
            )
          : null,
      customSoundEnabled: json['customSoundEnabled'] ?? false,
      customSoundPath: json['customSoundPath'],
    );
  }
}
