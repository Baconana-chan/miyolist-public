import 'package:hive/hive.dart';
import 'anime_model.dart';

part 'media_list_entry.g.dart';

@HiveType(typeId: 2)
class MediaListEntry extends HiveObject {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final int mediaId;
  
  @HiveField(2)
  final String status; // CURRENT, PLANNING, COMPLETED, DROPPED, PAUSED, REPEATING
  
  @HiveField(3)
  final double? score;
  
  @HiveField(4)
  final int progress; // Episodes or chapters watched/read
  
  @HiveField(5)
  final int? progressVolumes;
  
  @HiveField(6)
  final int? repeat;
  
  @HiveField(7)
  final String? notes;
  
  @HiveField(8)
  final DateTime? startedAt;
  
  @HiveField(9)
  final DateTime? completedAt;
  
  @HiveField(10)
  final DateTime? updatedAt;
  
  @HiveField(11)
  final AnimeModel? media; // Associated anime/manga
  
  @HiveField(12)
  final List<String>? customLists; // Custom lists the entry belongs to

  MediaListEntry({
    required this.id,
    required this.mediaId,
    required this.status,
    this.score,
    required this.progress,
    this.progressVolumes,
    this.repeat,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
    this.media,
    this.customLists,
  });

  factory MediaListEntry.fromJson(Map<String, dynamic> json) {
    return MediaListEntry(
      id: json['id'] as int,
      mediaId: json['mediaId'] as int,
      status: json['status'] as String,
      score: json['score']?.toDouble(),
      progress: json['progress'] as int? ?? 0,
      progressVolumes: json['progressVolumes'] as int?,
      repeat: json['repeat'] as int?,
      notes: json['notes'] as String?,
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] * 1000)
          : null,
      media: json['media'] != null ? AnimeModel.fromJson(json['media']) : null,
      customLists: _parseCustomLists(json['customLists']),
    );
  }

  static List<String>? _parseCustomLists(dynamic customListsJson) {
    if (customListsJson == null) return null;
    
    // If it's already a List, parse it
    if (customListsJson is List) {
      return customListsJson
          .whereType<String>()
          .toList();
    }
    
    // If it's a Map (AniList returns custom lists as Map<String, bool>)
    if (customListsJson is Map) {
      return customListsJson.keys
          .where((key) => customListsJson[key] == true)
          .cast<String>()
          .toList();
    }
    
    return null;
  }

  static DateTime? _parseDate(dynamic dateJson) {
    if (dateJson == null) return null;
    try {
      final year = dateJson['year'] as int?;
      final month = dateJson['month'] as int?;
      final day = dateJson['day'] as int?;
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaId': mediaId,
      'status': status,
      'score': score,
      'progress': progress,
      'progressVolumes': progressVolumes,
      'repeat': repeat,
      'notes': notes,
      'startedAt': startedAt != null
          ? {
              'year': startedAt!.year,
              'month': startedAt!.month,
              'day': startedAt!.day,
            }
          : null,
      'completedAt': completedAt != null
          ? {
              'year': completedAt!.year,
              'month': completedAt!.month,
              'day': completedAt!.day,
            }
          : null,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'media': media?.toJson(),
      'customLists': customLists,
    };
  }

  /// Convert to JSON for Supabase sync (snake_case matching database schema)
  /// [isManga] - if true, includes progress_volumes field (for manga_lists table)
  Map<String, dynamic> toSupabaseJson({bool isManga = false}) {
    final json = {
      'id': id,
      'media_id': mediaId,
      'status': status,
      'score': score,
      'progress': progress,
      'repeat': repeat,
      'notes': notes,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // media сохраняется как JSONB
      'media': media?.toSupabaseJson(),
    };
    
    // Only include progress_volumes for manga (manga_lists table has this column)
    if (isManga) {
      json['progress_volumes'] = progressVolumes;
    }
    
    return json;
  }

  MediaListEntry copyWith({
    int? id,
    int? mediaId,
    String? status,
    double? score,
    int? progress,
    int? progressVolumes,
    int? repeat,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    AnimeModel? media,
    List<String>? customLists,
  }) {
    return MediaListEntry(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      status: status ?? this.status,
      score: score ?? this.score,
      progress: progress ?? this.progress,
      progressVolumes: progressVolumes ?? this.progressVolumes,
      repeat: repeat ?? this.repeat,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      media: media ?? this.media,
      customLists: customLists ?? this.customLists,
    );
  }
}
