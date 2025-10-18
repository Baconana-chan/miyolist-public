# Theme System Documentation

## Overview

MiyoList now features a flexible multi-theme system that allows users to choose between different color schemes. The system is designed to be easily extensible, making it simple to add new themes in the future.

## Available Themes

### 1. Dark Theme (Default) 🌙
**Value:** `dark`

The original manga-style theme with dark backgrounds and red/blue accents.

**Colors:**
- Background: `#121212` (Primary), `#1A1A1A` (Secondary)
- Card: `#1E1E1E`
- Text: `#FFFFFF` (Primary), `#B0B0B0` (Secondary)
- Accent: `#E63946` (Red), `#457B9D` (Blue)

**Best for:** Night-time use, reducing eye strain

### 2. Light Theme ☀️
**Value:** `light`

A clean, bright theme with light backgrounds and vibrant accents.

**Colors:**
- Background: `#F5F5F5` (Primary), `#FFFFFF` (Secondary)
- Card: `#FFFFFF`
- Text: `#1A1A1A` (Primary), `#666666` (Secondary)
- Accent: `#D32F2F` (Red), `#1976D2` (Blue)

**Best for:** Daytime use, well-lit environments

### 3. Carrot Theme 🥕
**Value:** `carrot`

A unique warm theme featuring orange and golden tones inspired by carrots.

**Colors:**
- Background: `#1A1410` (Primary), `#2A2018` (Secondary)
- Card: `#332820`
- Text: `#FFF8F0` (Primary), `#D4C4B0` (Secondary)
- Accent: `#FF6B35` (Carrot Orange), `#F7931E` (Golden)
- Success: `#8BC34A` (Green leaves)

**Best for:** Users who want a unique, cozy aesthetic

## Architecture

### Core Components

#### 1. `ThemeColors` (Abstract Class)
**File:** `lib/core/theme/theme_colors.dart`

Base class defining the color contract for all themes:
- Background colors (primary, secondary, card)
- Text colors (primary, secondary, tertiary)
- Accent colors (primary, secondary, tertiary)
- Status colors (success, warning, error, info)
- Special colors (divider, shadow)
- Brightness (dark/light)

#### 2. Theme Implementations
**File:** `lib/core/theme/theme_colors.dart`

- `DarkThemeColors` - Implements dark theme
- `LightThemeColors` - Implements light theme
- `CarrotThemeColors` - Implements carrot theme

#### 3. `AppThemeMode` (Enum)
**File:** `lib/core/theme/theme_mode_enum.dart`

Enum defining available themes:
```dart
enum AppThemeMode {
  dark('Dark', 'dark'),
  light('Light', 'light'),
  carrot('Carrot 🥕', 'carrot');
}
```

Properties:
- `label` - Display name for UI
- `value` - Storage value
- `fromValue()` - Convert storage value to enum

#### 4. `AppTheme` (Static Class)
**File:** `lib/core/theme/app_theme.dart`

Central theme manager:
- `getThemeColors(mode)` - Get color scheme for a theme
- `getTheme(mode)` - Build complete ThemeData
- `updateColors(mode)` - Update current colors
- `colors` - Access current theme colors

#### 5. `ThemeProvider` (ChangeNotifier)
**File:** `lib/core/providers/theme_provider.dart`

State management for theme:
- Loads theme from storage on init
- `setTheme(mode)` - Change theme and save
- `cycleTheme()` - Quick switch between themes
- Notifies listeners on theme change

### Data Flow

```
User selects theme in UI
       ↓
ThemeProvider.setTheme()
       ↓
Save to UserSettings (Hive)
       ↓
AppTheme.updateColors()
       ↓
notifyListeners()
       ↓
MaterialApp rebuilds with new theme
```

## Usage

### Accessing Current Theme Colors

```dart
// In widgets
final colors = AppTheme.colors;
Container(
  color: colors.primaryBackground,
  child: Text(
    'Hello',
    style: TextStyle(color: colors.primaryText),
  ),
)
```

### Changing Theme

```dart
// Using provider
final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
await themeProvider.setTheme(AppThemeMode.carrot);

// Cycle through themes
await themeProvider.cycleTheme();
```

### UI Integration

Theme selector is integrated into Privacy Settings Dialog:
- Visual preview of each theme
- Color scheme display
- Description of each theme
- Radio-button style selection
- Instant preview on selection

## Adding New Themes

### Step 1: Create Color Class

```dart
// In theme_colors.dart
class MyNewThemeColors implements ThemeColors {
  @override
  Color get primaryBackground => const Color(0xFF...);
  
  @override
  Color get secondaryBackground => const Color(0xFF...);
  
  // ... implement all required colors
  
  @override
  Brightness get brightness => Brightness.dark; // or light
}
```

### Step 2: Add to Enum

```dart
// In theme_mode_enum.dart
enum AppThemeMode {
  dark('Dark', 'dark'),
  light('Light', 'light'),
  carrot('Carrot 🥕', 'carrot'),
  myNewTheme('My Theme ✨', 'my_theme'), // Add here
}
```

### Step 3: Add to Theme Factory

```dart
// In app_theme.dart
static ThemeColors getThemeColors(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.dark:
      return DarkThemeColors();
    case AppThemeMode.light:
      return LightThemeColors();
    case AppThemeMode.carrot:
      return CarrotThemeColors();
    case AppThemeMode.myNewTheme:
      return MyNewThemeColors(); // Add here
  }
}
```

