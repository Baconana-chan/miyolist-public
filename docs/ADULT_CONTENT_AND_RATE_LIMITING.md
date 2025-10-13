# Adult Content Filtering & Rate Limiting

## Overview

MiyoList now includes two important features to improve the user experience and comply with platform guidelines:

1. **Adult Content Filtering** - Respects user's AniList settings for 18+ content
2. **Rate Limiting** - Prevents API spam and respects AniList's 30 requests/minute limit

---

## 🔞 Adult Content Filtering

### How It Works

When a user logs in, MiyoList fetches their AniList profile settings, including the `displayAdultContent` preference. This setting is saved locally and used to filter out adult titles from lists and search results.

### Implementation

#### User Model Update

```dart
@HiveField(7)
final bool displayAdultContent;
```

The user's preference is stored in:
- **Source**: AniList API (`options.displayAdultContent`)
- **Local Storage**: Hive (UserModel, field 7)
- **Default**: `false` (hide adult content by default)

#### Anime/Manga Model Update

```dart
@HiveField(14)
final bool isAdult;
```

Each anime/manga title has an `isAdult` flag:
- **Source**: AniList API (`media.isAdult`)
- **Local Storage**: Hive (AnimeModel, field 14)
- **Default**: `false`

### Filtering Logic

```dart
List<MediaListEntry> _filterByStatus(List<MediaListEntry> list, String status) {
  var filtered = list.where((entry) => entry.status == status).toList();
  
  // Filter adult content if user has it disabled
  if (!_displayAdultContent) {
    filtered = filtered.where((entry) {
      return entry.media?.isAdult != true;
    }).toList();
  }
  
  return filtered;
}
```

### User Flow

```
1. User logs in via AniList OAuth
   ↓
2. App fetches user profile with options.displayAdultContent
   ↓
3. Setting saved to Hive (displayAdultContent field)
   ↓
4. When loading lists:
   - If displayAdultContent = true → Show all titles
   - If displayAdultContent = false → Filter out isAdult titles
   ↓
5. User sees filtered results
```

### AniList Settings

Users can change this setting on AniList:

1. Go to **AniList Settings** → **Account**
2. Find **"18+ Content"** checkbox
3. Check to enable, uncheck to disable
4. Save settings
5. Re-login to MiyoList to sync new preference

### Benefits

#### For Google Play Compliance
- ✅ Respects user's content preferences
- ✅ Hides adult content by default
- ✅ User has explicit control via AniList
- ✅ No adult content shown to users who didn't opt-in

#### For PC Users
- ✅ Cleaner browsing experience
- ✅ Safe for work viewing
- ✅ Respects personal preferences
- ✅ No accidental adult content

---

## ⏱️ Rate Limiting

### Background

AniList has API rate limits to protect their infrastructure:

- **Normal limit**: 90 requests per minute
- **Current limit**: 30 requests per minute (temporarily reduced)
- **Documentation**: https://docs.anilist.co/guide/rate-limiting

### Implementation

#### RateLimiter Class

```dart
class RateLimiter {
  static const int maxRequestsPerMinute = 30;
  static const Duration timeWindow = Duration(minutes: 1);
  
  // Track request timestamps
  final List<DateTime> _requestTimestamps = [];
  
  // Execute request with rate limiting
  Future<T> execute<T>(Future<T> Function() request) async {
    await waitForSlot();
    recordRequest();
    return await request();
  }
}
```

### Features

#### 1. Automatic Request Tracking

```dart
// Every API call is tracked
final result = await _rateLimiter.execute(() async {
  return await _client.query(...);
});
```

#### 2. Smart Waiting

```dart
// If limit reached, automatically waits
if (waitTime > 0) {
  print('Rate limit reached. Waiting ${waitTime}ms...');
  await Future.delayed(Duration(milliseconds: waitTime + 100));
}
```

#### 3. Request Statistics

```dart
Map<String, dynamic> getRateLimiterStats() {
  return {
    'currentRequests': _rateLimiter.currentRequestCount,
    'remainingRequests': _rateLimiter.remainingRequests,
    'maxRequestsPerMinute': 30,
    'waitTimeMs': _rateLimiter.getWaitTimeMs(),
  };
}
```

### How It Works

#### Request Flow

