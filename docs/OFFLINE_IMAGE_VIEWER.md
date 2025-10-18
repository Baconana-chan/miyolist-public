# Offline Image Viewer - Feature Documentation

**Feature:** Offline Image Gallery  
**Version:** v1.1.0-dev  
**Date:** October 15, 2025  
**Status:** ✅ Completed

---

## 📸 Overview

The **Offline Image Viewer** is a dedicated gallery for browsing all cached cover images from your anime/manga list. It provides a beautiful, organized way to explore your offline image cache with search, sorting, and full-screen viewing capabilities.

---

## ✨ Features

### 1. **Image Gallery Page**
- **Grid layout** with 3 columns for optimal browsing
- **Card-based design** with cover previews
- **Media ID display** on each card
- **File size** and **cached date** shown
- **Dark theme** consistent with app design
- **Smooth animations** and transitions

### 2. **Statistics Dashboard**
At the top of the gallery:
- 📊 **Total Images** - Count of all cached images
- 💾 **Total Size** - Combined size of all cached images
- 📈 **Average Size** - Average file size

### 3. **Search Functionality**
- **Real-time search** as you type
- Search by **Media ID** (e.g., "12345")
- Search by **filename** (partial match)
- **Clear button** to reset search
- **Empty state** when no results found

### 4. **Sort Options**
Three sorting modes via toolbar menu:
- ⏰ **Newest First** - Most recently cached images (default)
- 📜 **Oldest First** - Images cached long ago
- 📊 **Largest First** - Biggest files at the top

### 5. **Full-Screen Image Viewer**
Tap any image to enter immersive viewer:
- **Swipe navigation** - Swipe left/right to browse
- **Pinch to zoom** - InteractiveViewer with 0.5x to 4x zoom
- **Tap to toggle UI** - Hide/show controls
- **Immersive mode** - System UI hidden for maximum screen space
- **Image counter** - Shows "X / Y" position
- **Progress bar** - Visual indicator of position in gallery

### 6. **Image Actions**
- **Long press** on card to delete image
- **Delete button** in full-screen viewer
- **Confirmation dialog** before deletion
- **Success feedback** via SnackBar
- **Info dialog** with detailed metadata:
  - Media ID
  - Filename
  - File size
  - Cached date (relative)
  - Last modified date

### 7. **Refresh Capability**
- **Manual refresh** button in toolbar
- Reloads all images and statistics
- Updates after deletions

---

## 🎨 User Interface

### Gallery Page Layout
```
┌─────────────────────────────────┐
│ 📸 Offline Gallery    [Sort] [⟳] │ <- AppBar
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │   📊 Statistics Dashboard   │ │ <- Stats Card
│ │   Images | Size | Avg Size  │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [🔍 Search by ID or filename...] │ <- Search Bar
├─────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │ IMG │ │ IMG │ │ IMG │        │ <- Image Grid
│ │ ID  │ │ ID  │ │ ID  │        │    (3 columns)
│ └─────┘ └─────┘ └─────┘        │
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │ IMG │ │ IMG │ │ IMG │        │
│ └─────┘ └─────┘ └─────┘        │
└─────────────────────────────────┘
```

### Full-Screen Viewer
```
┌─────────────────────────────────┐
│ [←] Media #12345    [ℹ️] [🗑️]   │ <- Top Bar (auto-hide)
│                                 │
│                                 │
│          [  IMAGE  ]            │ <- Zoomable image
│                                 │
│                                 │
│         3 / 10                  │ <- Counter
│ ▰▰▰▱▱▱▱▱▱▱                      │ <- Progress bar
└─────────────────────────────────┘
```

---

## 🔧 Technical Implementation

### Architecture
```
lib/features/image_gallery/
├── models/
│   └── cached_image_info.dart    # Image metadata model
├── services/
│   └── image_gallery_service.dart # Business logic
└── presentation/
    ├── image_gallery_page.dart   # Main gallery UI
    └── image_viewer_page.dart    # Full-screen viewer
```

