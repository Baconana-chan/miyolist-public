# Data-Driven Image Generation for Wrap-Up

## 🎯 Problem with Current Approach

### Screenshot-Based Export (Current):
```dart
// Uses GlobalKey to capture widget screenshot
Future<String?> captureWidgetWithBackground({
  required GlobalKey key,  // ❌ Limited by screen height!
  required String filename,
}) {
  // Can only capture what's visible on screen
  final RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject();
}
```

**Limitations:**
- ❌ **Limited by screen height** - Can't capture content taller than viewport
- ❌ **Depends on widget being rendered** - Must wait for UI to build
- ❌ **Performance impact** - Rendering large widgets is slow
- ❌ **Scrollable content** - Can't capture off-screen content
- ❌ **Fixed layout** - Bound by Flutter widget constraints

### Data-Driven Generation (NEW):
```dart
// Generates image directly from data using Canvas
Future<String?> generateWrapupImage({
  required WrapupData data,  // ✅ Pure data, no UI needed!
  required String filename,
}) {
  // Draw everything programmatically on Canvas
  // Can be any height, any layout, any design
}
```

**Advantages:**
- ✅ **Unlimited height** - Can create 10,000px tall images
- ✅ **No UI rendering** - Works in background
- ✅ **Better performance** - Direct Canvas drawing is fast
- ✅ **Full control** - Complete freedom over design
- ✅ **All data visible** - No scrolling needed

---

## 📊 New Data Model: `WrapupData`

```dart
class WrapupData {
  // === BASIC STATS ===
  final int totalEntries;      // Total anime/manga
  final int totalEpisodes;     // Episodes watched
  final int totalChapters;     // Chapters read
  final double daysWatched;    // Days spent watching
  final int year;              // Year of wrap-up
  
  // === SCORE DISTRIBUTION ===
  final Map<int, int> scoreDistribution; // score -> count
  // Example: {10: 350, 9: 150, 8: 100, ...}
  
  // === TOP GENRES ===
  final List<GenreCount> topGenres;
  // Example: [
  //   GenreCount(genre: "Comedy", count: 703),
  //   GenreCount(genre: "Action", count: 450),
  //   ...
  // ]
  
  // === ANALYTICS ===
  final double meanScore;          // Average rating
  
  // === OPTIONAL EXTENDED DATA ===
  final Map<String, int>? seasonalCounts;      // "Winter 2024" -> 50
  final Map<String, int>? statusCounts;        // "Completed" -> 715
  final Map<String, int>? formatCounts;        // "TV" -> 1200
  final List<String>? topStudios;              // Top 5 studios
  final String? mostWatchedDay;                // "Saturday"
  final int? longestBingeEpisodes;             // 24 episodes
}
```

---

## 🎨 Generated Image Structure

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  📊 GRADIENT HEADER (250px)                     │
│     "MiyoList 2024 Wrap-Up"                     │
│     "Your Year in Anime & Manga"                │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  📋 STAT CARDS (Grid 2x2)                       │
│  ┌──────────┐  ┌──────────┐                    │
│  │ 📋 2268  │  │ 📺 5256  │                    │
│  │ Entries  │  │ Episodes │                    │
│  └──────────┘  └──────────┘                    │
│  ┌──────────┐  ┌──────────┐                    │
│  │ 📖 3227  │  │ ⏱️ 87.6  │                    │
│  │ Chapters │  │ Days     │                    │
│  └──────────┘  └──────────┘                    │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  📊 SCORE DISTRIBUTION (Bar Chart)              │
│     Mean Score: 7.85                            │
│                                                 │
│     █                                           │
│     █      █                                    │
│  █  █   █  █  ███                               │
│  1  2   3  4  567   8    9    10               │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  🎭 TOP GENRES (Horizontal Bars)                │
│  #1  Comedy        [████████████████] 703       │
│  #2  Action        [████████████] 450           │
│  #3  Fantasy       [██████████] 380             │
│  #4  Romance       [████████] 320               │
│  #5  Drama         [███████] 290                │
│  ...                                            │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  📱 FOOTER                                       │
│     "Made with MiyoList 📊"                     │
│                                                 │
└─────────────────────────────────────────────────┘

