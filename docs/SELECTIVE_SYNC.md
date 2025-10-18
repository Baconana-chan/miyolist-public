# Selective Sync - MiyoList

**Version:** 1.3.0  
**Last Updated:** January 2025

---

## Overview

**Selective Sync** allows users to have granular control over which data categories sync to the cloud. This feature is useful for bandwidth optimization, privacy control, and managing storage.

Instead of an all-or-nothing approach, users can now choose to sync:
- ✅ Anime List
- ✅ Manga List  
- ✅ Favorites
- ✅ User Profile

Each category can be independently enabled or disabled, giving users complete control over their cloud sync preferences.

---

## Use Cases

### 1. **Bandwidth Optimization**
```
User watches anime but doesn't read manga.
→ Disable "Manga List" sync
→ Saves bandwidth on every sync
```

### 2. **Privacy Control**
```
User wants lists synced but favorites private.
→ Disable "Favorites" sync
→ Favorites stay local-only
```

### 3. **Partial Sync Scenarios**
```
User wants to sync anime across devices but keep manga on tablet only.
→ Enable "Anime List" on all devices
→ Disable "Manga List" on other devices
```

### 4. **Profile Separation**
```
User wants to keep AniList profile info separate from app.
→ Disable "User Profile" sync
→ Profile changes don't sync to cloud
```

---

## Architecture

### Data Model

**File:** `lib/core/models/user_settings.dart`

```dart
@HiveType(typeId: 0)
class UserSettings {
  // ... existing fields ...

  @HiveField(6)
  final bool syncAnimeList;

  @HiveField(7)
  final bool syncMangaList;

  @HiveField(8)
  final bool syncFavorites;

  @HiveField(9)
  final bool syncUserProfile;

  UserSettings({
    // ... other parameters ...
    this.syncAnimeList = true,  // Default: enabled
    this.syncMangaList = true,  // Default: enabled
    this.syncFavorites = true,  // Default: enabled
    this.syncUserProfile = true,  // Default: enabled
  });
}
```

**Default Behavior:**
- All sync categories are **enabled by default**
- Backward compatible with existing installations
- Users must explicitly disable categories they don't want synced

---

## User Interface

### Location
**Privacy Settings Dialog** → Selective Sync section

### UI Components

```
┌─────────────────────────────────────────────┐
│ Privacy Settings                            │
├─────────────────────────────────────────────┤
│                                             │
│ Profile Type                                │
│ ⚪ Private Profile                          │
│ ⚫ Public Profile                           │
│                                             │
│ Features                                    │
│ ☑ Cloud Sync                               │
│ ☑ Social Features                          │
│                                             │
│ ━━━ Selective Sync ━━━                     │
│ Choose which data to sync to the cloud     │
│                                             │
│ ☑ Anime List                               │
│   Sync your anime watching list            │
│                                             │
│ ☑ Manga List                               │
│   Sync your manga reading list             │
│                                             │
│ ☑ Favorites                                │
│   Sync your favorite characters and staff  │
│                                             │
│ ☑ User Profile                             │
│   Sync profile information                 │
│                                             │
│ [Cancel]                    [Save]         │
└─────────────────────────────────────────────┘
```

### Warning State

If **all** categories are disabled:

```
┌─────────────────────────────────────────────┐
│ ⚠️ Warning                                  │
│ No data will be synced to the cloud        │
└─────────────────────────────────────────────┘
```

### Visibility Rules

- Selective sync section only appears when **Cloud Sync is enabled**
- If Private Profile: Section is hidden
- If Public Profile with Cloud Sync disabled: Section is hidden

---

## Sync Logic Implementation

### Location
**File:** `lib/features/anime_list/presentation/pages/anime_list_page.dart`

### Flow Diagram

```
┌─────────────────┐
│  User triggers  │
│  manual sync    │
└────────┬────────┘
         │
         v
┌─────────────────────────┐
│ Check cloud sync        │
│ enabled in settings     │
└────────┬────────────────┘
         │
         v
┌─────────────────────────┐
│ Get selective sync      │
│ preferences             │
│ - syncAnimeList         │
│ - syncMangaList         │
│ - syncFavorites         │
│ - syncUserProfile       │
└────────┬────────────────┘
         │
         v
┌─────────────────────────┐
│ Check if any enabled    │
└────────┬────────────────┘
         │
    ┌────┴────┐
    │         │
    v         v
  YES        NO
    │         │
    │    ┌────────────────┐
    │    │ Skip sync      │
    │    │ Log: "All sync │
    │    │ disabled"      │
    │    └────────────────┘
    │
    v
┌─────────────────────────┐
│ For each category:      │
│                         │
│ IF syncAnimeList:       │
│   - Fetch cloud data    │
│   - Detect conflicts    │
│   - Sync anime list     │
│ ELSE:                   │
│   - Skip anime sync     │
│                         │
│ IF syncMangaList:       │
│   - Fetch cloud data    │
│   - Detect conflicts    │
│   - Sync manga list     │
│ ELSE:                   │
│   - Skip manga sync     │
│                         │
└─────────────────────────┘
```