```
User Action (e.g., load lists)
    ↓
App calls AniList API
    ↓
RateLimiter checks current count
    ↓
┌─────────────────────┬─────────────────────┐
│ Under 30 requests?  │ Over 30 requests?   │
│ ✅ Execute now      │ ⏳ Wait for slot    │
└──────────┬──────────┴──────────┬──────────┘
           │                     │
           ↓                     ↓
    Record timestamp      Calculate wait time
           │                     │
           ↓                     ↓
    Return result         Wait + Execute
```

#### Time Window Management

```
Minute 1: [Request1, Request2, ..., Request30]  ← Full
         ↓ Wait until Request1 expires
Minute 2: [Request2, ..., Request30, Request31] ← Available slot
```

#### Automatic Cleanup

Old requests are automatically removed:

```dart
void _cleanOldRequests() {
  final now = DateTime.now();
  final cutoffTime = now.subtract(timeWindow);
  
  _requestTimestamps.removeWhere(
    (timestamp) => timestamp.isBefore(cutoffTime)
  );
}
```

### Usage in AniListService

All GraphQL queries and mutations are wrapped:

```dart
// Before (no rate limiting)
final result = await _client.query(QueryOptions(...));

// After (with rate limiting)
final result = await _rateLimiter.execute(() async {
  return await _client.query(QueryOptions(...));
});
```

### Benefits

#### Prevents API Spam
- ✅ Automatic request throttling
- ✅ Protects AniList infrastructure
- ✅ Prevents 429 (Too Many Requests) errors
- ✅ Smooth user experience

#### Smart Behavior
- ✅ No unnecessary delays
- ✅ Only waits when needed
- ✅ Transparent to user
- ✅ Predictable performance

#### Developer Friendly
- ✅ Easy to integrate
- ✅ No manual counting needed
- ✅ Statistics available
- ✅ Testable and maintainable

---

## 🧪 Testing

### Adult Content Filtering

**Test Case 1: User with 18+ Disabled**
```
1. On AniList, disable "18+ Content"
2. Login to MiyoList
3. View anime/manga lists
4. Verify: No adult titles appear
```

**Test Case 2: User with 18+ Enabled**
```
1. On AniList, enable "18+ Content"
2. Login to MiyoList
3. View anime/manga lists
4. Verify: Adult titles appear (if in user's list)
```

**Test Case 3: Setting Change**
```
1. Login with 18+ disabled
2. Verify adult content hidden
3. On AniList, enable 18+ content
4. Logout and re-login to MiyoList
5. Verify adult content now visible
```

### Rate Limiting

**Test Case 1: Normal Usage**
```
1. Open app and load lists (< 30 requests)
2. Verify: No delays, smooth loading
3. Check console: No rate limit messages
```

**Test Case 2: Heavy Usage**
```
1. Trigger multiple API calls quickly
2. After 30 requests, check console
3. Verify: "Rate limit reached. Waiting..." message
4. Verify: App continues working after wait
```

**Test Case 3: Statistics**
```dart
// In debug mode
final stats = anilistService.getRateLimiterStats();
print(stats);
// Output: {currentRequests: 25, remainingRequests: 5, ...}
```

---

## 📊 Technical Details

### Database Schema Changes

#### UserModel (Hive TypeId: 0)

```dart
Field 0: int id
Field 1: String name
Field 2: String? avatar
Field 3: String? bannerImage
Field 4: String? about
Field 5: DateTime? createdAt
Field 6: DateTime? updatedAt
Field 7: bool displayAdultContent  ← NEW!
```

#### AnimeModel (Hive TypeId: 1)

```dart
Field 0: int id
Field 1: String titleRomaji
Field 2: String? titleEnglish
Field 3: String? titleNative
Field 4: String? coverImage
Field 5: String? bannerImage
Field 6: int? episodes
Field 7: String? status
Field 8: String? format
Field 9: String? season
Field 10: int? seasonYear
Field 11: double? averageScore
Field 12: String? description
Field 13: List<String>? genres
Field 14: bool isAdult  ← NEW!
```

### GraphQL Query Updates

#### User Query (Added options)

```graphql
query {
  Viewer {
    id
    name
    avatar { large }
    bannerImage
    about
    createdAt
    updatedAt
    options {
      displayAdultContent  # NEW!
    }
  }
}
```

#### Media Query (Added isAdult)

```graphql
query {
  MediaListCollection(...) {
    lists {
      entries {
        media {
          id
          title { ... }
          # ... other fields
          isAdult  # NEW!
        }
      }
    }
  }
}
```

