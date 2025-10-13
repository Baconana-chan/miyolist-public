import 'media_list_entry.dart';

/// Represents a sync conflict between local and cloud data
class SyncConflict {
  final int entryId;
  final int mediaId;
  final String mediaTitle;
  final String? mediaCoverImage;
  final MediaListEntry localVersion;
  final MediaListEntry cloudVersion;
  final MediaListEntry? anilistVersion;
  final SyncMetadata localMetadata;
  final SyncMetadata cloudMetadata;
  final SyncMetadata? anilistMetadata;

  SyncConflict({
    required this.entryId,
    required this.mediaId,
    required this.mediaTitle,
    this.mediaCoverImage,
    required this.localVersion,
    required this.cloudVersion,
    this.anilistVersion,
    required this.localMetadata,
    required this.cloudMetadata,
    this.anilistMetadata,
  });

  /// Check if this is a three-way conflict (Local vs Cloud vs AniList)
  bool get isThreeWayConflict => anilistVersion != null;

  /// Get all conflicting fields with their values
  Map<String, ConflictingField> getConflictingFields() {
    final conflicts = <String, ConflictingField>{};

    // Compare status
    if (localVersion.status != cloudVersion.status) {
      conflicts['status'] = ConflictingField(
        fieldName: 'Status',
        localValue: localVersion.status,
        cloudValue: cloudVersion.status,
        anilistValue: anilistVersion?.status,
      );
    }

    // Compare score
    if (localVersion.score != cloudVersion.score) {
      conflicts['score'] = ConflictingField(
        fieldName: 'Score',
        localValue: localVersion.score?.toString() ?? 'Not set',
        cloudValue: cloudVersion.score?.toString() ?? 'Not set',
        anilistValue: anilistVersion?.score?.toString(),
      );
    }

    // Compare progress
    if (localVersion.progress != cloudVersion.progress) {
      conflicts['progress'] = ConflictingField(
        fieldName: 'Progress',
        localValue: localVersion.progress.toString(),
        cloudValue: cloudVersion.progress.toString(),
        anilistValue: anilistVersion?.progress.toString(),
      );
    }

    // Compare notes
    if (localVersion.notes != cloudVersion.notes) {
      conflicts['notes'] = ConflictingField(
        fieldName: 'Notes',
        localValue: localVersion.notes ?? 'No notes',
        cloudValue: cloudVersion.notes ?? 'No notes',
        anilistValue: anilistVersion?.notes,
      );
    }

    // Compare dates
    if (localVersion.startedAt != cloudVersion.startedAt) {
      conflicts['startedAt'] = ConflictingField(
        fieldName: 'Start Date',
        localValue: localVersion.startedAt?.toString() ?? 'Not set',
        cloudValue: cloudVersion.startedAt?.toString() ?? 'Not set',
        anilistValue: anilistVersion?.startedAt?.toString(),
      );
    }

    if (localVersion.completedAt != cloudVersion.completedAt) {
      conflicts['completedAt'] = ConflictingField(
        fieldName: 'Completed Date',
        localValue: localVersion.completedAt?.toString() ?? 'Not set',
        cloudValue: cloudVersion.completedAt?.toString() ?? 'Not set',
        anilistValue: anilistVersion?.completedAt?.toString(),
      );
    }

    // Compare repeat count
    if (localVersion.repeat != cloudVersion.repeat) {
      conflicts['repeat'] = ConflictingField(
        fieldName: 'Rewatches',
        localValue: localVersion.repeat?.toString() ?? '0',
        cloudValue: cloudVersion.repeat?.toString() ?? '0',
        anilistValue: anilistVersion?.repeat?.toString(),
      );
    }

    return conflicts;
  }
}

/// Represents a single conflicting field
class ConflictingField {
  final String fieldName;
  final String localValue;
  final String cloudValue;
  final String? anilistValue;

  ConflictingField({
    required this.fieldName,
    required this.localValue,
    required this.cloudValue,
    this.anilistValue,
  });

  bool get hasAniListConflict => anilistValue != null && 
      anilistValue != localValue && 
      anilistValue != cloudValue;
}

/// Metadata for tracking sync information
class SyncMetadata {
  final DateTime lastModified;
  final String deviceId;
  final String deviceName;
  final SyncSource source;

  SyncMetadata({
    required this.lastModified,
    required this.deviceId,
    required this.deviceName,
    required this.source,
  });

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      lastModified: json['last_modified'] is String
          ? DateTime.parse(json['last_modified'])
          : DateTime.fromMillisecondsSinceEpoch(json['last_modified'] * 1000),
      deviceId: json['device_id'] as String? ?? 'unknown',
      deviceName: json['device_name'] as String? ?? 'Unknown Device',
      source: SyncSource.fromString(json['source'] as String? ?? 'app'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last_modified': lastModified.toIso8601String(),
      'device_id': deviceId,
      'device_name': deviceName,
      'source': source.name,
    };
  }

  /// Create metadata for current device
  static SyncMetadata current(SyncSource source) {
    return SyncMetadata(
      lastModified: DateTime.now(),
      deviceId: _getDeviceId(),
      deviceName: _getDeviceName(),
      source: source,
    );
  }

  static String _getDeviceId() {
    // Use platform-specific device ID
    // For now, generate a persistent UUID stored in Hive
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _getDeviceName() {
    // Use platform-specific device name
    // For now, return platform name
    return 'Windows PC'; // TODO: Make dynamic based on Platform
  }
}

/// Source of the sync data
enum SyncSource {
  app,      // Local app modification
  anilist,  // Modified on AniList website
  cloud;    // Modified on another device via cloud

  static SyncSource fromString(String value) {
    switch (value.toLowerCase()) {
      case 'app':
        return SyncSource.app;
      case 'anilist':
        return SyncSource.anilist;
      case 'cloud':
        return SyncSource.cloud;
      default:
        return SyncSource.app;
    }
  }
}

/// Strategy for resolving conflicts
enum ConflictResolutionStrategy {
  /// Automatically choose the most recently modified version
  lastWriteWins,
  
  /// Always prefer local version
  preferLocal,
  
  /// Always prefer cloud version
  preferCloud,
  
  /// Always prefer AniList version (if available)
  preferAniList,
  
  /// Prompt user to manually resolve
  manual;

  String get displayName {
    switch (this) {
      case ConflictResolutionStrategy.lastWriteWins:
        return 'Last Write Wins (Automatic)';
      case ConflictResolutionStrategy.preferLocal:
        return 'Prefer Local Changes';
      case ConflictResolutionStrategy.preferCloud:
        return 'Prefer Cloud Changes';
      case ConflictResolutionStrategy.preferAniList:
        return 'Prefer AniList Changes';
      case ConflictResolutionStrategy.manual:
        return 'Ask Me Each Time';
    }
  }

  String get description {
    switch (this) {
      case ConflictResolutionStrategy.lastWriteWins:
        return 'Automatically use the most recently modified version';
      case ConflictResolutionStrategy.preferLocal:
        return 'Always use changes from this device';
      case ConflictResolutionStrategy.preferCloud:
        return 'Always use changes from other devices';
      case ConflictResolutionStrategy.preferAniList:
        return 'Always use changes from AniList website';
      case ConflictResolutionStrategy.manual:
        return 'Show a dialog to choose which version to keep';
    }
  }
}

/// Result of conflict resolution
class ConflictResolution {
  final MediaListEntry resolvedEntry;
  final SyncMetadata metadata;
  final ConflictResolutionStrategy usedStrategy;

  ConflictResolution({
    required this.resolvedEntry,
    required this.metadata,
    required this.usedStrategy,
  });
}
