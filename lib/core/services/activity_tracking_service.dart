import 'package:hive/hive.dart';
import '../models/activity_entry.dart';

/// Сервис для отслеживания активности пользователя
/// Используется для создания графиков и contribution heatmap
class ActivityTrackingService {
  static const String _activityBox = 'activityBox';
  Box<ActivityEntry>? _box;

  /// Initialize service
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<ActivityEntry>(_activityBox);
    }
  }

  /// Get direct access to the Hive box (for importing historical data)
  Box<ActivityEntry>? getBox() => _box;

  /// Log a new activity
  Future<void> logActivity({
    required String activityType,
    required int mediaId,
    required String mediaTitle,
    String? mediaType,
    Map<String, dynamic>? details,
  }) async {
    await init();

    final entry = ActivityEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      timestamp: DateTime.now(),
      activityType: activityType,
      mediaId: mediaId,
      mediaTitle: mediaTitle,
      mediaType: mediaType,
      details: details,
    );

    await _box!.add(entry);
  }

  /// Get all activities
  Future<List<ActivityEntry>> getAllActivities() async {
    await init();
    return _box!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get activities for a specific date range
  Future<List<ActivityEntry>> getActivitiesInRange(
    DateTime start,
    DateTime end,
  ) async {
    await init();
    return _box!.values
        .where((entry) =>
            entry.timestamp.isAfter(start) &&
            entry.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get activity count by date (for heatmap)
  Future<Map<DateTime, int>> getActivityCountByDate({
    int? days,
  }) async {
    await init();

    final now = DateTime.now();
    final startDate = days != null
        ? now.subtract(Duration(days: days))
        : DateTime(now.year - 1, now.month, now.day);

    final activities = await getActivitiesInRange(startDate, now);
    final Map<DateTime, int> countByDate = {};

    for (var entry in activities) {
      final date = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      countByDate[date] = (countByDate[date] ?? 0) + 1;
    }

    return countByDate;
  }

  /// Get activity statistics for the last N days
  Future<Map<String, dynamic>> getActivityStats({int days = 365}) async {
    await init();

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final activities = await getActivitiesInRange(startDate, now);

    // Calculate statistics
    final totalActivities = activities.length;
    final activityByType = <String, int>{};
    final uniqueMediaCount = <int>{};
    final activeDays = <DateTime>{};

    for (var entry in activities) {
      // Count by type
      activityByType[entry.activityType] =
          (activityByType[entry.activityType] ?? 0) + 1;

      // Count unique media
      uniqueMediaCount.add(entry.mediaId);

      // Count active days
      final date = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      activeDays.add(date);
    }

    // Calculate current streak
    int currentStreak = 0;
    final today = DateTime(now.year, now.month, now.day);
    DateTime checkDate = today;

    while (true) {
      final hasActivity = activities.any((entry) {
        final entryDate = DateTime(
          entry.timestamp.year,
          entry.timestamp.month,
          entry.timestamp.day,
        );
        return entryDate.isAtSameMomentAs(checkDate);
      });

      if (hasActivity) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Check if it's the first day - allow one day gap for today
        if (checkDate.isAtSameMomentAs(today)) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    final sortedDates = activeDays.toList()..sort();
    for (var date in sortedDates) {
      if (lastDate == null) {
        tempStreak = 1;
      } else {
        final diff = date.difference(lastDate).inDays;
        if (diff == 1) {
          tempStreak++;
        } else {
          longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
          tempStreak = 1;
        }
      }
      lastDate = date;
    }
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    return {
      'totalActivities': totalActivities,
      'activityByType': activityByType,
      'uniqueMedia': uniqueMediaCount.length,
      'activeDays': activeDays.length,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'avgActivitiesPerDay': activeDays.isEmpty
          ? 0.0
          : totalActivities / activeDays.length,
    };
  }

  /// Clear old activities (keep last N days)
  Future<void> clearOldActivities({int keepDays = 730}) async {
    await init();

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: keepDays));

    final keysToDelete = <dynamic>[];
    for (var i = 0; i < _box!.length; i++) {
      final entry = _box!.getAt(i);
      if (entry != null && entry.timestamp.isBefore(cutoffDate)) {
        keysToDelete.add(entry.key);
      }
    }

    for (var key in keysToDelete) {
      await _box!.delete(key);
    }
  }

  /// Export activities as JSON
  Future<List<Map<String, dynamic>>> exportActivities() async {
    await init();
    return _box!.values.map((entry) => entry.toJson()).toList();
  }

  /// Import activities from JSON
  Future<void> importActivities(List<Map<String, dynamic>> jsonList) async {
    await init();
    for (var json in jsonList) {
      final entry = ActivityEntry.fromJson(json);
      await _box!.add(entry);
    }
  }

  /// Delete all activities (for testing/reset)
  Future<void> clearAllActivities() async {
    await init();
    await _box!.clear();
  }
}
