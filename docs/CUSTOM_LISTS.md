# Custom Lists Feature

## Overview
Implemented support for AniList custom lists - allowing users to organize their anime/manga/novel entries into personalized collections.

## Features

### 1. **Custom Lists Management**
- Create new custom lists directly in the app
- Add/remove entries to/from multiple custom lists
- Delete custom lists
- Sync custom lists with AniList

### 2. **Custom Lists Dialog**
- Beautiful UI for managing custom lists
- Checkbox interface for quick selection
- Create new lists inline with text input
- Delete lists with confirmation dialog
- Shows selected count in real-time

### 3. **Integration with Entry Editor**
- "Custom Lists" button in Edit Entry dialog
- Badge showing number of lists the entry belongs to
- Quick access to manage lists for each entry

### 4. **AniList Synchronization**
- Fetches custom lists from AniList on sync
- Updates custom lists on AniList when entry is saved
- Preserves existing lists from AniList

## Implementation Details

### Models

**`MediaListEntry`** - Added field:
```dart
@HiveField(12)
final List<String>? customLists;
```

### GraphQL Updates

**Query** - Added `customLists` field:
```graphql
query($userId: Int, $type: MediaType) {
  MediaListCollection(userId: $userId, type: $type) {
    lists {
      entries {
        id
        mediaId
        # ... other fields ...
        customLists
      }
    }
  }
}
```

**Mutation** - Added `customLists` parameter:
```graphql
mutation(
  $entryId: Int,
  # ... other parameters ...
  $customLists: [String]
) {
  SaveMediaListEntry(
    id: $entryId,
    # ... other parameters ...
    customLists: $customLists
  ) {
    id
    # ... other fields ...
    customLists
  }
}
```

### UI Components

**`CustomListsDialog`** (`lib/features/anime_list/presentation/widgets/custom_lists_dialog.dart`):
- **Props**:
  - `initialLists`: Current lists the entry belongs to
  - `allAvailableLists`: All available custom lists
- **Features**:
  - Checkbox list for selecting existing lists
  - Text field + button for creating new lists
  - Delete button for each list (with confirmation)
  - Empty state when no lists exist
  - Selected count display
  - Save/Cancel actions

**`EditEntryDialog`** - Updated:
- Added `_customLists` state variable
- Added "Custom Lists" section after Notes
- Shows badge with count when lists are selected
- Button opens `CustomListsDialog`
- Saves custom lists when entry is saved

### Service Layer

**`AniListService`** - Updated methods:
- `fetchAnimeList()`: Fetches `customLists` field
- `fetchMangaList()`: Fetches `customLists` field  
- `updateMediaListEntry()`: Accepts `customLists` parameter

**`AnimeListPage`** - Updated:
- Passes `customLists` to `updateMediaListEntry()` during sync

## Usage

### Adding Entry to Custom Lists

1. Open any anime/manga/novel entry
2. Tap "Edit" button
3. Scroll to "Custom Lists" section
4. Tap "Add to Custom Lists" button
5. In the dialog:
   - Check existing lists to add entry
   - OR create a new list by typing name and tapping "+"
6. Tap "Save" in dialog
7. Tap "Save" in entry editor
8. Sync with AniList

### Creating New Custom List

In Custom Lists Dialog:
1. Type list name in text field
2. Tap "+" button or press Enter
3. List is created and automatically selected
4. Tap "Save" to apply

### Removing from Custom List

1. Open Custom Lists Dialog
2. Uncheck the list
3. Tap "Save"

### Deleting Custom List

1. Open Custom Lists Dialog
2. Tap delete icon (🗑️) next to list name
3. Confirm deletion
4. List is removed from all entries

## Data Flow

```
User Action
    ↓
EditEntryDialog (Local State)
    ↓
MediaListEntry.customLists (Hive)
    ↓
AniListService.updateMediaListEntry()
    ↓
AniList API (SaveMediaListEntry mutation)
    ↓
AniList Server (Persisted)
```

## Synchronization

### On Fetch (from AniList):
```dart
// GraphQL returns customLists array
MediaListEntry.fromJson({
  // ...
  'customLists': ['Favorites', 'To Rewatch'],
});
```

### On Update (to AniList):
```dart
await _anilist.updateMediaListEntry(
  entryId: entry.id,
  // ... other params ...
  customLists: ['Favorites', 'To Rewatch', 'Top 10'],
);
```

## Technical Notes

### Hive Storage
- **TypeId**: 2 (MediaListEntry)
- **FieldId**: 12 (customLists)
- **Type**: `List<String>?`
- Stored as list of list names

### Null Safety
- Field is nullable (`List<String>?`)
- Empty list converted to `null` when saving
- `null` converted to empty list when loading

