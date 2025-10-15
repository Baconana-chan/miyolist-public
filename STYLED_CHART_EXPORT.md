# Enhanced Chart Export with Styled Background

## 📋 Overview
Улучшенный экспорт графиков статистики с профессиональным оформлением - тёмный фон, заголовок с градиентом, и брендинг "Made with MiyoList 📊".

## ✨ Features
- **Dark Background (#1A1A1A)**: Тёмный фон для лучшей читаемости текста
- **Gradient Header**: Синий градиент (Color(0xFF2196F3) → Color(0xFF1976D2))
- **Title & Subtitle**: Крупный заголовок (48px) и подзаголовок с датой (28px)
- **Content Padding**: 10% отступы по бокам, 50px сверху от header
- **Footer Branding**: "Made with MiyoList 📊" в footer
- **High Resolution**: 3x pixel ratio для качественного экспорта
- **Auto Date**: Автоматическая дата в формате "MMMM dd, yyyy"

## 🎨 Export Layout
```
┌────────────────────────────────────┐
│  Gradient Header (150px)           │
│    Title (48px bold white)         │
│    Date (28px white 90%)           │
├────────────────────────────────────┤
│  Content with padding (50px top)   │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │   Original Chart Content     │  │
│  │   (Full statistics widget)   │  │
│  │                              │  │
│  └──────────────────────────────┘  │
│                                    │
├────────────────────────────────────┤
│  Footer (100px)                    │
│  "Made with MiyoList 📊"           │
└────────────────────────────────────┘
```

## 📐 Dimensions
- **Width**: Content width + 10% padding
- **Height**: Content height + 300px (150px header + 50px spacing + 100px footer)
- **Resolution**: 3x pixel ratio (default)

## 🎯 Tab Titles
Each tab has a specific title:
- **Overview Tab**: "MiyoList Statistics Overview"
- **Activity Tab**: "Activity History"
- **Anime Tab**: "Anime Statistics"
- **Manga Tab**: "Manga Statistics"
- **Timeline Tab**: "Watching Timeline"

## 📊 Methods

### captureWidgetWithBackground()
```dart
Future<String?> captureWidgetWithBackground({
  required GlobalKey key,
  required String filename,
  String? title,
  String? subtitle,
  double pixelRatio = 3.0,
})
```

**Parameters:**
- `key`: GlobalKey of the RepaintBoundary widget
- `filename`: Base filename (without extension)
- `title`: Title text (if null, no title shown)
- `subtitle`: Subtitle text (if null, shows current date)
- `pixelRatio`: Image resolution multiplier (default: 3.0)

**Returns:** Filepath to saved PNG or null on error

**Usage:**
```dart
final filepath = await _exportService.captureWidgetWithBackground(
  key: _overviewKey,
  filename: 'miyolist_overview',
  title: 'MiyoList Statistics Overview',
  pixelRatio: 3.0,
);
```

### captureAndShareWidgetWithBackground()
```dart
Future<bool> captureAndShareWidgetWithBackground({
  required GlobalKey key,
  required String filename,
  String? title,
  String? subtitle,
  String? text,
  double pixelRatio = 3.0,
})
```

**Parameters:**
- Same as `captureWidgetWithBackground()` plus:
- `text`: Share dialog message (default: "Check out my MiyoList statistics! 📊")

**Returns:** `true` if shared successfully, `false` otherwise

**Usage:**
```dart
final success = await _exportService.captureAndShareWidgetWithBackground(
  key: _animeKey,
  filename: 'miyolist_anime',
  title: 'Anime Statistics',
  text: 'My anime statistics 📺',
  pixelRatio: 3.0,
);
```

## 🎨 Color Scheme
```dart
Background: Color(0xFF1A1A1A)
Gradient Start: Color(0xFF2196F3)
Gradient End: Color(0xFF1976D2)
Title: Colors.white (bold)
Subtitle: Colors.white.withOpacity(0.9)
Footer: Colors.white.withOpacity(0.7)
```

## 📱 Platform Support
- **Windows**: Saves to `%USERPROFILE%\Downloads`
- **Android**: Saves to `/storage/emulated/0/Download`
- **Other**: Saves to app documents directory

## 🔄 Integration
Updated in `statistics_page.dart`:
- `_exportCurrentTab()`: Uses `captureWidgetWithBackground()`
- `_shareCurrentTab()`: Uses `captureAndShareWidgetWithBackground()`

## 📝 File Naming
Format: `{filename}_{timestamp}.png`
- Timestamp: ISO 8601 format with colons replaced by dashes
- Example: `miyolist_overview_2024-01-15T12-30-45.png`

## 🎯 Usage Flow
1. User taps **Download** button in AppBar
2. Shows loading SnackBar with spinner
3. Waits 300ms for chart to fully render
4. Captures widget with styled background
5. Shows success SnackBar with filepath
6. User can tap **SHARE** button to share via system dialog

## ✅ Benefits
- **Better Readability**: Dark background ensures text visibility on any surface
- **Professional Look**: Gradient header and branding add polish
- **User-Friendly**: Dates and titles provide context
- **Shareable**: Perfect for social media (Discord, Twitter, Reddit)
- **High Quality**: 3x resolution ensures crisp images
- **Consistent Branding**: "Made with MiyoList" promotes the app

## 🔜 Future Enhancements
- [ ] Add username to header (e.g., "@username's Statistics")
- [ ] Add small MiyoList logo/avatar
- [ ] Theme selection (Light/Dark backgrounds)
- [ ] Custom colors for branding
- [ ] Export multiple tabs as collage
- [ ] PDF export option

## 📦 Dependencies
- `dart:ui` (Canvas, ParagraphBuilder)
- `intl` (DateFormat)
- `path_provider` (Directory paths)
- `share_plus` (Sharing functionality)

---

**Last Updated**: v1.1.0 (Botan 牡丹)
**Feature Status**: ✅ Complete and Tested