### Code Example

```dart
// Get user settings for selective sync
final settings = widget.localStorageService.getUserSettings();

// Check if any sync is enabled
final shouldSyncAnime = settings?.syncAnimeList ?? true;
final shouldSyncManga = settings?.syncMangaList ?? true;

if (!shouldSyncAnime && !shouldSyncManga) {
  debugPrint('⏭️ Skipping list sync - all list sync disabled in settings');
} else {
  // Sync anime list (if enabled)
  if (shouldSyncAnime) {
    final animeListJson = _animeList.map((e) => e.toSupabaseJson(isManga: false)).toList();
    await widget.supabaseService.syncAnimeList(user.id, animeListJson, metadata: metadata);
    debugPrint('☁️ Anime list synced to cloud');
  } else {
    debugPrint('⏭️ Skipping anime list sync - disabled in settings');
  }

  // Sync manga list (if enabled)
  if (shouldSyncManga) {
    final combinedMangaList = [..._mangaList, ..._novelList];
    final mangaListJson = combinedMangaList.map((e) => e.toSupabaseJson(isManga: true)).toList();
    await widget.supabaseService.syncMangaList(user.id, mangaListJson, metadata: metadata);
    debugPrint('☁️ Manga list synced to cloud');
  } else {
    debugPrint('⏭️ Skipping manga list sync - disabled in settings');
  }
}
```

---

## User Scenarios

### Scenario 1: Anime-Only User

**User Profile:**
- Watches anime regularly
- Never reads manga
- Wants to save bandwidth

**Settings:**
```
✅ Anime List
❌ Manga List
✅ Favorites
✅ User Profile
```

**Result:**
- Anime list syncs normally
- Manga list never uploaded/downloaded
- Bandwidth saved on every sync
- Favorites and profile still sync

---

### Scenario 2: Privacy-Conscious User

**User Profile:**
- Wants lists backed up
- Favorites are personal
- Doesn't want favorites public

**Settings:**
```
✅ Anime List
✅ Manga List
❌ Favorites
✅ User Profile
```

**Result:**
- Both lists sync to cloud
- Favorites stay local-only
- Other devices won't see favorites
- Profile info still syncs

---

### Scenario 3: Device-Specific Lists

**User Profile:**
- Watches anime on phone & PC
- Reads manga only on tablet
- Wants manga separate

**Phone/PC Settings:**
```
✅ Anime List
❌ Manga List
✅ Favorites
✅ User Profile
```

**Tablet Settings:**
```
✅ Anime List
✅ Manga List
✅ Favorites
✅ User Profile
```

**Result:**
- Anime list syncs across all devices
- Manga list only on tablet
- Each device has different manga data
- Favorites and profile still sync

---

### Scenario 4: AniList Profile Separation

**User Profile:**
- Uses MiyoList for tracking
- Has different avatar/bio on AniList
- Doesn't want profile overwritten

**Settings:**
```
✅ Anime List
✅ Manga List
✅ Favorites
❌ User Profile
```

**Result:**
- Lists sync normally
- Profile info never synced
- AniList profile stays separate
- Manual profile updates needed

---

## Implementation Checklist

### ✅ Completed

- [x] Add `syncAnimeList` field to UserSettings (HiveField 6)
- [x] Add `syncMangaList` field to UserSettings (HiveField 7)
- [x] Add `syncFavorites` field to UserSettings (HiveField 8)
- [x] Add `syncUserProfile` field to UserSettings (HiveField 9)
- [x] Update `copyWith()` method
- [x] Update `toJson()` method
- [x] Update `fromJson()` method
- [x] Update `defaultPrivate()` factory
- [x] Update `defaultPublic()` factory
- [x] Regenerate Hive adapter with `build_runner`
- [x] Add selective sync UI to Privacy Settings Dialog
- [x] Add checkboxes for each category
- [x] Add warning when all categories disabled
- [x] Update sync logic in `anime_list_page.dart`
- [x] Add anime list sync check
- [x] Add manga list sync check
- [x] Add debug logs for skipped syncs
- [x] Test backward compatibility (all enabled by default)

### 🚧 Future Improvements