Width: 1080px (Full HD)
Height: Dynamic (adjusts to content) - typically 2400-3000px
```

---

## 🚀 Usage Example

### 1. Prepare Data

```dart
// Collect statistics from local data
final stats = await _storageService.getUserStatistics();

// Create WrapupData object
final wrapupData = WrapupData(
  totalEntries: stats.totalAnime + stats.totalManga,
  totalEpisodes: stats.totalEpisodes,
  totalChapters: stats.totalChapters,
  daysWatched: stats.daysWatched,
  year: DateTime.now().year,
  
  // Score distribution (1-10)
  scoreDistribution: {
    1: 5,
    2: 10,
    3: 15,
    4: 20,
    5: 30,
    6: 50,
    7: 150,
    8: 350,
    9: 150,
    10: 30,
  },
  
  // Top genres
  topGenres: [
    GenreCount(genre: 'Comedy', count: 703),
    GenreCount(genre: 'Action', count: 450),
    GenreCount(genre: 'Fantasy', count: 380),
    GenreCount(genre: 'Romance', count: 320),
    GenreCount(genre: 'Drama', count: 290),
  ],
  
  meanScore: 7.85,
);
```

### 2. Generate Image

```dart
final exportService = ChartExportService();

// Generate wrap-up image (NO GlobalKey needed!)
final String? filepath = await exportService.generateWrapupImage(
  data: wrapupData,
  filename: 'miyolist_wrapup_2024',
  pixelRatio: 3.0, // High quality
);

if (filepath != null) {
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Wrap-up saved: $filepath')),
  );
}
```

### 3. Complete Integration Example

```dart
class StatisticsPage extends StatelessWidget {
  Future<void> _exportWrapup() async {
    // 1. Collect data from local storage
    final stats = await LocalStorageService().getUserStatistics();
    final animeList = await LocalStorageService().getAnimeList();
    
    // 2. Process data
    final scoreDistribution = _calculateScoreDistribution(animeList);
    final topGenres = _calculateTopGenres(animeList);
    
    // 3. Create WrapupData
    final wrapupData = WrapupData(
      totalEntries: stats.totalEntries,
      totalEpisodes: stats.totalEpisodes,
      totalChapters: stats.totalChapters,
      daysWatched: stats.daysWatched,
      year: DateTime.now().year,
      scoreDistribution: scoreDistribution,
      topGenres: topGenres,
      meanScore: stats.meanScore,
    );
    
    // 4. Generate image (background operation)
    final service = ChartExportService();
    final filepath = await service.generateWrapupImage(
      data: wrapupData,
      filename: 'wrapup_${DateTime.now().year}',
      pixelRatio: 3.0,
    );
    
    // 5. Show result
    if (filepath != null) {
      _showSuccessDialog(filepath);
    }
  }
  
  Map<int, int> _calculateScoreDistribution(List<MediaListEntry> entries) {
    final distribution = <int, int>{};
    for (final entry in entries) {
      final score = entry.score?.toInt() ?? 0;
      if (score > 0) {
        distribution[score] = (distribution[score] ?? 0) + 1;
      }
    }
    return distribution;
  }
  
  List<GenreCount> _calculateTopGenres(List<MediaListEntry> entries) {
    final genreCounts = <String, int>{};
    for (final entry in entries) {
      for (final genre in entry.media.genres ?? []) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
    }
    
    // Sort by count and take top 10
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedGenres.take(10).map((e) => 
      GenreCount(genre: e.key, count: e.value)
    ).toList();
  }
}
```

---

## 🎯 Comparison: Screenshot vs Data-Driven

### Screenshot Approach (OLD):
```dart
// ❌ Must render UI first
Widget buildStatisticsOverview() {
  return RepaintBoundary(
    key: _exportKey,  // GlobalKey for capture
    child: Column(  // ❌ Limited by screen height
      children: [
        StatsCard(...),
        ScoreChart(...),  // ❌ Might be cut off
        GenresChart(...), // ❌ Might not be visible
        // ❌ Can't show everything at once
      ],
    ),
  );
}

// Export (limited by viewport)
await exportService.captureWidgetWithBackground(
  key: _exportKey,  // ❌ Requires GlobalKey
  filename: 'stats',
);
```

### Data-Driven Approach (NEW):
```dart
// ✅ No UI rendering needed
final data = WrapupData(
  totalEntries: 2268,
  totalEpisodes: 5256,
  // ... all data here
);

