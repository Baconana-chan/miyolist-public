import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:miyolist/core/services/conflict_resolver.dart';
import 'package:miyolist/core/services/local_storage_service.dart';
import 'package:miyolist/core/services/crash_reporter.dart';
import 'package:miyolist/core/models/media_list_entry.dart';
import 'package:miyolist/core/models/sync_conflict.dart';

// Generate mocks
@GenerateMocks([LocalStorageService, CrashReporter])
import 'conflict_resolver_test.mocks.dart';

void main() {
  late ConflictResolver conflictResolver;
  late MockLocalStorageService mockLocalStorage;
  late MockCrashReporter mockCrashReporter;

  setUp(() {
    mockLocalStorage = MockLocalStorageService();
    mockCrashReporter = MockCrashReporter();
    conflictResolver = ConflictResolver(mockLocalStorage, mockCrashReporter);
  });

  group('ConflictResolver - Strategy Management', () {
    test('default strategy should be lastWriteWins', () {
      expect(
        conflictResolver.defaultStrategy,
        equals(ConflictResolutionStrategy.lastWriteWins),
      );
    });

    test('setDefaultStrategy should update strategy and save to storage', () {
      // Arrange
      const newStrategy = ConflictResolutionStrategy.preferLocal;
      when(mockLocalStorage.saveConflictResolutionStrategy(any))
          .thenAnswer((_) async => {});

      // Act
      conflictResolver.setDefaultStrategy(newStrategy);

      // Assert
      expect(conflictResolver.defaultStrategy, equals(newStrategy));
      verify(mockLocalStorage.saveConflictResolutionStrategy(newStrategy))
          .called(1);
      verify(mockCrashReporter.log(any, level: anyNamed('level'))).called(1);
    });

    test('loadSavedStrategy should load strategy from storage', () {
      // Arrange
      const savedStrategy = ConflictResolutionStrategy.preferCloud;
      when(mockLocalStorage.getConflictResolutionStrategy())
          .thenReturn(savedStrategy);

      // Act
      conflictResolver.loadSavedStrategy();

      // Assert
      expect(conflictResolver.defaultStrategy, equals(savedStrategy));
      verify(mockLocalStorage.getConflictResolutionStrategy()).called(1);
    });

    test('loadSavedStrategy should keep default if no saved strategy', () {
      // Arrange
      const defaultStrategy = ConflictResolutionStrategy.lastWriteWins;
      when(mockLocalStorage.getConflictResolutionStrategy()).thenReturn(null);

      // Act
      conflictResolver.loadSavedStrategy();

      // Assert
      expect(conflictResolver.defaultStrategy, equals(defaultStrategy));
    });
  });

  group('ConflictResolver - Conflict Detection', () {
    test('detectConflicts should return empty list when no conflicts', () async {
      // Arrange
      final localEntry = _createTestEntry(
        id: 1,
        progress: 12,
        score: 8.5,
        updatedAt: DateTime(2025, 10, 1),
      );

      final cloudEntry = _createTestEntryMap(
        id: 1,
        progress: 12,
        score: 8.5,
        updatedAt: DateTime(2025, 10, 1),
      );

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        localEntries: [localEntry],
        cloudEntries: [cloudEntry],
      );

      // Assert
      expect(conflicts, isEmpty);
    });

    test('detectConflicts should detect progress difference', () async {
      // Arrange
      final localEntry = _createTestEntry(
        id: 1,
        progress: 15,
        score: 8.5,
        updatedAt: DateTime(2025, 10, 2),
      );

      final cloudEntry = _createTestEntryMap(
        id: 1,
        progress: 12,
        score: 8.5,
        updatedAt: DateTime(2025, 10, 1),
      );

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        localEntries: [localEntry],
        cloudEntries: [cloudEntry],
      );

      // Assert
      expect(conflicts.length, equals(1));
      expect(conflicts.first.entryId, equals(1));
      expect(conflicts.first.localVersion.progress, equals(15));
      expect(conflicts.first.cloudVersion.progress, equals(12));
    });

    test('detectConflicts should detect score difference', () async {
      // Arrange
      final localEntry = _createTestEntry(
        id: 1,
        progress: 12,
        score: 9.0,
        updatedAt: DateTime(2025, 10, 2),
      );

      final cloudEntry = _createTestEntryMap(
        id: 1,
        progress: 12,
        score: 8.0,
        updatedAt: DateTime(2025, 10, 1),
      );

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        localEntries: [localEntry],
        cloudEntries: [cloudEntry],
      );

      // Assert
      expect(conflicts.length, equals(1));
      expect(conflicts.first.localVersion.score, equals(9.0));
      expect(conflicts.first.cloudVersion.score, equals(8.0));
    });

    test('detectConflicts should detect status difference', () async {
      // Arrange
      final localEntry = _createTestEntry(
        id: 1,
        status: 'COMPLETED',
        updatedAt: DateTime(2025, 10, 2),
      );

      final cloudEntry = _createTestEntryMap(
        id: 1,
        status: 'CURRENT',
        updatedAt: DateTime(2025, 10, 1),
      );

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        localEntries: [localEntry],
        cloudEntries: [cloudEntry],
      );

      // Assert
      expect(conflicts.length, equals(1));
      expect(conflicts.first.localVersion.status, equals('COMPLETED'));
      expect(conflicts.first.cloudVersion.status, equals('CURRENT'));
    });

    test('detectConflicts should handle multiple conflicts', () async {
      // Arrange
      final localEntries = [
        _createTestEntry(id: 1, progress: 15, updatedAt: DateTime(2025, 10, 2)),
        _createTestEntry(id: 2, score: 9.0, updatedAt: DateTime(2025, 10, 2)),
        _createTestEntry(id: 3, progress: 5, updatedAt: DateTime(2025, 10, 2)),
      ];

      final cloudEntries = [
        _createTestEntryMap(id: 1, progress: 12, updatedAt: DateTime(2025, 10, 1)),
        _createTestEntryMap(id: 2, score: 8.0, updatedAt: DateTime(2025, 10, 1)),
        _createTestEntryMap(id: 3, progress: 5, updatedAt: DateTime(2025, 10, 1)), // No conflict
      ];

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        localEntries: localEntries,
        cloudEntries: cloudEntries,
      );

      // Assert
      expect(conflicts.length, equals(2)); // Only entries 1 and 2 have conflicts
      verify(mockCrashReporter.log(any, level: LogLevel.warning)).called(1);
    });

    test('detectConflicts should handle entries not in cloud', () async {
      // Arrange
      final localEntry = _createTestEntry(id: 1, progress: 12);
      final cloudEntry = _createTestEntryMap(id: 2, progress: 15); // Different ID

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        localEntries: [localEntry],
        cloudEntries: [cloudEntry],
      );

      // Assert
      expect(conflicts, isEmpty); // No conflict if entry not in cloud
    });
  });

  group('ConflictResolver - Three-Way Merge', () {
    test('detectConflicts should include AniList version when provided', () async {
      // Arrange
      final localEntry = _createTestEntry(
        id: 1,
        progress: 15,
        updatedAt: DateTime(2025, 10, 3),
      );

      final cloudEntry = _createTestEntryMap(
        id: 1,
        progress: 12,
        updatedAt: DateTime(2025, 10, 2),
      );

      final anilistEntry = _createTestEntry(
        id: 1,
        progress: 10,
        updatedAt: DateTime(2025, 10, 1),
      );

      // Act
      final conflicts = await conflictResolver.detectConflicts(
        localEntries: [localEntry],
        cloudEntries: [cloudEntry],
        anilistEntries: [anilistEntry],
      );

      // Assert
      expect(conflicts.length, equals(1));
      expect(conflicts.first.anilistVersion, isNotNull);
      expect(conflicts.first.anilistVersion!.progress, equals(10));
    });
  });
}

// Helper functions to create test data
MediaListEntry _createTestEntry({
  required int id,
  int? progress,
  double? score,
  String? status,
  DateTime? updatedAt,
}) {
  return MediaListEntry(
    id: id,
    mediaId: 1000 + id,
    status: status ?? 'CURRENT',
    progress: progress ?? 0,
    score: score ?? 0.0,
    repeat: 0,
    notes: '',
    startedAt: null,
    completedAt: null,
    updatedAt: updatedAt ?? DateTime.now(),
    media: null, // Simplified for tests
  );
}

Map<String, dynamic> _createTestEntryMap({
  required int id,
  int? progress,
  double? score,
  String? status,
  DateTime? updatedAt,
}) {
  final timestamp = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  
  return {
    'id': id,
    'mediaId': 1000 + id, // camelCase for mediaId
    'status': status ?? 'CURRENT',
    'progress': progress ?? 0,
    'score': score ?? 0.0,
    'repeat': 0,
    'notes': '',
    'startedAt': null,
    'completedAt': null,
    'updatedAt': timestamp, // Unix timestamp in seconds
  };
}
