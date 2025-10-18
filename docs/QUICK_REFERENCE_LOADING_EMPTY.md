# Quick Reference: Loading Skeletons & Empty States

**For Developers** | Last Updated: Oct 11, 2025

---

## 🚀 Quick Start

### Add Loading Skeleton to Your Page

```dart
// 1. Import
import 'package:miyolist/core/widgets/media_card_skeleton.dart';

// 2. Show during loading
if (_isLoading) {
  return const MediaGridSkeleton(itemCount: 12);
}

// 3. Show real content when loaded
return GridView.builder(...);
```

### Add Empty State to Your Page

```dart
// 1. Import
import 'package:miyolist/core/widgets/empty_state_widget.dart';

// 2. Check if empty
if (items.isEmpty) {
  // Use factory constructor
  return EmptyStateWidget.noEntriesAtAll(isAnime: true);
}

// 3. Show real content
return ListView.builder(...);
```

---

## 📦 Available Widgets

### Loading Skeletons

| Widget | Use Case | Default Count |
|--------|----------|---------------|
| `MediaGridSkeleton` | Anime/Manga lists | 12 cards |
| `SearchResultListSkeleton` | Search results | 8 items |
| `MediaCardSkeleton` | Single card | 1 card |
| `SearchResultSkeleton` | Single result | 1 item |

### Empty States

| Factory Method | Use Case |
|----------------|----------|
| `.noSearchResults()` | No search matches |
| `.noEntriesInStatus()` | Empty status filter |
| `.noEntriesAtAll()` | New user, empty list |
| `.noFilterResults()` | Filters exclude all |

---

## 💻 Code Examples

### Example 1: Media List Page

```dart
Widget build(BuildContext context) {
  // Show skeleton during load
  if (_isLoading) {
    return const MediaGridSkeleton(itemCount: 12);
  }
  
  // Check empty state
  if (_entries.isEmpty) {
    if (_searchQuery.isNotEmpty) {
      return EmptyStateWidget.noSearchResults(
        query: _searchQuery,
        onClearSearch: () => setState(() => _searchQuery = ''),
      );
    }
    return EmptyStateWidget.noEntriesAtAll(isAnime: true);
  }
  
  // Show content
  return GridView.builder(
    itemCount: _entries.length,
    itemBuilder: (context, index) => MediaCard(...),
  );
}
```

### Example 2: Search Page

```dart
Widget _buildBody() {
  // Show skeleton
  if (_isLoading) {
    return const SearchResultListSkeleton(itemCount: 8);
  }
  
  // Show empty state
  if (_results.isEmpty) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No results',
      description: 'Try different keywords',
    );
  }
  
  // Show results
  return ListView.builder(
    itemCount: _results.length,
    itemBuilder: (context, index) => ResultCard(...),
  );
}
```

### Example 3: Custom Empty State

```dart
// For special cases, use custom constructor
return EmptyStateWidget(
  icon: Icons.favorite_border,
  iconColor: AppTheme.accentRed,
  title: 'No favorites yet',
  description: 'Add some favorites to see them here!',
  actionLabel: 'Browse Anime',
  onActionPressed: () => _navigateToSearch(),
);
```

---

## 🎨 Customization

### Change Skeleton Item Count

```dart
// Default: 12 cards
const MediaGridSkeleton()

// Custom: 6 cards
const MediaGridSkeleton(itemCount: 6)

// Custom: 20 cards
const MediaGridSkeleton(itemCount: 20)
```

### Change Skeleton Colors

```dart
// Use ShimmerLoading directly
ShimmerLoading(
  baseColor: Colors.grey[800]!,
  highlightColor: Colors.grey[700]!,
  child: YourWidget(),
)
```

### Custom Empty State Icon

```dart
EmptyStateWidget(
  icon: Icons.cloud_off,           // Your icon
  iconColor: Colors.blue,          // Custom color
  title: 'Offline',
  description: 'Check connection',
  actionLabel: 'Retry',
  onActionPressed: () => _retry(),
)
```

---

## 🔧 Common Patterns

### Pattern 1: Loading → Empty → Content

```dart
if (_isLoading) return Skeleton;
if (_data.isEmpty) return EmptyState;
return Content;
```

### Pattern 2: Search with Loading

```dart
if (_isSearching) return SearchSkeleton;
if (_query.isEmpty) return InitialState;
if (_results.isEmpty) return NoResults;
return ResultsList;
```

### Pattern 3: Filter with Empty

```dart
if (_isLoading) return Skeleton;
if (_filtered.isEmpty && _hasFilters) {
  return EmptyStateWidget.noFilterResults(...);
}
if (_filtered.isEmpty) {
  return EmptyStateWidget.noEntriesAtAll(...);
}
return FilteredList;
```

---

## ⚠️ Common Mistakes