### Key Components

#### 1. **CachedImageInfo Model**
```dart
class CachedImageInfo {
  final File file;
  final String filename;
  final int mediaId;
  final int size;
  final DateTime lastModified;
  
  String get formattedSize { ... }
  String get formattedDate { ... }
  static Future<CachedImageInfo> fromFile(File file) { ... }
}
```

#### 2. **ImageGalleryService**
```dart
class ImageGalleryService {
  // Get all cached images
  Future<List<CachedImageInfo>> getAllCachedImages()
  
  // Search by media ID
  Future<List<CachedImageInfo>> searchByMediaId(String query)
  
  // Sort by size
  Future<List<CachedImageInfo>> getImagesSortedBySize()
  
  // Sort by date (oldest first)
  Future<List<CachedImageInfo>> getOldestImages()
  
  // Delete specific image
  Future<void> deleteImage(CachedImageInfo image)
  
  // Get statistics
  Future<Map<String, dynamic>> getStatistics()
}
```

#### 3. **Image Gallery Page**
- StatefulWidget with search and sort state
- GridView.builder for image cards
- TextEditingController for search
- PopupMenuButton for sort options
- Statistics card at top
- Empty states for no images/no results

#### 4. **Image Viewer Page**
- PageView for swipe navigation
- InteractiveViewer for zoom
- Immersive system UI mode
- Animated UI bars (top/bottom)
- Tap to toggle UI visibility
- Delete and info actions

---

## 🎯 Use Cases

### 1. **Browse Offline Content**
User wants to see all cached anime/manga covers:
1. Open Profile page
2. Tap "📸 Offline Gallery" button
3. Browse grid of all cached images
4. See statistics at top

### 2. **Find Specific Media**
User wants to find image for specific anime:
1. Open gallery
2. Tap search bar
3. Type media ID (e.g., "12345")
4. Results filtered in real-time
5. Tap image to view full-screen

### 3. **View Full-Screen**
User wants to see image in detail:
1. Tap any image in gallery
2. Full-screen viewer opens
3. Swipe left/right to browse
4. Pinch to zoom in/out
5. Tap to hide UI for maximum view
6. Tap info button for metadata

### 4. **Manage Storage**
User wants to free up space:
1. Open gallery
2. Sort by "Largest First"
3. Long press large images to delete
4. Confirm deletion
5. See updated statistics

### 5. **Find Old Cached Images**
User wants to see oldest cached images:
1. Open gallery
2. Tap sort menu → "Oldest First"
3. See images cached long ago
4. Optionally delete old images

---

## 📊 Statistics Tracking

### Metrics Displayed
- **Total Images**: Count of all cached files
- **Total Size**: Sum of all file sizes (formatted)
- **Average Size**: Mean file size
- **Oldest Date**: Date of oldest cached image
- **Newest Date**: Date of newest cached image

### Size Formatting
- **< 1 KB**: "512 B"
- **< 1 MB**: "256.5 KB"
- **< 1 GB**: "12.8 MB"
- **≥ 1 GB**: "1.2 GB"

### Date Formatting (Relative)
- **< 1 hour**: "45m ago"
- **< 1 day**: "3h ago"
- **< 1 week**: "5d ago"
- **< 1 month**: "2w ago"
- **≥ 1 month**: "3mo ago"

---

## 🎨 UI Details

### Color Scheme
- **Background**: `#121212` (Dark gray)
- **Cards**: `#1E1E1E` (Medium gray)
- **Primary Text**: `#FFFFFF` (White)
- **Secondary Text**: `#9E9E9E` (Gray 600)
- **Accent**: `#2196F3` (Blue)
- **Error**: `#F44336` (Red)

