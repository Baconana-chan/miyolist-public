# Conflict Resolution System

## Overview

MiyoList's **Conflict Resolution System** automatically detects and resolves sync conflicts between multiple devices, cloud storage (Supabase), and AniList website. This ensures your anime/manga lists stay consistent across all platforms without data loss.

---

## 🎯 Problem Solved

When using MiyoList on multiple devices (PC + Mobile) or making changes on AniList website, conflicts can arise:

```
Example Conflict:
┌─────────────────────────────────────────────────────────┐
│ PC:       Updated "Attack on Titan" progress to 15/25  │
│ Mobile:   Updated "Attack on Titan" score to 9.5/10    │
│ AniList:  Updated "Attack on Titan" status to PAUSED   │
└─────────────────────────────────────────────────────────┘
❓ Which version should be kept?
```

Without conflict resolution, the **last sync would overwrite** all other changes (Last-Write-Wins), potentially losing data.

---

## 🏗️ Architecture

### Components

1. **SyncConflict Model** (`lib/core/models/sync_conflict.dart`)
   - Represents a conflict with local, cloud, and optional AniList versions
   - Tracks metadata (timestamps, device info, source)
   - Identifies conflicting fields

2. **ConflictResolver Service** (`lib/core/services/conflict_resolver.dart`)
   - Detects conflicts by comparing versions
   - Supports 5 resolution strategies
   - Provides automatic and manual resolution

3. **ConflictResolutionDialog UI** (`lib/features/common/widgets/conflict_resolution_dialog.dart`)
   - Beautiful side-by-side comparison
   - Swipeable pages for multiple conflicts
   - One-click version selection

4. **Supabase Integration**
   - Stores `sync_metadata` JSONB column
   - Tracks last_modified, device_id, device_name, source
   - SQL migration included

---

## 📊 Resolution Strategies

### 1. Last-Write-Wins (Default) ✅
**Automatic** - Chooses the most recently modified version

```dart
Strategy: Last-Write-Wins
┌────────────────────────────────────┐
│ PC:      Modified 10 min ago       │ ← WINNER (most recent)
│ Mobile:  Modified 1 hour ago       │
│ AniList: Modified 2 hours ago      │
└────────────────────────────────────┘
Result: PC version is kept
```

**Best for:** Users who trust timestamps and want automatic resolution

### 2. Prefer Local 📱
**Automatic** - Always uses this device's version

**Best for:** Users who primarily use one device and want it to be the source of truth

### 3. Prefer Cloud ☁️
**Automatic** - Always uses the version from other devices (Supabase)

**Best for:** Users who want changes from other devices to take priority

### 4. Prefer AniList 🌐
**Automatic** - Always uses the version from AniList website

**Best for:** Users who manage lists on AniList.co and want it as the primary source

### 5. Ask Me Each Time (Manual) ❓
**Manual** - Shows dialog for user to choose

```dart
┌──────────────────────────────────────────────┐
│  ⚠️ Sync Conflicts Detected                  │
│                                               │
│  📺 Attack on Titan                          │
│                                               │
│  ┌─────────────┬─────────────┬──────────────┐│
│  │ This Device │ Other Device│   AniList    ││
│  ├─────────────┼─────────────┼──────────────┤│
│  │ Progress:15 │ Progress:10 │ Progress:10  ││
│  │ Score: 8.0  │ Score: 9.5  │ Score: 8.0   ││
│  │ Status:     │ Status:     │ Status:      ││
│  │ CURRENT     │ CURRENT     │ PAUSED       ││
│  └─────────────┴─────────────┴──────────────┘│
│                                               │
│  [Select This Device]  [Select Other Device] │
└──────────────────────────────────────────────┘
```

**Best for:** Power users who want full control

---

## 🔄 Conflict Detection Flow