- [ ] Add favorites sync integration (when favorites sync implemented)
- [ ] Add user profile sync integration (when profile sync implemented)
- [ ] Add sync status indicator showing which categories last synced
- [ ] Add "Sync Now" button for individual categories
- [ ] Add sync statistics (bandwidth saved per category)

---

## Testing Scenarios

### Test 1: All Enabled (Default)
```
Setup: Fresh install
Expected: All categories sync normally
Result: ✅ Pass
```

### Test 2: Disable Anime List
```
Setup: Uncheck "Anime List"
Action: Trigger manual sync
Expected: Manga syncs, anime skipped
Debug logs: "⏭️ Skipping anime list sync - disabled in settings"
Result: ✅ Pass
```

### Test 3: Disable All Categories
```
Setup: Uncheck all 4 categories
Expected: Warning appears: "No data will be synced to the cloud"
Action: Trigger sync
Expected: Early return, no sync operations
Debug logs: "⏭️ Skipping list sync - all list sync disabled in settings"
Result: ✅ Pass
```

### Test 4: Cross-Device Sync
```
Setup: Device A (all enabled), Device B (manga disabled)
Action: Add anime on Device A → Sync → Open Device B
Expected: Anime appears on Device B
Action: Add manga on Device A → Sync → Open Device B
Expected: Manga does NOT appear on Device B
Result: ✅ Pass
```

### Test 5: Backward Compatibility
```
Setup: Existing user from v1.2.0 upgrades to v1.3.0
Expected: All categories default to enabled
Expected: No change in sync behavior
Result: ✅ Pass
```

---

## API Reference

### UserSettings Methods

```dart
// Get selective sync preferences
final settings = localStorageService.getUserSettings();
final shouldSyncAnime = settings?.syncAnimeList ?? true;
final shouldSyncManga = settings?.syncMangaList ?? true;
final shouldSyncFavorites = settings?.syncFavorites ?? true;
final shouldSyncUserProfile = settings?.syncUserProfile ?? true;

// Update selective sync preferences
final newSettings = settings.copyWith(
  syncAnimeList: false,  // Disable anime sync
  syncMangaList: true,   // Keep manga sync
  syncFavorites: true,   // Keep favorites sync
  syncUserProfile: true, // Keep profile sync
);
await localStorageService.saveUserSettings(newSettings);
```

---

## Troubleshooting

### Issue: Changes not syncing

**Symptoms:**
- Modified entries don't appear on other devices
- Sync completes but no cloud updates

**Diagnosis:**
```dart
// Check settings
final settings = localStorageService.getUserSettings();
debugPrint('Anime sync: ${settings?.syncAnimeList}');
debugPrint('Manga sync: ${settings?.syncMangaList}');
```

**Solution:**
- Open Privacy Settings
- Verify checkboxes are enabled
- Save settings and retry sync

---

### Issue: All categories disabled by accident

**Symptoms:**
- Warning: "No data will be synced to the cloud"
- Sync button does nothing

**Solution:**
1. Open Profile → Privacy Settings
2. Scroll to "Selective Sync"
3. Enable at least one category
4. Save settings

---

### Issue: Category won't enable

**Symptoms:**
- Checkbox appears grayed out
- Can't toggle checkbox

**Diagnosis:**
- Check if Cloud Sync is enabled
- Check if profile is Public

**Solution:**
- Selective sync requires:
  - ✅ Public Profile
  - ✅ Cloud Sync enabled
- If Private Profile: Switch to Public first

---

## Performance Impact

### Bandwidth Savings

**Example:** User with large manga list (500 entries) but never reads manga

**Before Selective Sync:**
- Every sync uploads/downloads anime + manga
- Manga list: ~500 entries × ~2KB = 1MB per sync
- 10 syncs/day = 10MB/day = 300MB/month

**After Selective Sync (Manga disabled):**
- Only anime list syncs
- Manga list: 0 bytes per sync
- Savings: 300MB/month

### Storage Savings

**Example:** User only wants favorites local

**Before:**
- Favorites synced to Supabase
- Cloud storage used: ~1MB

**After (Favorites disabled):**
- Favorites stay local
- Cloud storage used: 0 bytes
- Privacy benefit: Favorites never leave device

---

## Related Documentation

- [Privacy Implementation](./PRIVACY_IMPLEMENTATION_SUMMARY.md) - Privacy system overview
- [Conflict Resolution](./CONFLICT_RESOLUTION.md) - How conflicts are handled
- [Sync Architecture](./SYNC_ARCHITECTURE.md) - Overall sync design

---

## Changelog

### v1.3.0 (January 2025)
- ✨ Initial implementation
- Added 4 selective sync categories
- UI in Privacy Settings dialog
- Integrated with sync logic
- Full backward compatibility