### Step 4: Add Description

```dart
// In privacy_settings_dialog.dart
String _getThemeDescription(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.dark:
      return 'Classic manga-style dark theme';
    case AppThemeMode.light:
      return 'Clean and bright light theme';
    case AppThemeMode.carrot:
      return 'Warm orange tones with carrot vibes';
    case AppThemeMode.myNewTheme:
      return 'Description of my new theme'; // Add here
  }
}
```

That's it! Your new theme will automatically appear in the theme selector.

## Storage

Theme preference is stored in `UserSettings` (Hive):
- **Field:** `themeMode` (String)
- **HiveField:** 13
- **Default:** `'dark'`
- **Values:** `'dark'`, `'light'`, `'carrot'`, or any future theme

## Backward Compatibility

### Legacy Color Constants

Old color constants remain available for backward compatibility:
```dart
AppTheme.accentRed  // #E63946
AppTheme.accentBlue // #457B9D
AppTheme.cardGray   // #1E1E1E
// etc.
```

### Migration

Existing code using `AppTheme.darkTheme` still works:
```dart
// Old code (still works)
theme: AppTheme.darkTheme

// New code (preferred)
theme: themeProvider.currentTheme
```

## Testing

### Manual Testing Checklist

- [ ] Switch between all 3 themes
- [ ] Verify colors update across all screens
- [ ] Check text readability in each theme
- [ ] Test theme persistence (close/reopen app)
- [ ] Verify theme selector UI
- [ ] Test on different screen sizes

### Visual Verification

For each theme, check:
- Backgrounds (primary, secondary, card)
- Text colors (primary, secondary)
- Accent colors (buttons, highlights)
- Status indicators (success, error, warning)
- Dividers and borders
- Shadows and elevations

## Performance Considerations

### Optimization

- Theme colors are cached in `AppTheme._colors`
- Only one `ThemeData` instance per theme
- Provider pattern prevents unnecessary rebuilds
- Theme change triggers single rebuild

### Best Practices

1. Access colors via `AppTheme.colors` (cached)
2. Use `listen: false` when changing theme
3. Avoid creating theme-dependent widgets in build()
4. Prefer `Theme.of(context)` for standard properties

## Future Enhancements

### Planned Features

1. **Auto Theme Switching**
   - Follow system theme
   - Time-based switching (dark at night)
   - Location-based (sunset/sunrise)

2. **Custom Themes**
   - User-created color schemes
   - Color picker for each element
   - Import/export theme files

3. **Theme Previews**
   - Live preview without applying
   - Side-by-side comparison
   - Screenshot of current screen in different themes

4. **Accessibility Themes**
   - High contrast mode
   - Colorblind-friendly palettes
   - Adjustable text size

5. **Community Themes**
   - Share custom themes
   - Browse theme gallery
   - Rate and favorite themes

## Troubleshooting

### Theme Not Changing

**Problem:** Theme doesn't update after selection

**Solution:**
```dart
// Ensure provider is wrapped around MaterialApp
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider(...)),
  ],
  child: MyApp(),
)
```

### Colors Not Updating

**Problem:** Some widgets show old colors

**Solution:**
```dart
// Use AppTheme.colors instead of hardcoded values
Container(
  color: AppTheme.colors.primaryBackground, // ✅
  // NOT: color: AppTheme.backgroundGray,   // ❌
)
```

### Theme Resets on Restart

**Problem:** Theme goes back to dark on app restart

**Solution:**
- Check `UserSettings` is being saved
- Verify Hive box initialization
- Ensure `ThemeProvider` loads from storage in constructor

## Performance Optimizations

### Fetch Cooldown on Theme Change

When changing themes, the app rebuilds `AnimeListPage`, which could trigger unnecessary data fetches from AniList. To prevent this:

**Implementation:**
```dart
// Static cooldown tracking
static DateTime? _lastFetchTime;
static const _fetchCooldown = Duration(minutes: 5);

// Check cooldown before fetching
if (_lastFetchTime == null || now.difference(_lastFetchTime!) > _fetchCooldown) {
  _fetchLatestFromAniList();
  _lastFetchTime = now;
}
```

**Benefits:**
- ✅ No redundant API calls on theme change
- ✅ Faster theme switching
- ✅ Reduced rate limit concerns
- ✅ Better user experience

**How it works:**
1. First app load → fetch data from AniList (sets timestamp)
2. User changes theme → app rebuilds
3. `initState` checks timestamp → cooldown active
4. Skip fetch, use cached local data
5. After 5 minutes → cooldown expires, next rebuild will fetch

**Manual refresh:**
- Sync button always works (updates timestamp)
- Background sync still functions normally

## Related Documentation

- [UserSettings Model](../core/models/user_settings.dart)
- [Privacy Settings Dialog](../features/profile/presentation/widgets/privacy_settings_dialog.dart)
- [App Theme](../core/theme/app_theme.dart)

## Version History

- **v1.4.0** - Initial multi-theme system
  - Dark theme (manga-style)
  - Light theme
  - Carrot theme 🥕
  - Theme selector UI
  - Persistent theme storage
  - Fetch cooldown optimization

---

**Last Updated:** October 11, 2025  
**Maintained by:** MiyoList Development Team
