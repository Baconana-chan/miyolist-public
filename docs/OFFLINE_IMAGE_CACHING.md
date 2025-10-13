# Offline Image Caching Implementation

## Overview

Implemented offline image caching for user's anime/manga list entries. Cover images are automatically downloaded and stored locally for faster loading and offline access.

## Features

### 1. Automatic Image Downloading
- Images are downloaded in the background after sync completes
- Non-blocking downloads don't interrupt user experience
- Only downloads images for media in user's list (anime, manga, novels)

### 2. Smart Caching Strategy
- **Local-first**: Always checks local cache before network
- **Graceful fallback**: Falls back to network if local file fails
- **Background downloads**: Downloads happen silently in background
- **Persistent storage**: Images survive app restarts

### 3. Cache Management UI
- View cache statistics (image count, storage used)
- Clear cache button with confirmation
- Accessible from Profile page → Image Cache icon

## Architecture

### Core Components

#### 1. `ImageCacheService` (`lib/core/services/image_cache_service.dart`)
Singleton service managing all offline caching operations:

```dart
class ImageCacheService {
  // Initialize cache directory
  Future<void> initialize()
  
  // Get local image if exists
  Future<File?> getLocalImage(String url, int mediaId)
  
  // Download and cache image
  Future<File?> downloadImage(String url, int mediaId)
  
  // Delete cached image
  Future<void> deleteImage(int mediaId)
  
  // Batch download for multiple images
  Future<void> downloadBatch(List<({int mediaId, String? coverUrl})> mediaList)
  
  // Cache management
  Future<int> getCacheSize()
  Future<int> getCachedImageCount()
  Future<void> clearCache()
  Future<void> cleanupUnusedImages(List<int> activeMediaIds)
}
```

**Storage Location**: `{DocumentsDirectory}/image_cache/`

**Filename Format**: `{mediaId}_{urlHash}.{extension}`
- Example: `123456_a1b2c3d4.jpg`
- Uses MD5 hash of URL to handle URL changes
- Extension preserved from original URL

#### 2. `CachedCoverImage` Widget (`lib/core/widgets/cached_cover_image.dart`)
Custom widget that displays images with offline caching:

```dart
CachedCoverImage(
  imageUrl: media.coverImage,
  mediaId: media.id,
  width: double.infinity,
  height: double.infinity,
  fit: BoxFit.cover,
  enableOfflineCache: true, // Set false for public pages
)
```

**Loading Priority**:
1. Check local cache
2. If found, display immediately
3. If not found, show network image (CachedNetworkImage)
4. Start background download for next time

#### 3. `ImageCacheSettingsDialog` (`lib/features/profile/presentation/widgets/image_cache_settings_dialog.dart`)
UI for managing cached images:
- Displays cache statistics
- Shows storage usage in human-readable format (KB/MB/GB)
- Allows clearing entire cache
- Confirmation dialog before clearing

### Integration Points

#### 1. Main App Initialization (`lib/main.dart`)
```dart
void main() async {
  // ...
  // Initialize image cache service
  await ImageCacheService().initialize();
  // ...
}
```

#### 2. List Card (`lib/features/anime_list/presentation/widgets/media_list_card.dart`)
Replaced `CachedNetworkImage` with `CachedCoverImage`:
```dart
// Old:
CachedNetworkImage(imageUrl: media.coverImage!)

// New:
CachedCoverImage(
  imageUrl: media.coverImage,
  mediaId: media.id,
  enableOfflineCache: true,
)
```

#### 3. Auto-Download After Sync (`lib/features/anime_list/presentation/pages/anime_list_page.dart`)
```dart
Future<void> _syncWithAniList() async {
  // ... sync logic ...
  
  // Download cover images in background after successful sync
  _downloadCoverImagesInBackground();
}

Future<void> _downloadCoverImagesInBackground() async {
  final imageCache = ImageCacheService();
  final allMedia = <({int mediaId, String? coverUrl})>[];
  
  // Collect all media from lists
  for (final entry in _animeList) {
    if (entry.media?.id != null && entry.media?.coverImage != null) {
      allMedia.add((mediaId: entry.media!.id, coverUrl: entry.media!.coverImage));
    }
  }
  // Same for manga and novels...
  
  // Download in background (non-blocking)
  imageCache.downloadBatch(allMedia);
}
```

#### 4. Profile Page Integration (`lib/features/profile/presentation/pages/profile_page.dart`)
Added Image Cache icon button to app bar:
```dart
IconButton(
  icon: const Icon(Icons.image),
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => const ImageCacheSettingsDialog(),
    );
  },
  tooltip: 'Image Cache',
)
```

## Technical Details

### Dependencies Added
```yaml
dependencies:
  http: ^1.2.2          # For downloading images
  path_provider: ^2.1.5 # For local storage paths
  crypto: ^3.0.6        # For URL hashing
```

### Storage Strategy

**Why Not Use CachedNetworkImage's Cache?**
- HTTP cache is temporary and cleared by OS
- Need persistent storage for offline access
- Want explicit control over cache lifecycle
- Need to cleanup when media removed from list

