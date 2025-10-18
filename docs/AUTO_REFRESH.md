# Auto-Refresh from AniList

## Overview
Implemented automatic data fetching from AniList on app startup to ensure custom lists and other updates are always current.

## Features

### 1. **Auto-Fetch on App Start**
- Automatically fetches latest data from AniList when app opens
- Runs in background without blocking UI
- Updates local storage with fresh data
- Non-critical - app still works if fetch fails

### 2. **Manual Refresh Button**
- New "Refresh" button (🔄) in app bar
- Fetches latest data from AniList immediately
- No cooldown period (unlike Sync button)
- Shows notification on completion

### 3. **Bidirectional Sync**
- **Sync button** (🔃): Pushes local changes TO AniList, then pulls latest FROM AniList
- **Refresh button** (🔄): Only pulls latest data FROM AniList
- Both update local storage and reload UI

## Implementation Details

### Auto-Fetch on Startup

**Location**: `lib/features/anime_list/presentation/pages/anime_list_page.dart`

```dart
void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this);
  _anilist = AniListService(widget.authService);
  WidgetsBinding.instance.addObserver(this);
  _loadData(); // Load from local storage first
  _fetchLatestFromAniList(); // Then fetch from AniList in background
}
```

### Fetch Method

```dart
Future<void> _fetchLatestFromAniList({bool showNotification = false}) async {
  // 1. Get user
  final user = widget.localStorageService.getUser();
  
  // 2. Fetch anime list from AniList
  final animeListData = await _anilist.fetchAnimeList(user.id);
  await widget.localStorageService.saveAnimeList(animeList);
  
  // 3. Fetch manga/novel list from AniList
  final mangaListData = await _anilist.fetchMangaList(user.id);
  await widget.localStorageService.saveMangaList(mangaList);
  
  // 4. Reload UI
  await _loadData();
  
  // 5. Download cover images in background
  _downloadCoverImagesInBackground();
  
  // 6. Show notification (optional)
  if (showNotification) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### Updated Sync Flow

```dart
Future<void> _syncData() async {
  // 1. Push local changes to AniList
  await _syncWithAniList(isAutoSync: false);
  
  // 2. Pull latest data from AniList
  await _fetchLatestFromAniList(showNotification: false);
}
```

## UI Updates

### App Bar Buttons

Before:
- Search (🔍)
- Filter (☰)
- Global Search (🌐)
- Profile (👤)
- **Sync (🔃)**

After:
- Search (🔍)
- Filter (☰)
- Global Search (🌐)
- Profile (👤)
- **Refresh (🔄)** ← NEW
- **Sync (🔃)**

### Button Behaviors

| Button | Action | Cooldown | Shows Notification | Use Case |
|--------|--------|----------|-------------------|----------|
| **Refresh** | Pull data FROM AniList | None | Yes | Get latest custom lists/updates |
| **Sync** | Push TO + Pull FROM AniList | 30 seconds | Yes | Sync local changes + updates |

## Data Flow

### On App Start:
```
App Launches
    ↓
Load from Local Storage (instant)
    ↓
Display UI with local data
    ↓
Fetch from AniList (background)
    ↓
Update Local Storage
    ↓
Reload UI with fresh data
```

### On Manual Refresh:
```
User taps Refresh button
    ↓
Show "Updating..." notification
    ↓
Fetch from AniList API
    ↓
Save to Local Storage
    ↓
Reload UI
    ↓
Show "✓ Data updated" notification
```

### On Sync:
```
User taps Sync button
    ↓
Show "Syncing..." notification
    ↓
Push local changes to AniList (modified entries)
    ↓
Fetch latest from AniList (all data)
    ↓
Save to Local Storage
    ↓
Reload UI
    ↓
