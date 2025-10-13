# 🎯 Smart Status Filtering Feature

**Date**: October 13, 2025  
**Feature**: Intelligent status filtering based on media release status  
**Status**: ✅ Implemented

---

## 📋 Overview

Implemented smart status filtering that limits available list statuses based on the actual release status of the anime/manga. This prevents users from selecting illogical statuses (e.g., marking an unreleased anime as "Watching").

---

## 🎨 Feature Details

### Status Logic

| Media Status | Available List Statuses | Reasoning |
|--------------|------------------------|-----------|
| **NOT_YET_RELEASED** (Анонсировано) | • Planning only | Can't watch what hasn't aired yet |
| **RELEASING** (Онгоинг) | • Planning<br>• Watching/Reading<br>• Paused<br>• Dropped | Currently airing - can't complete or rewatch yet |
| **FINISHED** (Завершено) | All statuses | Everything is available for completed series |
| **CANCELLED** (Отменено) | • Planning<br>• Dropped | Limited options for cancelled content |

### Examples

#### Scenario 1: Unreleased Anime
```
Title: "Attack on Titan Season 5" (NOT_YET_RELEASED)
Available: [Planning only]
Blocked: Watching, Completed, Rewatching, Paused, Dropped
Reason: "This title hasn't been released yet. You can only plan to watch it."
```

#### Scenario 2: Currently Airing
```
Title: "One Piece Episode 1100" (RELEASING)
Available: [Planning, Watching, Paused, Dropped]
Blocked: Completed, Rewatching
Reason: "This title is currently airing. Completed and Rewatching are unavailable."
```

#### Scenario 3: Completed Series
```
Title: "Fullmetal Alchemist: Brotherhood" (FINISHED)
Available: [All statuses]
Blocked: None
Reason: No restrictions
```

---

## 🔧 Technical Implementation

### Files Modified

1. **`edit_entry_dialog.dart`** - Main dialog widget
   - Added `mediaStatus` parameter
   - Implemented `_getAvailableStatuses()` method
   - Implemented `_getStatusHint()` method
   - Added validation in `initState()`
   - Added info hint UI

2. **`media_details_page.dart`** - Media details page
   - Passed `_media!.status` to both dialog calls
   - Updated `_showAddDialog()`
   - Updated `_showEditDialog()`

### Code Changes

#### New Parameter in EditEntryDialog
```dart
class EditEntryDialog extends StatefulWidget {
  final MediaListEntry entry;
  final bool isAnime;
  final Function(MediaListEntry) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToFavorites;
  final String? mediaStatus; // NEW: FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED

  const EditEntryDialog({
    super.key,
    required this.entry,
    required this.isAnime,
    required this.onSave,
    this.onDelete,
    this.onAddToFavorites,
    this.mediaStatus, // NEW: Optional parameter
  });
}
```

#### Status Filtering Logic
```dart
List<String> _getAvailableStatuses() {
  final baseStatuses = widget.isAnime ? _animeStatuses : _mangaStatuses;
  final mediaStatus = widget.mediaStatus;

  if (mediaStatus == null) return baseStatuses;

  switch (mediaStatus) {
    case 'NOT_YET_RELEASED':
      return ['PLANNING'];
    
    case 'RELEASING':
      return ['PLANNING', 'CURRENT', 'PAUSED', 'DROPPED'];
    
    case 'FINISHED':
      return baseStatuses;
    
    case 'CANCELLED':
      return ['PLANNING', 'DROPPED'];
    
    default:
      return baseStatuses;
  }
}
```

#### Status Validation
```dart
@override
void initState() {
  super.initState();
  _status = widget.entry.status;
  
  // Validate status against available statuses
  final availableStatuses = _getAvailableStatuses();
  if (!availableStatuses.contains(_status)) {
    // If current status is not available, default to PLANNING
    _status = 'PLANNING';
  }
  
  // ... rest of initialization
}
```

#### User Hint UI
```dart
// Status hint based on media status
if (widget.mediaStatus != null && widget.mediaStatus != 'FINISHED')
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: Colors.orange),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _getStatusHint(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade300,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ),
```

---

## 🎯 User Experience

### Visual Feedback

1. **Dropdown menu** shows only applicable statuses
2. **Orange info icon** appears when restrictions apply
3. **Helpful message** explains why certain statuses are unavailable

### Example Messages

- **Unreleased**: "This title hasn't been released yet. You can only plan to watch it."
- **Airing**: "This title is currently airing. Completed and Rewatching are unavailable."
- **Cancelled**: "This title was cancelled. Limited statuses available."

---

