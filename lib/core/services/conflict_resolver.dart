import '../models/media_list_entry.dart';
import '../models/sync_conflict.dart';
import 'local_storage_service.dart';
import 'crash_reporter.dart';

/// Service for detecting and resolving sync conflicts
class ConflictResolver {
  final LocalStorageService _localStorageService;
  final CrashReporter _crashReporter;

  // Default strategy (can be changed by user in settings)
  ConflictResolutionStrategy _defaultStrategy = 
      ConflictResolutionStrategy.lastWriteWins;

  ConflictResolver(this._localStorageService, this._crashReporter);

  /// Get current default resolution strategy
  ConflictResolutionStrategy get defaultStrategy => _defaultStrategy;

  /// Set default resolution strategy
  void setDefaultStrategy(ConflictResolutionStrategy strategy) {
    _defaultStrategy = strategy;
    _localStorageService.saveConflictResolutionStrategy(strategy);
    _crashReporter.log(
      'Conflict resolution strategy changed to: ${strategy.name}',
      level: LogLevel.info,
    );
  }

  /// Load saved strategy from storage
  void loadSavedStrategy() {
    final saved = _localStorageService.getConflictResolutionStrategy();
    if (saved != null) {
      _defaultStrategy = saved;
    }
  }

  /// Detect conflicts between local and cloud versions
  /// Returns list of conflicts that need resolution
  Future<List<SyncConflict>> detectConflicts({
    required List<MediaListEntry> localEntries,
    required List<Map<String, dynamic>> cloudEntries,
    List<MediaListEntry>? anilistEntries,
  }) async {
    final conflicts = <SyncConflict>[];

    try {
      // Create map of cloud entries for quick lookup
      final cloudMap = <int, Map<String, dynamic>>{};
      for (final cloudEntry in cloudEntries) {
        final id = cloudEntry['id'] as int;
        cloudMap[id] = cloudEntry;
      }

      // Create map of AniList entries if provided
      final anilistMap = <int, MediaListEntry>{};
      if (anilistEntries != null) {
        for (final entry in anilistEntries) {
          anilistMap[entry.id] = entry;
        }
      }

      // Check each local entry for conflicts
      for (final localEntry in localEntries) {
        final cloudData = cloudMap[localEntry.id];
        if (cloudData == null) continue;

        // Parse cloud entry
        final cloudEntry = MediaListEntry.fromJson(cloudData);
        final anilistEntry = anilistMap[localEntry.id];

        // Parse metadata
        final localMetadata = _getLocalMetadata(cloudData);
        final cloudMetadata = _getCloudMetadata(cloudData);
        final anilistMetadata = anilistEntry != null 
            ? _getAniListMetadata(anilistEntry)
            : null;

        // Check if entries are different
        if (_hasConflict(localEntry, cloudEntry)) {
          conflicts.add(SyncConflict(
            entryId: localEntry.id,
            mediaId: localEntry.mediaId,
            mediaTitle: localEntry.media?.titleRomaji ?? 'Unknown',
            mediaCoverImage: localEntry.media?.coverImage,
            localVersion: localEntry,
            cloudVersion: cloudEntry,
            anilistVersion: anilistEntry,
            localMetadata: localMetadata,
            cloudMetadata: cloudMetadata,
            anilistMetadata: anilistMetadata,
          ));
        }
      }

      if (conflicts.isNotEmpty) {
        _crashReporter.log(
          'Detected ${conflicts.length} sync conflicts',
          level: LogLevel.warning,
        );
      }
    } catch (e, stackTrace) {
      _crashReporter.log(
        'Error detecting conflicts: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    return conflicts;
  }

  /// Check if two entries have conflicting data
  bool _hasConflict(MediaListEntry local, MediaListEntry cloud) {
    return local.status != cloud.status ||
        local.score != cloud.score ||
        local.progress != cloud.progress ||
        local.notes != cloud.notes ||
        local.startedAt != cloud.startedAt ||
        local.completedAt != cloud.completedAt ||
        local.repeat != cloud.repeat;
  }

  /// Resolve a single conflict using the specified strategy
  Future<ConflictResolution> resolveConflict({
    required SyncConflict conflict,
    ConflictResolutionStrategy? strategy,
    MediaListEntry? manualSelection,
  }) async {
    final usedStrategy = strategy ?? _defaultStrategy;

    try {
      _crashReporter.log(
        'Resolving conflict for entry ${conflict.entryId} using ${usedStrategy.name}',
        level: LogLevel.info,
      );

      MediaListEntry resolvedEntry;
      SyncMetadata metadata;

      switch (usedStrategy) {
        case ConflictResolutionStrategy.lastWriteWins:
          // Choose the most recently modified version
          if (conflict.isThreeWayConflict) {
            // Three-way: check all timestamps
            final versions = [
              (conflict.localMetadata.lastModified, conflict.localVersion, conflict.localMetadata),
              (conflict.cloudMetadata.lastModified, conflict.cloudVersion, conflict.cloudMetadata),
              (conflict.anilistMetadata!.lastModified, conflict.anilistVersion!, conflict.anilistMetadata!),
            ];
            versions.sort((a, b) => b.$1.compareTo(a.$1));
            resolvedEntry = versions.first.$2;
            metadata = versions.first.$3;
          } else {
            // Two-way: local vs cloud
            if (conflict.localMetadata.lastModified.isAfter(conflict.cloudMetadata.lastModified)) {
              resolvedEntry = conflict.localVersion;
              metadata = conflict.localMetadata;
            } else {
              resolvedEntry = conflict.cloudVersion;
              metadata = conflict.cloudMetadata;
            }
          }
          break;

        case ConflictResolutionStrategy.preferLocal:
          resolvedEntry = conflict.localVersion;
          metadata = conflict.localMetadata;
          break;

        case ConflictResolutionStrategy.preferCloud:
          resolvedEntry = conflict.cloudVersion;
          metadata = conflict.cloudMetadata;
          break;

        case ConflictResolutionStrategy.preferAniList:
          if (conflict.anilistVersion != null) {
            resolvedEntry = conflict.anilistVersion!;
            metadata = conflict.anilistMetadata!;
          } else {
            // Fallback to last write wins if no AniList version
            if (conflict.localMetadata.lastModified.isAfter(conflict.cloudMetadata.lastModified)) {
              resolvedEntry = conflict.localVersion;
              metadata = conflict.localMetadata;
            } else {
              resolvedEntry = conflict.cloudVersion;
              metadata = conflict.cloudMetadata;
            }
          }
          break;

        case ConflictResolutionStrategy.manual:
          // Manual selection must be provided
          if (manualSelection == null) {
            throw ArgumentError('Manual selection required for manual strategy');
          }
          resolvedEntry = manualSelection;
          metadata = SyncMetadata.current(SyncSource.app);
          break;
      }

      return ConflictResolution(
        resolvedEntry: resolvedEntry,
        metadata: metadata,
        usedStrategy: usedStrategy,
      );
    } catch (e, stackTrace) {
      _crashReporter.log(
        'Error resolving conflict: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Resolve multiple conflicts at once
  Future<List<ConflictResolution>> resolveConflicts({
    required List<SyncConflict> conflicts,
    ConflictResolutionStrategy? strategy,
    Map<int, MediaListEntry>? manualSelections,
  }) async {
    final resolutions = <ConflictResolution>[];

    for (final conflict in conflicts) {
      final resolution = await resolveConflict(
        conflict: conflict,
        strategy: strategy,
        manualSelection: manualSelections?[conflict.entryId],
      );
      resolutions.add(resolution);
    }

    _crashReporter.log(
      'Resolved ${resolutions.length} conflicts',
      level: LogLevel.info,
    );

    return resolutions;
  }

  /// Get local metadata (from current device)
  SyncMetadata _getLocalMetadata(Map<String, dynamic> cloudData) {
    // Check if cloud data has local_metadata field
    if (cloudData.containsKey('local_metadata') && cloudData['local_metadata'] != null) {
      return SyncMetadata.fromJson(cloudData['local_metadata'] as Map<String, dynamic>);
    }

    // Fallback: use updatedAt from entry
    final updatedAt = cloudData['updated_at'] != null
        ? DateTime.parse(cloudData['updated_at'] as String)
        : DateTime.now();

    return SyncMetadata(
      lastModified: updatedAt,
      deviceId: 'local',
      deviceName: 'This Device',
      source: SyncSource.app,
    );
  }

  /// Get cloud metadata (from another device)
  SyncMetadata _getCloudMetadata(Map<String, dynamic> cloudData) {
    // Check if cloud data has sync_metadata field
    if (cloudData.containsKey('sync_metadata') && cloudData['sync_metadata'] != null) {
      return SyncMetadata.fromJson(cloudData['sync_metadata'] as Map<String, dynamic>);
    }

    // Fallback: use synced_at timestamp
    final syncedAt = cloudData['synced_at'] != null
        ? DateTime.parse(cloudData['synced_at'] as String)
        : DateTime.now();

    return SyncMetadata(
      lastModified: syncedAt,
      deviceId: 'cloud',
      deviceName: 'Other Device',
      source: SyncSource.cloud,
    );
  }

  /// Get AniList metadata
  SyncMetadata _getAniListMetadata(MediaListEntry entry) {
    return SyncMetadata(
      lastModified: entry.updatedAt ?? DateTime.now(),
      deviceId: 'anilist',
      deviceName: 'AniList Website',
      source: SyncSource.anilist,
    );
  }

  /// Create a merged entry from multiple versions (field-by-field merge)
  MediaListEntry mergeEntries({
    required MediaListEntry base,
    required Map<String, dynamic> fieldSelections,
  }) {
    // fieldSelections: {'status': localEntry.status, 'score': cloudEntry.score, ...}
    
    return base.copyWith(
      status: fieldSelections['status'] as String?,
      score: fieldSelections['score'] as double?,
      progress: fieldSelections['progress'] as int?,
      notes: fieldSelections['notes'] as String?,
      startedAt: fieldSelections['startedAt'] as DateTime?,
      completedAt: fieldSelections['completedAt'] as DateTime?,
      repeat: fieldSelections['repeat'] as int?,
    );
  }
}
