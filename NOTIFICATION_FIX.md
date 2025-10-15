# Notification System Fix (v1.1.0-dev)

## Overview
Fixed critical errors in notification system related to new AniList notification types (forum thread likes and direct messages).

## Issues Fixed

### 1. ❌ Type Cast Error: `type 'Null' is not a subtype of type 'int' in type cast`

**Root Cause:**
- `createdAt` field in GraphQL response could be `null` for some notification types
- Code was forcefully casting to `int` without null check: `(json['createdAt'] as int)`

**Solution:**
Added safe parsing in `AniListNotification.fromJson()`:
```dart
// Safe parsing of createdAt - handle both int and null
DateTime createdAt;
final createdAtValue = json['createdAt'];
if (createdAtValue != null) {
  createdAt = DateTime.fromMillisecondsSinceEpoch(
    (createdAtValue as int) * 1000,
  );
} else {
  createdAt = DateTime.now(); // Fallback to current time
}
```

### 2. ❌ Missing Notification Type: `THREAD_LIKE`

**Problem:**
- New notification type from AniList: when someone likes your forum thread
- Example: "or353 liked your forum thread, MiyoList: AL app for Windows and Android"
- GraphQL query didn't include `ThreadLikeNotification` fragment
- No case handling in model methods

**Solution:**
- Added `ThreadLikeNotification` fragment to GraphQL query in `notification_service.dart`:
```graphql
... on ThreadLikeNotification {
  id
  type
  context
  createdAt
  thread {
    id
    title
  }
  user {
    id
    name
    avatar {
      large
    }
  }
}
```

- Added case handling in `notification.dart`:
  - `getTypeIcon()`: Returns '💬' for `THREAD_LIKE`
  - `getTypeName()`: Returns 'Forum' for `THREAD_LIKE`
  - `getFormattedText()`: Returns `"${userName ?? 'Someone'} liked your forum thread${threadTitle != null ? ', $threadTitle' : ''}."`

### 3. ❌ Missing User Name in Messages: `ACTIVITY_MESSAGE`

**Problem:**
- Activity messages showed: "das sent you a message."
- But username was not properly displayed, showing incomplete text
- `ACTIVITY_MESSAGE` type was already in GraphQL but not handled in model

**Solution:**
- Added `ACTIVITY_MESSAGE` to all switch cases in `notification.dart`:
  - `getTypeIcon()`: Returns '❤️' (grouped with activity types)
  - `getTypeName()`: Returns 'Activity'
  - `getFormattedText()`: Returns `"${userName ?? 'Someone'} sent you a message."`

## Files Modified

### `lib/core/services/notification_service.dart`
- **Line ~233**: Added `ThreadLikeNotification` GraphQL fragment
- Ensures forum thread likes are properly fetched from AniList API

### `lib/core/models/notification.dart`
- **Lines 48-62**: Rewrote `fromJson()` with safe `createdAt` parsing
- **Lines 120-139**: Added `ACTIVITY_MESSAGE` and `THREAD_LIKE` to `getTypeIcon()`
- **Lines 143-166**: Added `ACTIVITY_MESSAGE` and `THREAD_LIKE` to `getTypeName()`
- **Lines 170-204**: Added `ACTIVITY_MESSAGE` and `THREAD_LIKE` to `getFormattedText()`

## Testing Recommendations

### Test Case 1: Forum Thread Like
1. Create a forum thread on AniList
2. Have someone like your thread
3. Check notifications in MiyoList
4. ✅ Should display: "username liked your forum thread, Thread Title."
5. ✅ Should show forum icon (💬)
6. ✅ Clicking should open thread URL

### Test Case 2: Activity Message
1. Have someone send you a direct message on AniList
2. Check notifications in MiyoList
3. ✅ Should display: "username sent you a message."
4. ✅ Should show activity icon (❤️)
5. ✅ Username should be visible (not null)

### Test Case 3: Null createdAt Handling
1. Fetch notifications with various types
2. ✅ No type cast errors should occur
3. ✅ All notifications should have valid timestamps
4. ✅ Fallback to current time if createdAt is null

## Supported Notification Types (Complete List)

### 📺 Airing
- `AIRING` - New episode aired

### ❤️ Activity
- `ACTIVITY_LIKE` - Someone liked your activity
- `ACTIVITY_REPLY` - Someone replied to your activity
- `ACTIVITY_REPLY_LIKE` - Someone liked your reply
- `ACTIVITY_MENTION` - Someone mentioned you
- `ACTIVITY_MESSAGE` - Someone sent you a message ✅ **FIXED**

### 💬 Forum
- `THREAD_COMMENT_LIKE` - Someone liked your comment
- `THREAD_COMMENT_REPLY` - Someone replied to your comment
- `THREAD_SUBSCRIBED` - New comment in subscribed thread
- `THREAD_COMMENT_MENTION` - Someone mentioned you in a thread
- `THREAD_LIKE` - Someone liked your thread ✅ **NEW**

### 👤 Follows
- `FOLLOWING` - Someone started following you

### 🎬 Media
- `RELATED_MEDIA_ADDITION` - New media added to site
- `MEDIA_DATA_CHANGE` - Media data updated
- `MEDIA_MERGE` - Media merged with another
- `MEDIA_DELETION` - Media deleted from site

## Future Improvements

### Potential Enhancements
1. **Better Error Handling**: Add try-catch in fromJson() for individual fields
2. **Logging**: Replace print statements with proper logger
3. **Notification Actions**: Add quick actions (like, reply, etc.) directly from notification
4. **Rich Formatting**: Parse markdown in notification context text
5. **Grouping**: Group similar notifications (e.g., "5 people liked your thread")

### Missing Notification Types (if any)
- Monitor AniList API updates for new notification types
- Check GraphQL schema periodically: https://anilist.github.io/ApiV2-GraphQL-Docs/

## Related Documentation
- [AniList API Docs](https://anilist.gitbook.io/anilist-apiv2-docs/)
- [GraphQL Notification Types](https://anilist.github.io/ApiV2-GraphQL-Docs/notificationunion.doc.html)
- Project notification service: `lib/core/services/notification_service.dart`
- Project notification model: `lib/core/models/notification.dart`

## Status
✅ **Fixed** - All notification types now properly handled
✅ **Tested** - Compilation successful, no errors
⏳ **Pending** - User testing with real notifications

---

**Date:** 2025-10-15  
**Version:** v1.1.0-dev  
**Author:** GitHub Copilot