```
1. User clicks "Sync" button
   ↓
2. Fetch cloud data from Supabase
   ↓
3. ConflictResolver.detectConflicts()
   - Compare local vs cloud entry by entry
   - Check: status, score, progress, notes, dates, repeat count
   - Extract sync_metadata for timestamps
   ↓
4. IF conflicts detected:
   ├─ Strategy = Manual?
   │  └─→ Show ConflictResolutionDialog
   │      └─→ User selects preferred version
   └─ Strategy = Automatic?
      └─→ Auto-resolve using strategy
          └─→ Apply chosen version
   ↓
5. Sync resolved data to Supabase with new metadata
   ↓
6. ✅ Success!
```

---

## 🛠️ Implementation Details

### Three-Way Merge

When conflicts involve all three sources (Local + Cloud + AniList):

```dart
Local:   Progress 15, Score 8.0
Cloud:   Progress 10, Score 9.5
AniList: Progress 10, Score 8.0, Status PAUSED

Resolution (Last-Write-Wins):
1. Compare timestamps:
   - Local:   2025-10-11 14:30
   - Cloud:   2025-10-11 13:00  ← Older
   - AniList: 2025-10-11 15:00  ← NEWEST

2. Result: AniList version wins
   - Progress: 10
   - Score: 8.0
   - Status: PAUSED
```

### Metadata Structure

```json
{
  "last_modified": "2025-10-11T15:30:00.000Z",
  "device_id": "device_abc123",
  "device_name": "Windows PC",
  "source": "app"  // "app" | "anilist" | "cloud"
}
```

### Field-Level Comparison

Conflict detection checks these fields:
- ✅ `status` (CURRENT, COMPLETED, PAUSED, etc.)
- ✅ `score` (0-10)
- ✅ `progress` (episodes/chapters)
- ✅ `notes` (user notes)
- ✅ `startedAt` (start date)
- ✅ `completedAt` (completion date)
- ✅ `repeat` (rewatch/reread count)

---

## 📝 Usage Examples

### Change Default Strategy

```dart
// In Settings or Profile page
final conflictResolver = ConflictResolver(
  localStorageService,
  CrashReporter(),
);

// Set to prefer AniList
conflictResolver.setDefaultStrategy(
  ConflictResolutionStrategy.preferAniList
);
```

### Manual Conflict Detection

```dart
// Fetch data
final localEntries = localStorageService.getAnimeList();
final cloudEntries = await supabaseService.fetchAnimeList(userId);
final anilistEntries = await anilistService.fetchAnimeList(userId);

// Detect conflicts
final conflicts = await conflictResolver.detectConflicts(
  localEntries: localEntries,
  cloudEntries: cloudEntries,
  anilistEntries: anilistEntries,
);

if (conflicts.isNotEmpty) {
  print('Found ${conflicts.length} conflicts');
  
  // Auto-resolve
  final resolutions = await conflictResolver.resolveConflicts(
    conflicts: conflicts,
    strategy: ConflictResolutionStrategy.lastWriteWins,
  );
  
  // Apply resolutions
  for (final resolution in resolutions) {
    await localStorageService.updateAnimeEntry(
      resolution.resolvedEntry
    );
  }
}
```

### Show Resolution Dialog

```dart
await showDialog(
  context: context,
  builder: (context) => ConflictResolutionDialog(
    conflicts: conflicts,
    onResolve: (resolvedEntries) async {
      // User selected versions
      for (final entry in resolvedEntries) {
        await applyResolution(entry);
      }
    },
    onCancel: () {
      Navigator.pop(context);
    },
  ),
);
```

---

## 🗄️ Database Setup

### Run Migration

1. Go to Supabase Dashboard: https://your-project.supabase.co
2. Open SQL Editor
3. Copy and run: `supabase_conflict_resolution_migration.sql`

```sql
-- Adds sync_metadata column to anime_lists and manga_lists
ALTER TABLE anime_lists 
ADD COLUMN IF NOT EXISTS sync_metadata JSONB DEFAULT NULL;

ALTER TABLE manga_lists 
ADD COLUMN IF NOT EXISTS sync_metadata JSONB DEFAULT NULL;
```

### Verify Migration

```sql
-- Check if columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('anime_lists', 'manga_lists') 
  AND column_name = 'sync_metadata';
```

---

## 🧪 Testing