## ✅ Benefits

### For Users
- **Prevents confusion** - Can't select illogical statuses
- **Clear guidance** - Understands why options are limited
- **Better data quality** - Forces correct status tracking

### For App
- **Data integrity** - Ensures list data makes sense
- **Logic enforcement** - Prevents impossible combinations
- **AniList compatibility** - Aligns with AniList's own logic

---

## 🧪 Testing Scenarios

### Test Case 1: Unreleased Anime
1. Open media details for unreleased anime (NOT_YET_RELEASED)
2. Click "Add to List"
3. **Expected**: Only "Plan to Watch" available in status dropdown
4. **Expected**: Orange hint appears: "This title hasn't been released yet..."

### Test Case 2: Currently Airing
1. Open media details for airing anime (RELEASING)
2. Click "Add to List"
3. **Expected**: Planning, Watching, Paused, Dropped available
4. **Expected**: Completed and Rewatching NOT available
5. **Expected**: Orange hint appears: "This title is currently airing..."

### Test Case 3: Completed Series
1. Open media details for finished anime (FINISHED)
2. Click "Add to List"
3. **Expected**: All statuses available
4. **Expected**: No hint appears

### Test Case 4: Editing Existing Entry
1. Open edit dialog for anime in list
2. Change media status (simulate different scenarios)
3. **Expected**: Available statuses update accordingly
4. **Expected**: If current status becomes invalid, defaults to Planning

### Test Case 5: Status Validation
1. Add anime to list with status "Watching"
2. Anime status changes to "NOT_YET_RELEASED" (edge case)
3. Open edit dialog
4. **Expected**: Status resets to "Planning"

---

## 📊 Coverage

### Media Statuses Handled
- ✅ NOT_YET_RELEASED (Announced)
- ✅ RELEASING (Currently Airing)
- ✅ FINISHED (Completed)
- ✅ CANCELLED (Cancelled)

### List Statuses
**Anime:**
- PLANNING (Plan to Watch)
- CURRENT (Watching)
- COMPLETED (Completed)
- PAUSED (Paused)
- DROPPED (Dropped)
- REPEATING (Rewatching)

**Manga:**
- PLANNING (Plan to Read)
- CURRENT (Reading)
- COMPLETED (Completed)
- PAUSED (Paused)
- DROPPED (Dropped)
- REPEATING (Rereading)

---

## 🚀 Future Enhancements

Potential improvements:

1. **Smart suggestions**
   - Suggest "Watching" for newly aired episodes
   - Suggest "Completed" when final episode airs

2. **Transition guidance**
   - Alert when media status changes (e.g., RELEASING → FINISHED)
   - Offer to update list status automatically

3. **Analytics**
   - Track how often users hit restrictions
   - Identify confusion points

4. **Custom rules**
   - User preferences for status logic
   - Studio-specific rules (e.g., seasonal shows)

---

## 📝 Notes

### Backward Compatibility
- ✅ `mediaStatus` is optional parameter
- ✅ Falls back to all statuses if not provided
- ✅ Existing code continues to work

### Edge Cases Handled
- ✅ Null media status → Show all options
- ✅ Invalid current status → Reset to Planning
- ✅ Unknown media status → Show all options
- ✅ Dialog reused in other contexts → Works without media status

### Design Decisions

**Why default to Planning?**
- Safest option when validation fails
- Never illogical to plan watching something
- Matches AniList behavior

**Why show hint only for restricted statuses?**
- Reduces visual clutter for completed series
- Only appears when user needs explanation
- Orange color indicates informational warning

**Why allow Dropped for unreleased?**
- **Intentional omission** - If user hasn't started, they shouldn't "drop" it
- Can only drop what you've started
- Aligns with logical status progression

---

## 🎓 Lessons Learned

1. **Status validation** - Important to validate on dialog open, not just save
2. **User feedback** - Visual hints prevent confusion
3. **Graceful degradation** - Optional parameter ensures compatibility
4. **Smart defaults** - Planning is safest fallback

---

## ✅ Completion Checklist

- [x] Add `mediaStatus` parameter to EditEntryDialog
- [x] Implement `_getAvailableStatuses()` logic
- [x] Implement `_getStatusHint()` messages
- [x] Add status validation in `initState()`
- [x] Add info hint UI component
- [x] Update `_showAddDialog()` to pass media status
- [x] Update `_showEditDialog()` to pass media status
- [x] Test compilation (no errors)
- [x] Create feature documentation

---

**Status**: ✅ Ready for testing  
**Next Step**: User testing to validate UX and logic

_Feature implemented: October 13, 2025_
