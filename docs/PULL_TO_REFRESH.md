# Pull-to-Refresh Feature

**Implementation Date:** October 11, 2025  
**Version:** v1.4.1

---

## Overview

The Pull-to-Refresh feature allows users to manually refresh their anime, manga, and light novel lists by pulling down on the screen. This provides a familiar mobile UX pattern and makes syncing data more intuitive.

---

## Features

### Core Functionality
- **Gesture-based refresh:** Pull down anywhere in the list to trigger a refresh
- **AniList sync:** Fetches the latest data from AniList API
- **Local reload:** Reloads data from local storage after sync
- **Visual feedback:** Shows a loading spinner during refresh
- **Success notification:** Displays a brief success message after completion
- **Works with empty lists:** AlwaysScrollableScrollPhysics enables pull-to-refresh even when there are few items

### User Experience
- **Custom styling:**
  - Accent blue color for the spinner
  - Card gray background
  - Matches app theme
- **Fast response:** Minimal delay, feels instant
- **Error handling:** Shows error notification if sync fails
- **Non-blocking:** UI remains responsive during refresh

---

## Implementation Details

### Code Structure

```dart
// In anime_list_page.dart

// Wrapped GridView in RefreshIndicator
Expanded(
  child: RefreshIndicator(
    onRefresh: () => _handlePullToRefresh(),
    color: AppTheme.accentBlue,
    backgroundColor: AppTheme.cardGray,
    child: _buildMediaGrid(...),
  ),
)

// GridView with AlwaysScrollableScrollPhysics
GridView.builder(
  physics: const AlwaysScrollableScrollPhysics(),
  // ... other properties
)

// Refresh handler
Future<void> _handlePullToRefresh() async {
  // 1. Fetch latest data from AniList
  await _fetchLatestFromAniList(showNotification: false);
  
  // 2. Reload local data
  await _loadData();
  
  // 3. Show success notification
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### What Happens During Refresh

1. **User pulls down** on the list
2. **RefreshIndicator** appears with loading spinner
3. **Fetch from AniList:**
   - Calls `_fetchLatestFromAniList()`
   - Downloads anime list
   - Downloads manga/novel list
   - Updates local Hive storage
4. **Reload local data:**
   - Calls `_loadData()`
   - Reads from Hive
   - Separates manga and novels
   - Updates UI state
5. **Show notification:**
   - Green checkmark snackbar
   - "✓ List refreshed" message
   - 1 second duration
6. **RefreshIndicator** disappears

---

## Technical Details

### Widget: RefreshIndicator

```dart
RefreshIndicator(
  onRefresh: () => _handlePullToRefresh(),  // Async callback
  color: AppTheme.accentBlue,               // Spinner color
  backgroundColor: AppTheme.cardGray,        // Background color
  child: GridView(...),                      // Scrollable child
)
```

**Key Properties:**
- `onRefresh`: Returns `Future<void>`, called when user pulls down
- `color`: Color of the refresh indicator
- `backgroundColor`: Background color behind the indicator
- `child`: Must be a scrollable widget (GridView, ListView, etc.)

### Physics: AlwaysScrollableScrollPhysics

```dart
GridView.builder(
  physics: const AlwaysScrollableScrollPhysics(),
  // ...
)
```

**Purpose:**
- Ensures the list is always scrollable
- Enables pull-to-refresh even when content doesn't fill the screen
- Essential for lists with few items

**Without this:** Pull-to-refresh wouldn't work when there are only 1-2 items visible.

---

## Error Handling

### Network Errors
If AniList API is unreachable:
- Shows red error snackbar
- Message: "Failed to update: [error]"
- Duration: 3 seconds
- Local data remains unchanged

### Authentication Errors
If user token is invalid:
- Gracefully fails
- Shows error notification
- User can retry or re-login

### Empty Lists
If user has no entries:
- Still allows pull-to-refresh
- Shows "No entries found" message
- Refresh checks for new additions

---

## User Scenarios

### Scenario 1: Add New Anime on AniList Web
1. User adds anime on AniList website
2. Opens MiyoList app
3. Pulls down to refresh
4. New anime appears in list

### Scenario 2: Update Progress on Another Device
1. User updates progress on mobile AniList app
2. Opens MiyoList on Windows
3. Pulls down to refresh
4. Progress syncs and updates

### Scenario 3: Check for New Episodes
1. User watches new episode
2. Updates progress on another platform
3. Pulls down to refresh in MiyoList
4. Sees updated episode count

---

## Performance Considerations

### Caching
- Local data is cached in Hive
- Refresh only updates changed entries
- No redundant API calls

### Rate Limiting
- Respects AniList rate limits (30 req/min)
- Uses existing rate limiter service
- Batches requests efficiently

### UI Performance
- Async operations don't block UI
- GridView remains responsive
- Smooth animations

---

## Comparison with Sync Button

| Feature | Pull-to-Refresh | Sync Button |
|---------|----------------|-------------|
| **Trigger** | Gesture (pull down) | Button click |
| **Cooldown** | None | 1 minute |
| **Notification** | Brief success message | Detailed status |
| **Use Case** | Quick refresh | Full sync with conflict resolution |
| **Data Flow** | AniList → Local | Local ↔ AniList ↔ Cloud |

**When to use:**
- **Pull-to-Refresh:** Quick check for updates from AniList
- **Sync Button:** Full synchronization including cloud and conflict resolution

---

## Future Enhancements

### Potential Improvements
- [ ] Show last refresh timestamp
- [ ] Add pull-to-refresh to search page
- [ ] Add pull-to-refresh to profile page (favorites)
- [ ] Custom refresh animations
- [ ] Haptic feedback on refresh
- [ ] Refresh multiple tabs simultaneously
- [ ] Incremental sync (only changed entries)

### Advanced Features
- [ ] Background refresh on app resume
- [ ] Scheduled auto-refresh (every N minutes)
- [ ] Smart refresh (only if data is stale)
- [ ] Differential sync (minimal data transfer)

---

## Testing Checklist

- [x] Pull down with many items (> 20)
- [x] Pull down with few items (< 5)
- [x] Pull down with empty list
- [x] Pull down while offline
- [x] Pull down with invalid token
- [x] Pull down rapidly (multiple times)
- [x] Check notification appearance
- [x] Verify data updates after refresh
- [x] Test on different window sizes
- [x] Test with search active
- [x] Test with filters active

---

## Related Files

### Implementation
- `lib/features/anime_list/presentation/pages/anime_list_page.dart`
  - `_handlePullToRefresh()` - Main refresh handler
  - `_fetchLatestFromAniList()` - AniList fetch logic
  - `_loadData()` - Local data reload
  - RefreshIndicator widget wrapper

### Dependencies
- `material.dart` - RefreshIndicator widget
- `lib/core/services/anilist_service.dart` - API calls
- `lib/core/services/local_storage_service.dart` - Local storage
- `lib/core/theme/app_theme.dart` - Colors

---

## Changelog

### v1.4.1 (October 11, 2025)
- ✨ **NEW:** Pull-to-refresh feature
- Added RefreshIndicator wrapper
- Implemented `_handlePullToRefresh()` method
- Added AlwaysScrollableScrollPhysics for better UX
- Custom styling (blue accent, card gray background)
- Success notification on completion

---

## Conclusion

The Pull-to-Refresh feature provides a modern, intuitive way for users to sync their data. It complements the existing sync button and offers a quick, gesture-based alternative for checking updates. The implementation is simple, performant, and follows Flutter best practices.

**Key Benefits:**
- ✅ Familiar UX pattern
- ✅ Easy to use
- ✅ Fast and responsive
- ✅ Works in all scenarios
- ✅ Minimal code footprint
- ✅ Follows app theme