Show "✓ Synced successfully" notification
```

## Benefits

### 1. **Always Up-to-Date**
- Custom lists created on AniList website appear immediately on next app start
- Changes made on other devices sync automatically
- No manual refresh needed in most cases

### 2. **Fast Initial Load**
- App loads local data instantly (no wait)
- Updates happen in background
- Smooth user experience

### 3. **Graceful Degradation**
- If fetch fails, local data is still available
- Non-critical - app continues to work
- Errors logged but not shown to user (unless manual refresh)

### 4. **Network Efficiency**
- Only fetches when needed (app start, manual refresh, sync)
- No continuous polling
- Respects rate limits

## Use Cases

### Scenario 1: Custom Lists Created on Website
1. User creates custom list "Top 10" on AniList website
2. Adds anime to that list
3. Opens MiyoList app
4. **Result**: Custom lists automatically loaded on app start

### Scenario 2: Changes from Other Devices
1. User updates score on phone
2. Opens app on desktop
3. **Result**: Score updated automatically

### Scenario 3: Manual Refresh
1. User makes changes on website
2. App is already open
3. User taps Refresh button
4. **Result**: Changes pulled immediately

## Error Handling

### Network Failure
```dart
catch (e) {
  debugPrint('⚠️ Background fetch failed (non-critical): $e');
  // Continue execution - local data still available
  
  if (showNotification && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### No User Found
```dart
final user = widget.localStorageService.getUser();
if (user == null) {
  debugPrint('⚠️ No user found, skipping AniList fetch');
  return;
}
```

## Future Enhancements

### Priority 1: Smart Refresh
- Check for actual changes before reloading UI
- Compare timestamps to skip unnecessary updates
- Show "No new changes" message

### Priority 2: Periodic Background Sync
- Auto-refresh every X minutes when app is active
- Configurable interval in settings
- Pause when app is in background

### Priority 3: Offline Queue
- Queue changes when offline
- Sync when connection restored
- Show queue status in UI

### Priority 4: Selective Sync
- Sync only specific list (anime/manga/novels)
- Skip unchanged data
- Faster sync for large lists

### Priority 5: Push Notifications
- Notify when custom list updated by collaborators
- Alert for new episodes/chapters
- Requires backend service

## Testing Checklist

### Auto-Fetch on Start
- [ ] App loads local data first (fast)
- [ ] Background fetch starts automatically
- [ ] UI updates after fetch completes
- [ ] Works on first app launch
- [ ] Works on subsequent launches

### Manual Refresh
- [ ] Refresh button visible in app bar
- [ ] Shows "Updating..." notification
- [ ] Fetches latest data from AniList
- [ ] Shows success notification
- [ ] Shows error notification on failure
- [ ] No cooldown period

### Sync Button
- [ ] Pushes local changes first
- [ ] Pulls latest data second
- [ ] Shows sync notification
- [ ] Respects 30-second cooldown
- [ ] Updates UI with fresh data

### Error Handling
- [ ] Works without internet (uses local data)
- [ ] Handles API errors gracefully
- [ ] Logs errors to console
- [ ] Doesn't crash app on failure
- [ ] Shows user-friendly error messages (manual refresh only)

### Custom Lists Integration
- [ ] Custom lists fetched from AniList
- [ ] Custom lists appear in Edit Entry dialog
- [ ] New lists created on website appear in app
- [ ] Deleted lists removed from app
- [ ] Changes sync bidirectionally

## Known Limitations

1. **No Change Detection** - Always fetches full list even if nothing changed
2. **No Incremental Updates** - Can't fetch only new/modified entries
3. **No Conflict Resolution** - Last write wins if changes on multiple devices
4. **No Offline Indicator** - User doesn't know if data is stale
5. **No Background Sync** - Only syncs when app is active/opened

## Performance Notes

### Network Usage
- **On App Start**: ~2-3 API requests (user + anime + manga lists)
- **On Refresh**: Same as app start
- **On Sync**: Additional requests for each modified entry

### Storage Impact
- Local storage updated on every fetch
- Old data overwritten completely
- No differential updates

### UI Responsiveness
- Initial load: <100ms (from local storage)
- Background fetch: 1-3 seconds (network dependent)
- No UI blocking during fetch

## Conclusion

This implementation ensures users always have the latest data from AniList, particularly important for custom lists which previously weren't loaded until manual sync. The auto-fetch on startup combined with the manual refresh button provides both convenience and control.
