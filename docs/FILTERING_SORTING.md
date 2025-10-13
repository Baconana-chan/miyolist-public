# Advanced Filtering and Sorting

## Overview
Implemented comprehensive filtering and sorting system for anime, manga, and light novel lists with multiple criteria and options.

## Features

### Filters

#### 1. **Format Filter**
**Anime:**
- TV
- TV Short
- Movie
- Special
- OVA
- ONA
- Music

**Manga:**
- Manga
- One Shot

**Light Novels:**
- Novel

#### 2. **Media Status Filter**
- Finished
- Releasing  
- Not Yet Released
- Cancelled
- Hiatus

#### 3. **Country Filter**
- 🇯🇵 Japan
- 🇨🇳 China
- 🇰🇷 South Korea
- 🇹🇼 Taiwan

#### 4. **Genre Filter** (18 genres)
- Action, Adventure, Comedy, Drama
- Ecchi, Fantasy, Horror
- Mahou Shoujo, Mecha, Music
- Mystery, Psychological, Romance
- Sci-Fi, Slice of Life, Sports
- Supernatural, Thriller

#### 5. **Year Range Filter**
- Start Year: From 1940 to current year
- End Year: From 1940 to current year  
- Supports filtering by year range or single year

### Sorting Options

1. **Title** (A-Z / Z-A)
2. **My Score** (0-10)
3. **Progress** (episodes/chapters)
4. **Last Updated** (entry modification date)
5. **Last Added** (entry creation date)
6. **My Start Date** (when user started)
7. **My Completed Date** (when user finished)
8. **Release Date** (anime/manga release year)
9. **Average Score** (AniList community score)
10. **Popularity** (AniList popularity ranking)

Each sort can be **Ascending** or **Descending**.

## UI Components

### 1. Filter Button
Located in app bar between Search and Global Search icons.
- Shows filter dialog on tap
- Accessible from all 3 tabs (Anime/Manga/Novels)

### 2. Filter Dialog
Three-tab interface:
- **Filters Tab**: Format, Status, Country, Genres
- **Sort Tab**: Sort option + direction
- **Year Tab**: Year range picker

### 3. Active Filter Indicator
Blue banner showing:
- Number of active filters per type
- Current sort option (if not default)
- "Clear" button to reset filters

Example: `2 format(s), 3 genre(s), 2010-2020 • Sorted by Average Score`

### 4. Search Indicator  
Red banner (when searching):
- Shows current search query
- "Clear" button to reset search

## Implementation Details

### Models

**`ListFilters`** (`lib/features/anime_list/models/list_filters.dart`):
```dart
class ListFilters {
  final Set<String> formats;
  final Set<String> mediaStatuses;
  final Set<String> genres;
  final Set<String> countries;
  final int? startYear;
  final int? endYear;
  final SortOption sortOption;
  final bool ascending;
}
```

**`SortOption`** enum:
- 10 sorting options
- Each has display label

**Helper classes:**
- `AnimeFormats` - anime format constants
- `MangaFormats` - manga format constants
- `MediaStatus` - media status constants
- `Countries` - country constants with flags

### Updated Models

**`AnimeModel`** added fields:
```dart
@HiveField(17)
final String? countryOfOrigin;  // JP, CN, KR, TW

@HiveField(18)
final int? startYear;  // Release year

@HiveField(19)
final int? popularity;  // AniList popularity

DateTime? get startDate  // Computed from startYear
```

### Logic Flow

1. **Filter Application** (`_applyFiltersAndSort`):
   ```
   Status filter → Format → Media Status → Genres → Country → Year → Sort
   ```

2. **Sorting** (`_sortList`):
   - Handles null values gracefully
   - Supports ascending/descending
   - Different logic per sort type

3. **State Management**:
   - Separate filters for each tab (anime/manga/novel)
   - Filters persist during session
   - Reset on "Clear" button

## Usage

### Opening Filters
1. Navigate to list (Anime/Manga/Novels tab)
2. Tap filter icon in app bar
3. Configure filters in dialog
4. Tap "Apply"

### Multiple Filters
Filters are **additive** (AND logic):
- Format: TV + OVA = shows TV OR OVA
- Within categories: AND logic
- Example: TV + Action + Japan = TV shows that are Action AND from Japan

### Year Range
- Both years optional
- Start Year only: "from 2010"
- End Year only: "until 2020"  
- Both: "2010-2020"

### Sorting
1. Open Sort tab
2. Select sort option
3. Toggle Ascending/Descending
4. Apply

## Technical Notes

### Performance
- Filters applied to already-filtered list (by status)
- Sorting happens after all filters
- Efficient set-based membership checks

### Data Requirements
New fields required from AniList API:
```graphql
countryOfOrigin
startDate { year }
popularity
status
genres
```

### Persistence
- Filters NOT persisted between app sessions
- Reset to defaults on app restart
- Intentional design for clean slate

## Future Enhancements

### Priority 1: Save Filter Presets
```dart
class FilterPreset {
  String name;
  ListFilters filters;
}
```

### Priority 2: More Filters
- Studio filter
- Voice actor filter
- Tag filter (more specific than genres)
- Rating filter (G, PG, PG-13, R, R+)

### Priority 3: Filter Combinations
- AND/OR toggle for genres
- Exclude filter (NOT logic)
- Advanced query builder

### Priority 4: Smart Filters
- "Seasonal" - current season anime
- "Trending" - high popularity gain
- "Completed Recently" - user finished in last 30 days

## Known Limitations

1. **No filter persistence** - resets on app restart
2. **Genre filter limited** - only 18 most popular genres
3. **Year filter UI** - scrollable list (could be improved)
4. **No multi-tab filter sync** - each tab independent

## Testing Checklist

- [x] All format filters work
- [x] Status filters work
- [x] Country filters work  
- [x] Genre filters (multiple selection)
- [x] Year range filtering
- [x] All 10 sort options
- [x] Ascending/descending toggle
- [x] Filter indicator displays correctly
- [x] Clear filters button
- [x] Filters persist across tab switches
- [ ] Performance with 1000+ entries
- [ ] Edge cases (empty filters, no results)

## Screenshots Needed

1. Filter dialog - Filters tab
2. Filter dialog - Sort tab
3. Filter dialog - Year tab
4. Active filter indicator
5. Empty results with filters active

## Conclusion

This implementation provides a powerful, user-friendly filtering and sorting system that significantly improves list management. The modular design allows easy addition of new filters and sort options in the future.