// ✅ Generate directly from data
await exportService.generateWrapupImage(
  data: data,  // ✅ Pure data
  filename: 'wrapup_2024',
);

// ✅ Can include ALL data (no height limit)
// ✅ Works in background
// ✅ Faster and more reliable
```

---

## 🔧 Technical Implementation

### Canvas Drawing Methods

#### 1. `_drawText()` - Text rendering
```dart
void _drawText({
  required Canvas canvas,
  required String text,
  required double x,
  required double y,
  required double fontSize,
  required Color color,
  FontWeight? fontWeight,
  TextAlign textAlign = TextAlign.left,
  double maxWidth = double.infinity,
})
```

#### 2. `_drawStatCard()` - Stat card with icon
```dart
void _drawStatCard({
  required Canvas canvas,
  required double x,
  required double y,
  required double width,
  required double height,
  required String icon,     // Emoji: 📋 📺 📖 ⏱️
  required String value,    // "2268"
  required String label,    // "Total Entries"
})
```

#### 3. `_drawScoreDistribution()` - Bar chart
```dart
void _drawScoreDistribution({
  required Canvas canvas,
  required double x,
  required double y,
  required double width,
  required double height,
  required Map<int, int> scoreDistribution,
  required double meanScore,
})
```

#### 4. `_drawTopGenres()` - Horizontal bar list
```dart
void _drawTopGenres({
  required Canvas canvas,
  required double x,
  required double y,
  required double width,
  required List<GenreCount> genres,
})
```

### Color Scheme

```dart
// Background
const bgColor = Color(0xFF1A1A1A);

// Card background
const cardColor = Color(0xFF2A2A2A);

// Gradient header
const gradientColors = [
  Color(0xFF2196F3),  // Blue
  Color(0xFF1976D2),  // Dark blue
];

// Score-based colors
final scoreColors = {
  1-3:  Colors.red,         // Bad
  4-5:  Colors.orange,      // Below average
  6-7:  Colors.yellow,      // Average
  8-9:  Colors.lightGreen,  // Good
  10:   Colors.green,       // Perfect
};
```

---

## ✅ Benefits for Wrap-Up Feature

### 1. **Unlimited Content**
- Can include 50+ sections in one image
- No need to split into multiple exports
- Complete year overview in single file

### 2. **Performance**
- No UI rendering overhead
- Can generate in background
- Faster than screenshot approach

### 3. **Customization**
- Easy to add new sections
- Programmatic layout control
- Can adjust for different data sizes

### 4. **Reliability**
- No dependency on widget rendering
- Works even if UI is hidden
- Consistent output quality

### 5. **Future-Proof**
- Easy to extend with new data
- Can create different formats (social media, print, etc.)
- Support for localization

---

## 🚀 Next Steps for Wrap-Up

1. **Collect Annual Data**:
   ```dart
   - Total anime/manga watched this year
   - Seasonal breakdown (Winter, Spring, Summer, Fall)
   - Most watched genres
   - Completion stats
   - Binge sessions
   - Top rated shows
   ```

2. **Generate Wrap-Up Image**:
   ```dart
   - Create WrapupData object
   - Call generateWrapupImage()
   - Save to exports folder
   ```

3. **Share Feature**:
   ```dart
   - Generate image
   - Share on social media (Twitter, Instagram)
   - Include hashtags: #MiyoList #AnimeWrapUp2024
   ```

---

## 📝 Example Output

**File**: `miyolist_wrapup_2024_2025-01-15T12-30-45.png`
**Size**: ~500-800 KB (PNG, 1080x2500px)
**Location**: `C:\Users\VIC\Documents\MiyoList_Exports\`

---

## 🎉 Conclusion

**Data-driven generation** решает проблему ограничения высоты экрана и позволяет создавать **полноценные Wrap-up изображения** с всей статистикой года!

✅ **Готово к использованию** для годового отчета
✅ **Легко расширяется** новыми секциями
✅ **Быстрее** чем скриншоты
✅ **Надежнее** - не зависит от UI

---

**Version**: v1.1.0 "Botan (牡丹)"
**Feature**: Data-Driven Image Generation
**Status**: ✅ Ready for Wrap-Up Implementation