### Performance
- Lists stored locally in Hive (no network delay)
- Only synced to AniList when user saves entry
- Batch sync supported for multiple entries

## Filter by Custom Lists

Added in v1.2.0 - Users can now filter their lists by custom lists.

### Features
- **Multi-select filtering**: Select multiple custom lists to show entries
- **Dynamic list detection**: Automatically finds all custom lists from entries
- **Empty state handling**: Shows helpful message when no custom lists exist
- **Tab integration**: Works across Anime, Manga, and Novel tabs
- **Combined filtering**: Works alongside format, genre, status, and year filters

### Usage
1. Open Filter & Sort dialog
2. Navigate to "Custom Lists" tab (2nd tab)
3. Select one or more custom lists
4. Click "Apply" to filter

### Implementation Details
- `ListFilters` model updated with `customLists` field
- `FilterSortDialog` added new "Custom Lists" tab
- `_applyFiltersAndSort()` applies OR logic (entry in ANY selected list)
- `_getAllCustomLists()` extracts unique list names from current entries

See [CUSTOM_LISTS_FILTER.md](./CUSTOM_LISTS_FILTER.md) for detailed documentation.

## Future Enhancements

### Priority 1: Fetch All User's Custom Lists
Currently, `_getAllCustomLists()` returns empty list. Should:
```dart
// Query user's MediaListCollection to get all custom list names
query {
  MediaListCollection(userId: $userId) {
    user {
      id
      name
    }
    lists {
      name
      isCustomList
      entries {
        customLists
      }
    }
  }
}
```

### Priority 2: Filter by Custom Lists
Add custom list filter in `FilterSortDialog`:
- Multi-select dropdown/chips
- Filter entries by selected custom lists
- "Any" vs "All" logic option

### Priority 3: Bulk Add to Custom Lists
- Select multiple entries (checkbox mode)
- "Add to Custom List" bulk action
- Apply to all selected entries at once

### Priority 4: Custom List Tab/View
- Dedicated tab for viewing custom lists
- Group entries by custom list
- Reorder custom lists
- List descriptions/colors

### Priority 5: Import/Export Custom Lists
- Export lists as JSON
- Share lists with other users
- Import from file or URL

## Testing Checklist

### Basic Functionality
- [ ] Create new custom list
- [ ] Add entry to existing list
- [ ] Remove entry from list
- [ ] Delete custom list
- [ ] Save entry with custom lists

### AniList Integration
- [ ] Custom lists fetched from AniList on sync
- [ ] Custom lists updated to AniList on save
- [ ] Multiple lists per entry supported
- [ ] Empty custom lists handled correctly

### UI/UX
- [ ] Custom lists dialog opens correctly
- [ ] Badge shows correct count
- [ ] Empty state displays when no lists
- [ ] Create list validates input
- [ ] Delete confirmation works
- [ ] Selected count updates in real-time

### Edge Cases
- [ ] Entry with no custom lists
- [ ] Entry with many custom lists (10+)
- [ ] List name with special characters
- [ ] Duplicate list name prevention
- [ ] Very long list names (50+ characters)
- [ ] Deleting list that entry belongs to

## Known Limitations

1. **No server-side list fetching** - Currently only lists that exist on entries are known
2. **No list metadata** - Can't store list descriptions, colors, or icons
3. **No list ordering** - Lists displayed alphabetically by default
4. **No shared lists** - Each user's lists are private
5. **No list templates** - Can't import predefined list structures

## API Reference

### MediaListEntry Methods

```dart
// Create entry with custom lists
final entry = MediaListEntry(
  // ... required fields ...
  customLists: ['Favorites', 'To Rewatch'],
);

// Update custom lists
final updated = entry.copyWith(
  customLists: ['Favorites', 'Top 10'],
);

// Check if entry in list
final isFavorite = entry.customLists?.contains('Favorites') ?? false;
```

### AniListService Methods

```dart
// Update with custom lists
await anilist.updateMediaListEntry(
  entryId: entry.id,
  customLists: ['Favorites'],
);
```

### CustomListsDialog

```dart
// Open dialog
final result = await showDialog<List<String>>(
  context: context,
  builder: (context) => CustomListsDialog(
    initialLists: entry.customLists ?? [],
    allAvailableLists: getAllCustomLists(),
  ),
);

// result contains selected list names or null if cancelled
if (result != null) {
  setState(() {
    _customLists = result;
  });
}
```

## Conclusion

This implementation provides a solid foundation for custom lists functionality, allowing users to organize their media collections beyond the standard status categories. The feature integrates seamlessly with AniList's existing custom lists system and provides an intuitive UI for management.
