# Theme Change Performance Fix

## Issue
When user changes theme in settings, the entire app rebuilds, including `AnimeListPage`. This triggered `initState()` which called `_fetchLatestFromAniList()`, causing unnecessary API requests to AniList.

**Result:** Every theme change = new API request (wasteful, slow)

## Solution
Implemented static fetch cooldown mechanism with 5-minute window.

### Implementation Details

**Added static variables:**
```dart
static DateTime? _lastFetchTime;
static const _fetchCooldown = Duration(minutes: 5);
```

**Modified initState:**
```dart
final now = DateTime.now();
if (_lastFetchTime == null || now.difference(_lastFetchTime!) > _fetchCooldown) {
  _fetchLatestFromAniList(); // Only if cooldown passed
  _lastFetchTime = now;
} else {
  // Skip fetch, use cached data
  debugPrint('⏳ Skipping AniList fetch, cooldown active');
}
```

**Manual refresh handling:**
```dart
Future<void> _fetchLatestFromAniList({bool showNotification = false}) async {
  // Update timestamp when manually triggered
  if (showNotification) {
    _lastFetchTime = DateTime.now();
  }
  // ... rest of method
}
```

## Benefits

✅ **No redundant API calls** - Theme changes don't trigger fetches  
✅ **Faster theme switching** - Instant UI update without waiting for API  
✅ **Rate limit protection** - Reduced API requests  
✅ **Better UX** - Smoother experience when changing themes  
✅ **Preserves functionality** - Manual sync button still works  

## Technical Details

### Why Static?
Variables are `static` so they persist across widget rebuilds. When theme changes:
1. `AnimeListPage` widget is destroyed
2. New `AnimeListPage` widget is created
3. Static `_lastFetchTime` survives and prevents re-fetch

### Cooldown Period
- **5 minutes** - Reasonable balance between freshness and efficiency
- User can always manually sync if needed
- Background sync on app pause still works

### Edge Cases Handled
- ✅ First app load → Always fetches
- ✅ Manual sync button → Always fetches (updates timestamp)
- ✅ Theme change → Skips if within cooldown
- ✅ App restart → Static cleared, allows new fetch
- ✅ Background sync → Independent mechanism, works as before

## Testing

**Before fix:**
```
1. Open app → Fetch from AniList ✅
2. Change theme (Dark → Light) → Fetch from AniList ❌ (unnecessary)
3. Change theme (Light → Carrot) → Fetch from AniList ❌ (unnecessary)
Result: 3 API calls in seconds
```

**After fix:**
```
1. Open app → Fetch from AniList ✅
2. Change theme (Dark → Light) → Skip fetch, use cache ✅
3. Change theme (Light → Carrot) → Skip fetch, use cache ✅
Result: 1 API call, instant theme changes
```

## Related Files

- `lib/features/anime_list/presentation/pages/anime_list_page.dart`
- `docs/THEME_SYSTEM.md`

## Version

- **Fixed in:** v1.4.0
- **Date:** October 11, 2025
