import 'package:miyolist/features/social/data/models/social_user.dart';

/// Following user's entry for a specific media
class FollowingMediaEntry {
  final SocialUser user;
  final String status; // CURRENT, PLANNING, COMPLETED, etc.
  final double? score; // 0-100 or 0-10 depending on user settings
  final int? progress; // Episodes/chapters completed

  FollowingMediaEntry({
    required this.user,
    required this.status,
    this.score,
    this.progress,
  });

  factory FollowingMediaEntry.fromMap(Map<String, dynamic> map) {
    return FollowingMediaEntry(
      user: map['user'] as SocialUser,
      status: map['status'] as String,
      score: map['score'] as double?,
      progress: map['progress'] as int?,
    );
  }

  /// Get formatted status text
  String get statusText {
    switch (status) {
      case 'CURRENT':
        return 'Watching';
      case 'PLANNING':
        return 'Planning';
      case 'COMPLETED':
        return 'Completed';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      case 'REPEATING':
        return 'Rewatching';
      default:
        return status;
    }
  }

  /// Get status color
  static int getStatusColor(String status) {
    switch (status) {
      case 'CURRENT':
        return 0xFF00A8FF; // Blue
      case 'PLANNING':
        return 0xFF9C27B0; // Purple
      case 'COMPLETED':
        return 0xFF4CAF50; // Green
      case 'PAUSED':
        return 0xFFFF9800; // Orange
      case 'DROPPED':
        return 0xFFF44336; // Red
      case 'REPEATING':
        return 0xFF03A9F4; // Light Blue
      default:
        return 0xFF757575; // Gray
    }
  }
}