### Icons
- 📸 **Gallery**: `Icons.photo_library`
- 🔍 **Search**: `Icons.search`
- 📊 **Sort**: `Icons.sort`
- ⟳ **Refresh**: `Icons.refresh`
- ℹ️ **Info**: `Icons.info_outline`
- 🗑️ **Delete**: `Icons.delete_outline`
- ⏰ **Newest**: `Icons.access_time`
- 📜 **Oldest**: `Icons.history`
- 💾 **Size**: `Icons.data_usage`

### Animations
- **Smooth fade-in** for image loading
- **Slide animations** for page transitions
- **Zoom animations** for InteractiveViewer
- **Progress bar animation** in viewer

---

## 🔒 Privacy & Data

### Data Source
- Images are loaded from **local cache directory** only
- Path: `{AppDocuments}/image_cache/`
- No network requests made
- No external sharing capabilities

### Filename Format
Images are named: `{mediaId}_{hash}.{extension}`
- Example: `12345_a1b2c3d4.jpg`
- MediaId extracted for display
- Hash ensures uniqueness

### Deletion Behavior
- **Confirmation dialog** before deletion
- **Permanent deletion** (cannot be undone)
- **Re-cached automatically** when media viewed again
- **No impact on AniList data** (only local files)

---

## ⚡ Performance

### Optimizations
- **Lazy loading**: Images loaded on scroll
- **Image caching**: Flutter's Image.file caching
- **Async file operations**: Non-blocking file I/O
- **Efficient sorting**: In-memory sorting only
- **Minimal rebuilds**: Proper state management

### Memory Management
- Images disposed when out of view
- PageView uses lazy loading
- InteractiveViewer handles memory efficiently
- No memory leaks from image loading

---

## 🐛 Error Handling

### File Not Found
- Shows broken image icon
- "Failed to load image" message
- Gracefully skips missing files

### Empty Cache
- **Empty state widget** shown
- Message: "No cached images yet"
- Helpful tip displayed

### Search No Results
- **Empty state widget** shown
- Message: "No images found"
- Suggestion to try different search

### Delete Errors
- **Error SnackBar** displayed
- Does not crash app
- File remains if deletion fails

---

## 📱 Access Points

### Profile Page
Located in AppBar actions:
```
[📸 Gallery] [🖼️ Cache] [⚙️ Settings] [...]
```

Position: **First button** in toolbar (leftmost)

### Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ImageGalleryPage(),
  ),
);
```

---

## 🚀 Future Enhancements

Potential improvements for future versions:

### Planned Features
- [ ] **Export images** - Share or export to device gallery
- [ ] **Bulk delete** - Select multiple images to delete
- [ ] **Grid size options** - 2/3/4 columns toggle
- [ ] **Filter by size range** - "Show images > 1MB"
- [ ] **Filter by date range** - "Show images from last month"
- [ ] **Media info integration** - Show anime/manga title
- [ ] **Navigate to media** - Tap media ID to open details
- [ ] **Share image** - Share via system dialog
- [ ] **Set as wallpaper** - Quick wallpaper setter
- [ ] **Slideshow mode** - Auto-advance images

### Advanced Features
- [ ] **Image compression** - Reduce file sizes in-place
- [ ] **Duplicate detection** - Find and merge duplicates
- [ ] **Favorites** - Mark favorite images
- [ ] **Collections** - Organize into custom folders
- [ ] **Tags** - Add custom tags to images
- [ ] **Cloud backup** - Sync cache to cloud
- [ ] **Image editing** - Crop, rotate, filters

---

## 📝 Implementation Notes

### Dependencies
- **path_provider**: ^2.1.1 (get app documents directory)
- **Flutter SDK**: Image.file, InteractiveViewer, PageView

### No External Dependencies
- No additional packages required
- Uses existing ImageCacheService
- Pure Flutter widgets

### File System Access
- Read-only access to cache directory
- Delete permission for cleanup
- No external storage access
- Respects app sandbox

---

## 🎯 Benefits

### For Users
- ✅ **Visual exploration** of cached content
- ✅ **Quick media lookup** by ID
- ✅ **Storage management** via deletion
- ✅ **Offline accessibility** to all covers
- ✅ **Beautiful presentation** of cache

### For Developers
- ✅ **Modular architecture** - Easy to extend
- ✅ **Reusable components** - CachedImageInfo model
- ✅ **Clean separation** - Service layer
- ✅ **Well-documented** - Comprehensive docs
- ✅ **Error resilient** - Handles edge cases

---

## 📚 Related Features

- **Image Caching** (v1.5.0) - Automatic background caching
- **Image Cache Settings** (v1.5.0) - Cache size limits and cleanup
- **Offline Mode** - Works without internet connection
- **Media Details** - Original source of cached images

---

## ✅ Testing Checklist

### Basic Functionality
- [x] Gallery page opens from profile
- [x] Images load in grid layout
- [x] Statistics display correctly
- [x] Search filters images
- [x] Sort options work
- [x] Full-screen viewer opens
- [x] Swipe navigation works
- [x] Zoom functionality works
- [x] Delete confirmation shows
- [x] Deletion removes image
- [x] Refresh updates gallery

### Edge Cases
- [x] Empty cache handled
- [x] No search results handled
- [x] Broken images handled
- [x] Single image handled
- [x] Large number of images handled
- [x] Very large file sizes handled
- [x] Very old dates handled

### UI/UX
- [x] Dark theme consistent
- [x] Icons clear and intuitive
- [x] Empty states helpful
- [x] Animations smooth
- [x] Touch targets adequate
- [x] Loading states clear
- [x] Error messages helpful

---

## 📖 User Guide

### How to Access
1. Open MiyoList app
2. Go to **Profile** page (bottom navigation)
3. Look for **📸 Offline Gallery** button in toolbar
4. Tap to open gallery

### How to Search
1. Open gallery
2. Tap search bar at top
3. Type media ID or filename
4. Results filter automatically
5. Tap ❌ to clear search

### How to Sort
1. Open gallery
2. Tap **sort icon** (three lines) in toolbar
3. Select sort option:
   - **Newest First** (default)
   - **Oldest First**
   - **Largest First**
4. Gallery re-sorts immediately

### How to View Full-Screen
1. Tap any image in gallery
2. Full-screen viewer opens
3. **Swipe left/right** to navigate
4. **Pinch to zoom** in/out
5. **Tap anywhere** to toggle UI
6. **Tap back button** to exit

### How to Delete Images
**Method 1: From Gallery**
1. Long press image card
2. Confirmation dialog appears
3. Tap "Delete" to confirm
4. Image removed from cache

**Method 2: From Viewer**
1. Open image in full-screen
2. Tap **trash icon** (🗑️) in top bar
3. Confirm deletion
4. Returns to gallery (or next image)

### How to View Image Info
1. Open image in full-screen viewer
2. Tap **info icon** (ℹ️) in top bar
3. Dialog shows:
   - Media ID
   - Filename
   - File size
   - Cached date
   - Last modified date
4. Tap "Close" to dismiss

---

## 🎓 Lessons Learned

### Technical Insights
- **File system operations** should be async
- **Image disposal** is important for memory
- **InteractiveViewer** handles zoom well
- **PageView** perfect for image galleries
- **SystemUiMode.immersiveSticky** for full-screen

### Design Decisions
- **3-column grid** optimal for mobile
- **Dark theme** reduces eye strain
- **Statistics at top** provides context
- **Tap to toggle UI** intuitive pattern
- **Confirmation dialogs** prevent accidents

### User Feedback Integration
- **Empty states** guide new users
- **Search** enables quick lookup
- **Sort options** provide flexibility
- **Long press to delete** familiar pattern
- **Swipe navigation** natural gesture

---

**Last Updated:** October 15, 2025  
**Version:** v1.1.0-dev  
**Status:** ✅ Production Ready
