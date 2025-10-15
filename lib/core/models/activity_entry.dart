import 'package:hive/hive.dart';

part 'activity_entry.g.dart';

/// Модель для отслеживания активности пользователя
/// Используется для создания GitHub-style contribution graph
@HiveType(typeId: 22)
class ActivityEntry extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String activityType;

  @HiveField(3)
  final int mediaId;

  @HiveField(4)
  final String mediaTitle;

  @HiveField(5)
  final String? mediaType; // 'ANIME', 'MANGA'

  @HiveField(6)
  final Map<String, dynamic>? details; // Old/new values

  ActivityEntry({
    required this.id,
    required this.timestamp,
    required this.activityType,
    required this.mediaId,
    required this.mediaTitle,
    this.mediaType,
    this.details,
  });

  /// Activity types
  static const String typeAdded = 'added';
  static const String typeProgress = 'progress';
  static const String typeStatus = 'status';
  static const String typeScore = 'score';
  static const String typeFavoriteAdded = 'favorite_added';
  static const String typeFavoriteRemoved = 'favorite_removed';
  static const String typeCustomList = 'custom_list';
  static const String typeNotes = 'notes';

  /// Get human-readable activity description
  String getDescription() {
    switch (activityType) {
      case typeAdded:
        return 'Added to list';
      case typeProgress:
        final oldProgress = details?['oldProgress'] ?? 0;
        final newProgress = details?['newProgress'] ?? 0;
        return 'Updated progress: $oldProgress → $newProgress';
      case typeStatus:
        final oldStatus = details?['oldStatus'] ?? 'Unknown';
        final newStatus = details?['newStatus'] ?? 'Unknown';
        return 'Changed status: $oldStatus → $newStatus';
      case typeScore:
        final oldScore = details?['oldScore'] ?? 0;
        final newScore = details?['newScore'] ?? 0;
        return 'Updated score: $oldScore → $newScore';
      case typeFavoriteAdded:
        return 'Added to favorites';
      case typeFavoriteRemoved:
        return 'Removed from favorites';
      case typeCustomList:
        return 'Custom list modified';
      case typeNotes:
        return 'Updated notes';
      default:
        return 'Unknown activity';
    }
  }

  /// Convert to JSON for export/backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'activityType': activityType,
      'mediaId': mediaId,
      'mediaTitle': mediaTitle,
      'mediaType': mediaType,
      'details': details,
    };
  }

  /// Create from JSON
  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      activityType: json['activityType'] as String,
      mediaId: json['mediaId'] as int,
      mediaTitle: json['mediaTitle'] as String,
      mediaType: json['mediaType'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}