### ❌ Don't: Show skeleton after content loaded

```dart
// Bad
if (_isLoading || _data.isEmpty) {
  return Skeleton;
}
```

**Why?** Shows skeleton even when data exists.

### ✅ Do: Check loading first

```dart
// Good
if (_isLoading) return Skeleton;
if (_data.isEmpty) return EmptyState;
return Content;
```

### ❌ Don't: Generic empty message

```dart
// Bad
if (_data.isEmpty) {
  return Text('No data');
}
```

**Why?** Not helpful or engaging.

### ✅ Do: Use context-aware empty state

```dart
// Good
if (_data.isEmpty) {
  return EmptyStateWidget.noEntriesAtAll(isAnime: true);
}
```

### ❌ Don't: Forget to dispose animations

```dart
// Bad - widget doesn't auto-dispose
// (Not applicable here, our widgets handle it!)
```

### ✅ Do: Use our widgets (auto-handled)

```dart
// Good - ShimmerLoading auto-disposes
return const MediaGridSkeleton();
```

---

## 🐛 Troubleshooting

### Skeleton not animating?

**Check:**
1. Widget is visible (not behind loading indicator)
2. Parent allows animation (not const)
3. Widget is mounted

**Fix:**
```dart
// Ensure not const parent
return MediaGridSkeleton(); // ✅
return const MediaGridSkeleton(); // ❌ (if parent is const)
```

### Empty state not showing?

**Check:**
1. Data is actually empty (`_data.length == 0`)
2. Loading is false (`_isLoading == false`)
3. Widget is in correct position in tree

**Debug:**
```dart
print('Loading: $_isLoading');
print('Data length: ${_data.length}');
if (_isLoading) return Skeleton;
if (_data.isEmpty) {
  print('Showing empty state');
  return EmptyState;
}
```

### Action button not working?

**Check:**
1. Callback is provided
2. Callback is not null
3. setState called in callback

**Fix:**
```dart
EmptyStateWidget.noSearchResults(
  query: _query,
  onClearSearch: () {
    setState(() {
      _query = '';
      _results = [];
    });
  },
)
```

---

## 📊 Performance Tips

### 1. Use const where possible

```dart
// Good
const MediaGridSkeleton()
const SearchResultListSkeleton()

// Better (if values are const)
const MediaGridSkeleton(itemCount: 12)
```

### 2. Don't create unnecessary skeletons

```dart
// Bad
if (_isLoading) return MediaGridSkeleton(itemCount: _data.length);

// Good
if (_isLoading) return const MediaGridSkeleton();
```

### 3. Dispose properly (auto-handled)

Our widgets auto-dispose animations, but if you create custom ones:

```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

---

## 🎯 Best Practices

### 1. Show skeleton immediately

```dart
@override
void initState() {
  super.initState();
  _loadData(); // Don't await here
}

@override
Widget build(BuildContext context) {
  if (_isLoading) return Skeleton; // Shows instantly
  return Content;
}
```

### 2. Use appropriate skeleton type

- Grid content → `MediaGridSkeleton`
- List content → `SearchResultListSkeleton`
- Custom layout → `ShimmerLoading` + custom

### 3. Always provide empty state guidance

```dart
// ❌ Bad
return Text('Empty');

// ✅ Good
return EmptyStateWidget.noEntriesAtAll(isAnime: true);
```

### 4. Make empty states actionable

```dart
// ✅ With action
EmptyStateWidget.noSearchResults(
  query: _query,
  onClearSearch: () => _clearSearch(),
)

// ⚠️ Without action (only if truly nothing to do)
EmptyStateWidget(icon: Icons.inbox, title: 'Empty')
```

---

## 📚 Related Documentation

- **Full Guide:** [LOADING_EMPTY_STATES.md](./LOADING_EMPTY_STATES.md)
- **Before/After:** [BEFORE_AFTER_LOADING_EMPTY.md](./BEFORE_AFTER_LOADING_EMPTY.md)
- **Implementation:** [IMPLEMENTATION_SUMMARY_LOADING_EMPTY.md](./IMPLEMENTATION_SUMMARY_LOADING_EMPTY.md)

---

## 🆘 Need Help?

### Check existing implementations
- `anime_list_page.dart` - Full example with all patterns
- `search_page.dart` - Search-specific patterns
- `global_search_page.dart` - Multi-type search

### Common questions

**Q: Can I use skeletons for other widgets?**  
A: Yes! Use `ShimmerLoading` with your custom widget.

**Q: How do I change animation speed?**  
A: Wrap in `ShimmerLoading(duration: Duration(...), child: ...)`.

**Q: Can I have multiple empty states?**  
A: Yes! Use factory constructors or custom `EmptyStateWidget`.

---

**Last Updated:** October 11, 2025  
**Version:** v1.4.0