### Performance Impact

#### Adult Content Filtering
- **Memory**: Negligible (+1 bool per user, +1 bool per media)
- **CPU**: Minimal (simple boolean check during filter)
- **Network**: None (uses existing API data)

#### Rate Limiting
- **Memory**: ~240 bytes (30 timestamps × 8 bytes)
- **CPU**: Minimal (list operations)
- **Network**: Reduces requests, prevents errors

---

## 🔧 Configuration

### Adjust Rate Limit

To change the rate limit (e.g., when AniList restores 90 req/min):

```dart
// lib/core/utils/rate_limiter.dart

class RateLimiter {
  static const int maxRequestsPerMinute = 90; // Change here
  // ...
}
```

### Disable Adult Filtering (Testing Only)

```dart
// lib/features/anime_list/presentation/pages/anime_list_page.dart

// Temporarily show all content
if (!_displayAdultContent && false) {  // Add && false
  filtered = filtered.where((entry) {
    return entry.media?.isAdult != true;
  }).toList();
}
```

**⚠️ Warning**: Never deploy with adult filtering disabled!

---

## 📝 Future Enhancements

### Adult Content Filtering

- [ ] In-app toggle to sync with AniList setting
- [ ] Blur adult content covers instead of hiding
- [ ] Separate filters for different content levels
- [ ] Content warning indicators
- [ ] Age verification flow

### Rate Limiting

- [ ] Adaptive rate limiting based on API headers
- [ ] Request queue with priorities
- [ ] Batch requests to reduce API calls
- [ ] Cache-first strategy
- [ ] Background sync with smart throttling

---

## 🎯 Best Practices

### For Developers

**DO:**
- ✅ Use `_rateLimiter.execute()` for all API calls
- ✅ Respect user's displayAdultContent setting
- ✅ Test with both adult content enabled/disabled
- ✅ Handle rate limit errors gracefully

**DON'T:**
- ❌ Bypass rate limiter for "urgent" requests
- ❌ Cache adult content visibility client-side
- ❌ Make parallel API calls without checking limit
- ❌ Ignore isAdult flag in search results

### For Users

**To Hide Adult Content:**
1. Go to AniList → Settings → Account
2. Uncheck "18+ Content"
3. Save and re-login to MiyoList

**To Show Adult Content:**
1. Go to AniList → Settings → Account
2. Check "18+ Content"
3. Save and re-login to MiyoList

---

## 🆘 Troubleshooting

### Adult Content Not Filtering

**Problem**: Adult titles still visible with setting disabled

**Solutions**:
```bash
1. Check user's AniList settings
2. Logout and re-login to MiyoList
3. Clear app data if persists
4. Verify isAdult field in API response
```

### Rate Limit Errors

**Problem**: Getting 429 errors from AniList

**Solutions**:
```bash
1. Check rate limiter is initialized
2. Verify all API calls use execute()
3. Check console for rate limit messages
4. Wait 60 seconds and try again
```

### Slow Performance

**Problem**: App feels sluggish

**Check**:
```dart
final stats = anilistService.getRateLimiterStats();
print(stats['waitTimeMs']); // Should be 0 most of the time
```

If wait time is high frequently:
- Reduce concurrent API calls
- Implement better caching
- Use batch requests

---

## 📖 References

- **AniList Rate Limiting**: https://docs.anilist.co/guide/rate-limiting
- **AniList GraphQL Schema**: https://anilist.github.io/ApiV2-GraphQL-Docs/
- **Google Play Content Policy**: https://support.google.com/googleplay/android-developer/answer/9878810

---

## ✅ Summary

### What Was Added

1. **Adult Content Filtering**
   - `displayAdultContent` field in UserModel
   - `isAdult` field in AnimeModel
   - Filtering logic in AnimeListPage
   - Respects AniList user settings

2. **Rate Limiting**
   - RateLimiter utility class
   - 30 requests per minute limit
   - Automatic request tracking
   - Smart waiting system
   - Integrated into AniListService

### Benefits

- ✅ Google Play compliant
- ✅ Better user experience
- ✅ Prevents API abuse
- ✅ Respects user preferences
- ✅ Professional app behavior

### Next Steps

1. Test both features thoroughly
2. Monitor rate limiter stats
3. Gather user feedback
4. Consider future enhancements

---

**Status**: ✅ Implemented and Ready for Testing
**Version**: 1.1.0
**Date**: 2024
