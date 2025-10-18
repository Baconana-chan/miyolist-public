# View Modes & Bulk Operations

**Implemented:** October 11, 2025  
**Version:** v1.4.0

---

## 📊 View Modes

Three different view modes for displaying your anime/manga lists:

### Grid View (Default)
- **Layout:** Card-based grid
- **Details:** Cover image, title, format, progress, score
- **Best for:** Visual browsing, recognizing by covers
- **Density:** Medium

### List View
- **Layout:** Horizontal cards with larger size (140px height)
- **Details:** 100px cover image, full title, format, year, progress, score, status label
- **Best for:** Detailed information at a glance
- **Density:** Low (most detailed)

### Compact View
- **Layout:** Minimal text-focused rows
- **Details:** Status dot (8px), title, format, progress, score
- **Best for:** Maximum density, quick scanning
- **Density:** High (most compact)

### Features
- ✅ Per-category storage (Anime, Manga, Novels have separate view modes)
- ✅ Persistent storage in UserSettings
- ✅ PopupMenu in AppBar for easy switching
- ✅ Smooth transitions between modes
- ✅ All view modes support selection mode

### Technical Implementation
- **ViewMode enum:** `grid`, `list`, `compact`
- **Storage:** HiveField(14-16) in UserSettings
  - `animeViewMode: String`
  - `mangaViewMode: String`
  - `novelViewMode: String`
- **Widgets:**
  - `MediaListCard` - Grid view (existing)
  - `MediaListViewCard` - List view (new, 308 lines)
  - `MediaCompactViewCard` - Compact view (new, 213 lines)

---

## 🔲 Bulk Operations

Multi-select and batch operations for efficient list management:

### Entering Selection Mode
- **Long press** on any card to enter selection mode
- AppBar changes to show selection count
- Action buttons appear (Select All, Bulk Edit, Cancel)
- Cards show selection indicators

### Selection UI
- **Visual indicators:**
  - Blue border (3px) on selected cards
  - Checkmark circle (28px) in top-right corner
  - Shadow glow on selected cards
- **Works in all view modes:** Grid, List, Compact
- **Select all:** Button to select all visible entries

### Bulk Actions

#### 1. Change Status
- Change multiple entries to same status
- Dropdown with context-aware status names
- Supports all statuses: Watching/Reading, Planning, Completed, Paused, Dropped, Repeating

#### 2. Change Score
- Set same score for multiple entries
- Slider from 0 to 10 (0.5 increments)
- Visual score display

#### 3. Delete
- Delete multiple entries at once
- Warning banner with confirmation
- Requires explicit confirmation

### Features
- ✅ Multi-select mode with long press
- ✅ Visual selection indicators (border, checkmark)
- ✅ Selection count in AppBar
- ✅ Select all functionality
- ✅ Beautiful bulk edit dialog with 3 actions
- ✅ Direct Hive box operations (animeListBox.put/delete)
- ✅ Type-aware (Anime/Manga/Novel)
- ✅ Confirmation for destructive actions
- ✅ Success notifications

### Technical Implementation
- **BulkEditDialog:** 419 lines
  - `BulkAction` enum: changeStatus, changeScore, delete
  - Beautiful card-based action selection
  - Context-aware UI (shows appropriate statuses)
- **Selection State:**
  ```dart
  bool _isSelectionMode = false;
  final Set<int> _selectedEntryIds = {};
  ```
- **Card Updates:**
  - All three card types support selection parameters
  - `isSelectionMode`, `isSelected`, `onLongPress`
- **Storage:**
  - Direct Hive box operations
  - `animeListBox.put(id, entry)` / `delete(id)`
  - `mangaListBox.put(id, entry)` / `delete(id)`
  - No intermediate save methods needed

### User Flow
1. Long press on any card → Enter selection mode
2. Tap additional cards to select/deselect
3. Use "Select All" to select everything (optional)
4. Tap "Bulk Edit" button (checklist icon)
5. Choose action in dialog
6. Confirm action
7. Changes applied to all selected entries
8. Exit selection mode automatically

---

## 🎨 UI/UX Highlights

### View Modes
- **Seamless switching:** No data reload needed
- **Visual feedback:** Icon in PopupMenu shows current mode
- **Persistent:** Remembers choice per category
- **Accessible:** Clear labels and descriptions

### Bulk Operations
- **Intuitive:** Long press is standard pattern
- **Safe:** Confirmation for destructive actions
- **Clear:** Selection count always visible
- **Efficient:** Batch operations save time
- **Flexible:** Works with all view modes

---

## 📈 Performance

### View Modes
- **Lazy loading:** Only current view mode widgets built
- **Efficient rebuilds:** Only affected widgets update
- **Memory:** Same data, different presentation

### Bulk Operations
- **Direct database access:** No intermediate layers
- **Batch operations:** Single transaction per action
- **No redundant syncs:** One sync after bulk operation
- **Type-safe:** Correct box based on media type

---

## 🐛 Known Limitations

### View Modes
- None currently

### Bulk Operations
- Cannot undo bulk operations (use with caution)
- Cannot bulk edit different statuses simultaneously
- Cannot bulk edit custom fields (start date, notes, etc.)

---

## 🔮 Future Enhancements

### View Modes
- [ ] Table view (spreadsheet-like)
- [ ] Poster view (covers only, no text)
- [ ] Detailed view (expanded information)

### Bulk Operations
- [ ] Undo/redo support
- [ ] More actions: bulk custom list assignment, bulk rewatch count
- [ ] Filter-based bulk actions (e.g., "change all Planning to Watching")
- [ ] Bulk import/export

---

## 📝 Developer Notes

### Adding New View Mode
1. Create new widget in `widgets/` folder
2. Add enum value to `ViewMode`
3. Update `_buildMediaGrid()` switch statement
4. Add to PopupMenu options
5. Test with all card features (selection, info button, etc.)

### Adding New Bulk Action
1. Add enum value to `BulkAction`
2. Create action card in `BulkEditDialog`
3. Add case to `_applyBulkAction()` switch
4. Handle storage operations
5. Test with multiple entries
6. Add confirmation if destructive

### Storage Pattern
```dart
// Always use direct box operations
await widget.localStorageService.animeListBox.put(entry.id, entry);
await widget.localStorageService.animeListBox.delete(entry.id);

// Determine type based on:
// 1. Current tab (0 = Anime, 1 = Manga, 2 = Novel)
// 2. Media format (NOVEL → mangaBox)
```

---

**Last Updated:** October 11, 2025