**Filename Generation**:
```dart
String _generateFilename(String url, int mediaId) {
  final urlHash = md5.convert(utf8.encode(url)).toString().substring(0, 8);
  final extension = url.split('.').last.split('?').first;
  return '${mediaId}_$urlHash.$extension';
}
```

**Why Use MediaId + URL Hash?**
- MediaId for easy deletion when entry removed
- URL hash handles URL changes (CDN migrations)
- Extension preserved for proper image format

### Error Handling

All operations use try-catch with graceful fallbacks:

1. **Download Failure**: Falls back to network image
2. **Local File Corrupted**: Falls back to network image
3. **Storage Full**: Logs error, continues with network images
4. **Permission Denied**: Uses network images only

### Performance Optimizations

1. **Non-Blocking Downloads**:
   ```dart
   imageCache.downloadBatch(allMedia).then((_) {
     debugPrint('Downloaded ${allMedia.length} images');
   }).catchError((e) {
     debugPrint('Error: $e');
   });
   ```

2. **Small Download Delay**:
   ```dart
   await Future.delayed(const Duration(milliseconds: 100));
   ```
   Prevents overwhelming the network with parallel requests.

3. **Check Before Download**:
   ```dart
   if (await file.exists()) {
     return file; // Skip if already cached
   }
   ```

4. **Batch Operations**:
   Download multiple images in one operation rather than separate calls.

## Usage Guidelines

### When to Enable Offline Cache

**✅ Enable (enableOfflineCache: true)**:
- User's anime list cards
- User's manga list cards
- User's novel list cards

**❌ Disable (enableOfflineCache: false)**:
- Public media detail pages
- Character detail pages
- Staff detail pages
- Studio detail pages
- Search results
- Global search results

**Reasoning**: Only cache images the user will frequently access offline (their list). Public pages can use network cache.

### Cache Maintenance

**Automatic Cleanup** (TODO):
```dart
// When sync completes, cleanup unused images
final activeMediaIds = [
  ..._animeList.map((e) => e.media?.id),
  ..._mangaList.map((e) => e.media?.id),
  ..._novelList.map((e) => e.media?.id),
].whereType<int>().toList();

await imageCache.cleanupUnusedImages(activeMediaIds);
```

**Manual Cleanup**:
Users can clear cache via Profile → Image Cache → Clear Cache

## Future Enhancements

### Priority 1: Cleanup Integration
```dart
// Add to sync completion
Future<void> _syncWithAniList() async {
  // ... sync logic ...
  
  // Download new images
  await _downloadCoverImagesInBackground();
  
  // Cleanup removed entries
  final activeIds = _getAllActiveMediaIds();
  await ImageCacheService().cleanupUnusedImages(activeIds);
}
```

### Priority 2: Download Progress
```dart
class ImageCacheService {
  final StreamController<double> _progressController = StreamController();
  Stream<double> get downloadProgress => _progressController.stream;
  
  Future<void> downloadBatch(...) async {
    for (int i = 0; i < mediaList.length; i++) {
      await downloadImage(...);
      _progressController.add((i + 1) / mediaList.length);
    }
  }
}
```

### Priority 3: Smart Pre-fetching
- Download images for "Planning" status media
- Pre-fetch next season's anime
- Background sync with low priority

### Priority 4: Storage Limits
```dart
// Add to settings
class CacheSettings {
  int maxCacheSizeMB = 500;
  bool autoCleanup = true;
  bool downloadOnCellular = false;
}
```

## Testing Checklist

- [x] Images download after sync
- [x] Images load from cache on restart
- [x] Fallback to network when cache missing
- [x] Cache statistics display correctly
- [x] Clear cache works
- [x] No blocking of UI during downloads
- [ ] Cleanup unused images
- [ ] Handle storage full scenarios
- [ ] Test with 1000+ list entries
- [ ] Test on mobile networks

## Known Limitations

1. **No Progress Indicator**: Background downloads are silent
2. **No Storage Limit**: Will download all list entries (could be large)
3. **No Cleanup on Entry Delete**: Cache persists after removing from list
4. **No Differential Sync**: Always re-downloads all images

## Performance Impact

**Storage Usage**:
- Average cover image: ~100-200 KB
- 500 entries: ~50-100 MB
- 1000 entries: ~100-200 MB

**Network Usage**:
- Initial sync: Downloads all images (~50-200 MB)
- Subsequent syncs: Only new entries
- Bandwidth: Throttled with 100ms delays

**App Performance**:
- No impact on startup (async initialization)
- No impact on UI (background downloads)
- Faster list scrolling (local images load instantly)

## Migration Notes

**Upgrading from Previous Versions**:
- First launch will initialize cache directory
- No data migration needed
- Existing network cache unaffected
- Users can manually trigger download by syncing

**Downgrading**:
- Cache directory remains but unused
- No errors, falls back to network images
- Users can manually delete `image_cache` folder

## Conclusion

This implementation provides a robust offline image caching system specifically optimized for user's list entries. The design prioritizes:

1. **User Experience**: Fast, offline-capable, non-intrusive
2. **Performance**: Non-blocking, batched operations
3. **Reliability**: Graceful fallbacks, error handling
4. **Maintainability**: Clean architecture, well-documented

The system is production-ready with room for future enhancements like automatic cleanup, progress indicators, and storage management.
