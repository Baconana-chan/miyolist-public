# AniList Client Initialization Fix

## Overview
Fixed "AniList client not initialized" error when opening public profile pages from the activity feed.

## Problem
When navigating to MediaDetailsPage from activity feed (or other external navigation), the AniListService client was accessed before initialization:

```
Error: Exception: AniList client not initialized. Call _ensureInitialized() first.
Stack trace:
#0  AniListService.client (anilist_service.dart:39)
#1  _MediaDetailsPageState._initializeServices (media_details_page.dart:62)
```

### Root Cause
```dart
// OLD CODE
void _initializeServices() {
  _anilist = AniListService(_authService);
  _socialService = SocialService(_anilist.client); // ❌ Client not ready!
}
```

The `_anilist.client` getter was called immediately after construction, but the GraphQL client is only created when `_ensureInitialized()` is called (which requires async/await).

## Solution

### 1. Added Public Initialization Method
Added a public `ensureInitialized()` method to `AniListService`:

```dart
// anilist_service.dart
/// Public method to ensure the client is initialized
/// Can be called externally when needed
Future<void> ensureInitialized() async {
  await _ensureInitialized();
}
```

### 2. Made Services Initialization Async
Changed `_initializeServices()` to be async and call initialization before accessing client:

```dart
// media_details_page.dart
Future<void> _initializeServices() async {
  _localStorage = widget.localStorageService ?? LocalStorageService();
  _supabase = widget.supabaseService ?? SupabaseService();
  _authService = AuthService();
  _anilist = widget.anilistService ?? AniListService(_authService);
  
  // ✅ Ensure AniList client is initialized before creating SocialService
  await _anilist.ensureInitialized();
  _socialService = SocialService(_anilist.client);

  _searchService = MediaSearchService(
    localStorage: _localStorage,
    supabase: _supabase,
    anilist: _anilist,
  );

  _loadCurrentUserId();
}
```

### 3. Updated initState() Flow
Changed `initState()` to properly handle async initialization:

```dart
@override
void initState() {
  super.initState();
  // Initialize services and load data asynchronously
  _initializeAndLoad();
}

Future<void> _initializeAndLoad() async {
  await _initializeServices();
  _loadMediaDetails();
}
```

## Files Modified
1. `lib/core/services/anilist_service.dart` - Added public `ensureInitialized()` method
2. `lib/features/media_details/presentation/pages/media_details_page.dart` - Made initialization async

## Technical Details

### Initialization Flow (Before)
```
initState()
  ↓
_initializeServices() [sync]
  ↓
AniListService() constructor
  ↓
_socialService = SocialService(_anilist.client) ❌ CRASH
```

### Initialization Flow (After)
```
initState()
  ↓
_initializeAndLoad() [async fire-and-forget]
  ↓
await _initializeServices()
  ↓
AniListService() constructor
  ↓
await _anilist.ensureInitialized() ✅ Client ready
  ↓
_socialService = SocialService(_anilist.client) ✅ Works
```

## Why This Works

### Fire-and-Forget Pattern
The async initialization uses a "fire-and-forget" pattern in `initState()`:
- `initState()` cannot be async (Flutter requirement)
- We call `_initializeAndLoad()` without awaiting
- Flutter handles the async operation in the background
- UI shows loading state until data is ready

### Lazy Initialization Alternative (Not Used)
We could have made `_socialService` lazily initialized:
```dart
SocialService get _socialService {
  _cachedSocialService ??= SocialService(_anilist.client);
  return _cachedSocialService!;
}
```
But this would still crash on first access if client isn't initialized.

## Testing
- ✅ Navigate to MediaDetailsPage from activity feed
- ✅ Navigate to MediaDetailsPage from search
- ✅ Navigate to MediaDetailsPage from anime/manga list
- ✅ Navigate to public profile from activity feed
- ✅ No "client not initialized" errors

## Related Issues
This fix also prevents similar issues in:
- Public profile pages
- Activity feed interactions
- Any page that uses SocialService

## Notes
- The `ensureInitialized()` method is idempotent (safe to call multiple times)
- First call initializes the client, subsequent calls return immediately
- The client uses the access token from AuthService
- If no token is available, initialization throws an exception (expected behavior for auth-required features)
