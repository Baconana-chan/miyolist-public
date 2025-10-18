# Light Novels Separate List Feature

## Overview
Added separate tab for Light Novels while keeping them functionally as MANGA type in AniList API.

## Implementation Date
October 10, 2025 - v1.1.2

## Features

### Visual Separation
- **3 Tabs**: Anime, Manga, Light Novels
- Light Novels displayed separately from Manga
- Same functionality as Manga (status labels, editing, etc.)
- Filtered by `format` field from AniList API

### Technical Implementation

#### Format Detection
Light Novels are identified by `format == 'NOVEL'` in the media data:
```dart
for (final entry in mangaListRaw) {
  final format = entry.media?.format?.toUpperCase();
  if (format == 'NOVEL') {
    novelList.add(entry);
  } else {
    mangaList.add(entry);
  }
}
```

#### Sync Behavior
Despite visual separation, Light Novels are still synced as MANGA type:
```dart
// Combine manga and novels for sync (they're all MANGA type in AniList)
final combinedMangaList = [..._mangaList, ..._novelList];
final mangaListJson = combinedMangaList.map((e) => e.toSupabaseJson()).toList();
```

### User Experience

#### Tabs
- **Anime Tab**: TV, Movie, OVA, etc.
- **Manga Tab**: Manga, One-shot, Doujinshi, Manhwa, Manhua
- **Light Novels Tab**: Light Novels only

#### Status Labels
Light Novels use same labels as Manga:
- Reading / Plan to Read / Completed / Paused / Dropped / Rereading

#### Editing
- Edit dialog works the same for all types
- Changes automatically update correct list (anime/manga/novel)
- Auto-detection by `format` field

## Code Changes

### anime_list_page.dart

#### State Variables
```dart
List<MediaListEntry> _novelList = [];
String _selectedNovelStatus = 'CURRENT';
```

#### Tab Controller
```dart
_tabController = TabController(length: 3, vsync: this);  // Changed from 2 to 3
```

#### Data Loading
```dart
// Separate manga and light novels by format
final mangaList = <MediaListEntry>[];
final novelList = <MediaListEntry>[];

for (final entry in mangaListRaw) {
  final format = entry.media?.format?.toUpperCase();
  if (format == 'NOVEL') {
    novelList.add(entry);
  } else {
    mangaList.add(entry);
  }
}
```

#### Edit Dialog Updates
```dart
// Check if it's a novel or manga
final isNovel = updatedEntry.media?.format?.toUpperCase() == 'NOVEL';

if (isNovel) {
  final index = _novelList.indexWhere((e) => e.id == updatedEntry.id);
  if (index != -1) {
    _novelList[index] = updatedEntry;
  }
} else {
  final index = _mangaList.indexWhere((e) => e.id == updatedEntry.id);
  if (index != -1) {
    _mangaList[index] = updatedEntry;
  }
}
```

### local_storage_service.dart

#### Fixed Type Cast Error
```dart
Map<String, dynamic>? getFavorites() {
  final data = favoritesBox.get('favorites');
  if (data == null) return null;
  return Map<String, dynamic>.from(data as Map);  // Safe conversion
}
```

**Previous Issue**: 
```dart
return favoritesBox.get('favorites') as Map<String, dynamic>?;  // ❌ Type error
```

**Error Message**: 
```
type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>?' in type cast
```

## AniList API Format Values

### ANIME Formats
- TV
- TV_SHORT
- MOVIE
- SPECIAL
- OVA
- ONA
- MUSIC

### MANGA Formats
- MANGA
- NOVEL (Light Novels)
- ONE_SHOT

## Data Flow

### Loading
```
getMangaList()
    ↓
Separate by format
    ↓
format == 'NOVEL' → _novelList
format != 'NOVEL' → _mangaList
```

### Syncing
```
_mangaList + _novelList
    ↓
combinedMangaList
    ↓
syncMangaList(combinedList)
    ↓
Supabase (all as MANGA type)
```

### Editing
```
User edits entry
    ↓
Check entry.media.format
    ↓
format == 'NOVEL' → update _novelList
format != 'NOVEL' → update _mangaList
```

## Benefits

1. **Visual Clarity**: Users can easily distinguish Light Novels from Manga
2. **API Compatibility**: Still works with AniList's MANGA type
3. **No Data Loss**: All entries properly synced and stored
4. **Consistent UX**: Same editing experience across all types

## Edge Cases

### Unknown Format
If `format` is null or unrecognized:
- Default to Manga list
- Still synced correctly
- No data loss

### Migration
Existing users:
- Light Novels automatically separated on next app launch
- No manual action required
- Data remains intact

## Performance

### Memory
- Minimal overhead (just list separation)
- No duplicate data storage
- Efficient filtering by format

### Sync
- Single sync call for manga + novels
- No additional API requests
- Same performance as before

## Future Enhancements
- [ ] Custom labels for each type in settings
- [ ] Reorder tabs (drag & drop)
- [ ] Hide/show specific tabs
- [ ] Format-specific sorting options
- [ ] Visual indicators (icons) for each format

## Testing Checklist
- [x] Light Novels show in separate tab
- [x] Manga doesn't include Light Novels
- [x] Editing Light Novel updates correct list
- [x] Deleting Light Novel removes from correct list
- [x] Syncing combines manga + novels
- [x] Status filters work for all tabs
- [x] Tab switching preserves filter state

## Known Limitations
1. No separate stats for Light Novels (combined with Manga in API)
2. Cannot move entry between Manga/Novel (format is from AniList)
3. Format field must be present (API requirement)

## Compatibility
- ✅ Backward compatible (existing data works)
- ✅ AniList API compatible
- ✅ Supabase sync compatible
- ✅ Local storage compatible