### Test Scenario 1: Two-Way Conflict (Local vs Cloud)

1. **Setup:**
   - Device A: Update anime X progress to 15
   - Device B: Update anime X score to 9.5
   - Both sync to cloud

2. **Expected:**
   - Conflict detected on next sync
   - Last-Write-Wins: Device with newer timestamp wins
   - Manual: Dialog shows both versions

3. **Verify:**
   - Check logs: `⚠️ Detected X sync conflicts`
   - Verify chosen version applied correctly

### Test Scenario 2: Three-Way Conflict (Local + Cloud + AniList)

1. **Setup:**
   - PC: Update anime Y status to PAUSED
   - Mobile: Update anime Y progress to 20
   - AniList.co: Update anime Y score to 8.0
   - Sync from all sources

2. **Expected:**
   - Three-way conflict detected
   - Dialog shows all 3 versions side-by-side
   - User selects preferred version

3. **Verify:**
   - All 3 versions shown in UI
   - Timestamps displayed correctly
   - Selected version applied

### Test Scenario 3: Auto-Resolution

1. **Setup:**
   - Set strategy to `preferAniList`
   - Make conflicting changes on PC and AniList

2. **Expected:**
   - Automatic resolution without dialog
   - AniList version always wins

3. **Verify:**
   - No dialog shown
   - AniList changes applied
   - Log: `🔧 Auto-resolving conflicts with preferAniList`

---

## 🐛 Troubleshooting

### Issue: Conflicts not detected

**Possible causes:**
- sync_metadata column missing in database
- Old entries without metadata (NULL values)
- Timestamps not being set

**Solution:**
```dart
// Force metadata on next sync
await supabaseService.syncAnimeList(
  userId, 
  animeList,
  metadata: SyncMetadata.current(SyncSource.app),
);
```

### Issue: Dialog not showing

**Check:**
1. Strategy is set to `manual`
2. Conflicts list is not empty
3. Dialog called on UI thread

```dart
if (_conflictResolver.defaultStrategy == ConflictResolutionStrategy.manual) {
  await _showConflictResolutionDialog(conflicts);
}
```

### Issue: Wrong version chosen

**Verify:**
- Timestamps are correct
- Device clocks are synchronized
- Metadata is being saved properly

---

## 🔮 Future Enhancements

- [ ] Field-level merging (keep progress from PC, score from mobile)
- [ ] Conflict history viewer
- [ ] Bulk resolution presets
- [ ] Smart conflict prediction
- [ ] Offline conflict queue
- [ ] Conflict statistics dashboard

---

## 📚 API Reference

### ConflictResolver

```dart
class ConflictResolver {
  ConflictResolver(LocalStorageService, CrashReporter);
  
  // Properties
  ConflictResolutionStrategy get defaultStrategy;
  
  // Methods
  void setDefaultStrategy(ConflictResolutionStrategy strategy);
  void loadSavedStrategy();
  
  Future<List<SyncConflict>> detectConflicts({
    required List<MediaListEntry> localEntries,
    required List<Map<String, dynamic>> cloudEntries,
    List<MediaListEntry>? anilistEntries,
  });
  
  Future<ConflictResolution> resolveConflict({
    required SyncConflict conflict,
    ConflictResolutionStrategy? strategy,
    MediaListEntry? manualSelection,
  });
  
  Future<List<ConflictResolution>> resolveConflicts({
    required List<SyncConflict> conflicts,
    ConflictResolutionStrategy? strategy,
    Map<int, MediaListEntry>? manualSelections,
  });
}
```

### SyncConflict

```dart
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
  
  bool get isThreeWayConflict;
  Map<String, ConflictingField> getConflictingFields();
}
```

### SyncMetadata

```dart
class SyncMetadata {
  final DateTime lastModified;
  final String deviceId;
  final String deviceName;
  final SyncSource source;
  
  factory SyncMetadata.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  static SyncMetadata current(SyncSource source);
}
```

---

## 📄 License

This feature is part of MiyoList and follows the same license.

**Version:** 1.3.0  
**Last Updated:** October 11, 2025
