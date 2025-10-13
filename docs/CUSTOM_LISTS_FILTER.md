# Custom Lists Filter

## Overview

The Custom Lists Filter feature allows users to filter their anime, manga, and light novel entries by custom lists created in AniList or within the app.

## Implementation

### Model Changes

**`ListFilters`** (`lib/features/anime_list/models/list_filters.dart`)
- Added `customLists` field of type `Set<String>`
- Updated `copyWith` method to include `customLists`
- Updated `hasActiveFilters` to check for custom lists

### UI Components

**`FilterSortDialog`** (`lib/features/anime_list/presentation/widgets/filter_sort_dialog.dart`)
- Added new tab "Custom Lists" (4th tab)
- Added `availableCustomLists` parameter to receive list of all custom lists
- Added `_selectedCustomLists` state variable
- Implemented `_buildCustomListsTab()` method:
  - Shows empty state when no custom lists exist
  - Displays `FilterChip` widgets for each available custom list
  - Allows multi-select of custom lists
  - Uses accent blue color for selected chips

**`AnimeListPage`** (`lib/features/anime_list/presentation/pages/anime_list_page.dart`)
- Added `_getAllCustomLists()` method to extract all unique custom list names from entries
- Updated filter dialog invocation to pass `availableCustomLists`
- Added custom lists filter logic in `_applyFiltersAndSort()`:
  - Filters entries that belong to at least one selected custom list
  - Works with OR logic (entry in any selected list)

### Filter Logic

When custom lists are selected:
```dart
if (filters.customLists.isNotEmpty) {
  filtered = filtered.where((entry) {
    final entryCustomLists = entry.customLists ?? [];
    return filters.customLists.any((filterList) => 
      entryCustomLists.contains(filterList));
  }).toList();
}
```

## Usage

1. Create custom lists in entry editor or on AniList website
2. Open Filter & Sort dialog
3. Navigate to "Custom Lists" tab
4. Select one or more custom lists to filter by
5. Click "Apply" to see filtered results

## Features

- ✅ Multi-select custom lists
- ✅ Empty state when no lists exist
- ✅ Sorted alphabetically
- ✅ Works across all tabs (Anime, Manga, Novels)
- ✅ Resets with "Reset" button
- ✅ Persists across filter dialog sessions
- ✅ Combines with other filters (format, genre, status, etc.)

## UI/UX Details

- **Empty State**: Shows helpful message to create custom lists
- **Filter Chips**: Blue accent color when selected
- **Tab Order**: Filters → Custom Lists → Sort → Year
- **List Source**: Dynamically extracted from current tab's entries

## Technical Notes

- Custom lists are extracted dynamically from entries on each filter dialog open
- Lists are sorted alphabetically for consistent display
- Filter uses OR logic: entry shown if in ANY selected custom list
- Works seamlessly with other active filters

## Future Enhancements

- [ ] AND logic option (entry must be in ALL selected lists)
- [ ] Quick filter buttons on main list view
- [ ] Custom list badges on entry cards
- [ ] Filter by "entries not in any custom list"
