# Custom Themes System 🎨

**Status:** ✅ Completed  
**Date:** October 15, 2025  
**Version:** v1.1.0-dev

## Overview

The Custom Themes system allows users to create, edit, and manage their own color themes for MiyoList. Users can fully customize all 15 theme colors to create a unique visual experience.

## Features

### ✅ Theme Management
- **Create themes** - Build custom themes from scratch
- **Edit themes** - Modify existing custom themes
- **Duplicate themes** - Copy built-in or custom themes
- **Delete themes** - Remove custom themes (built-ins are protected)
- **Export/Import** - Share themes via JSON

### ✅ Theme Editor
- **Visual color picker** - Interactive color selection using flutter_colorpicker
- **Real-time preview** - See changes immediately
- **15 customizable colors**:
  - Background colors (3): Primary, Secondary, Card
  - Text colors (3): Primary, Secondary, Tertiary
  - Accent colors (3): Primary, Secondary, Tertiary
  - Status colors (4): Success, Warning, Error, Info
  - Special colors (2): Divider, Shadow
- **Dark/Light mode toggle** - Choose brightness

### ✅ Built-in Themes
Three default themes included:
1. **Dark (Original)** - Manga-style dark theme
2. **Light** - Clean light theme
3. **Carrot 🥕** - Warm orange-accented dark theme

## Architecture

### Models

**CustomTheme** (`lib/core/models/custom_theme.dart`)
```dart
@HiveType(typeId: 23)
class CustomTheme extends HiveObject {
  final String id;
  final String name;
  final String? description;
  
  // 15 color fields (stored as int)
  final int primaryBackground;
  final int secondaryBackground;
  // ... etc
  
  final bool isDark;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault; // Protected built-in theme
}
```

### Services

**CustomThemesService** (`lib/core/services/custom_themes_service.dart`)
- Manages Hive box `custom_themes`
- CRUD operations for themes
- Built-in theme initialization
- Export/Import functionality
- Duplicate theme support

### UI Components

**CustomThemesPage** (`lib/features/themes/custom_themes_page.dart`)
- List all themes (built-in + custom)
- Theme cards with color preview
- Actions: Edit, Duplicate, Export, Delete

**ThemeEditorPage** (`lib/features/themes/theme_editor_page.dart`)
- Visual theme editor
- Color picker dialogs
- Live preview section
- Save/Cancel actions

## Usage

### Access
1. Open **Profile Page**
2. Click **Settings** (⋮) menu
3. Select **Custom Themes** 🎨

### Create New Theme
1. Click **+** button in Custom Themes page
2. Enter theme name and description
3. Toggle Dark/Light mode
4. Tap on any color to open color picker
5. Select desired colors
6. Click **Save** ✓

### Edit Existing Theme
1. Tap on theme card
2. Modify colors as needed
3. Click **Save**

**Note:** Built-in themes cannot be edited directly, but can be duplicated for customization.

### Duplicate Theme
1. Click **Duplicate** button on theme card
2. Enter new theme name
3. Theme is copied with all colors
4. Edit the duplicate as needed

### Export Theme
1. Click **Export** button on theme card
2. JSON data is shown in dialog
3. Copy to clipboard or save to file
4. Share with others!

### Delete Theme
1. Click **Delete** button on custom theme card
2. Confirm deletion
3. Theme is permanently removed

**Note:** Built-in themes cannot be deleted.

## Theme Structure (JSON Export)

```json
{
  "name": "My Custom Theme",
  "description": "A beautiful custom theme",
  "colors": {
    "primaryBackground": 1184274,
    "secondaryBackground": 1710618,
    "cardBackground": 1973790,
    "primaryText": 4294967295,
    "secondaryText": 2960685,
    "tertiaryText": 2172287,
    "primaryAccent": 4289396006,
    "secondaryAccent": 4282664349,
    "tertiaryAccent": 741677,
    "success": 4283215696,
    "warning": 4294940928,
    "error": 4289396006,
    "info": 4282664349,
    "divider": 741677,
    "shadow": 4278190080
  },
  "isDark": true
}
```

## Technical Details

### Dependencies
- `flutter_colorpicker: ^1.1.0` - Color picker widget
- `hive: ^2.2.3` - Local storage
- `provider: ^6.1.2` - State management

### Storage
- **Box name:** `custom_themes`
- **Type ID:** 23 (CustomTheme adapter)
- **Location:** Hive local storage

### Initialization
Custom themes service is initialized in `main.dart`:
```dart
final customThemesService = CustomThemesService();
await customThemesService.init();

// Provided via Provider
Provider<CustomThemesService>.value(value: customThemesService)
```

### Built-in Theme Protection
- `isDefault: true` flag marks built-in themes
- Cannot be edited or deleted
- Can be duplicated for customization
- Always appear first in theme list

## Color System

### Color Categories

**Backgrounds** (Dark/Light surfaces)
- Primary: Main app background
- Secondary: Navigation bars, headers
- Card: Content cards, dialogs

**Text** (Contrast with backgrounds)
- Primary: Main text, headings
- Secondary: Descriptions, labels
- Tertiary: Subtle text, hints

**Accents** (Highlighted elements)
- Primary: Main accent (buttons, links)
- Secondary: Alternative accent
- Tertiary: Tertiary accent

**Status** (Semantic colors)
- Success: Positive actions ✓
- Warning: Cautions ⚠
- Error: Errors, deletions ✗
- Info: Informational ℹ

**Special** (Borders, shadows)
- Divider: Separators, borders
- Shadow: Drop shadows, elevation

## Future Enhancements

### Planned Features (v1.2.0+)
- [ ] **Apply custom themes** - Use custom themes in app
- [ ] **Theme presets** - Pre-made theme templates
- [ ] **Community themes** - Download themes from others
- [ ] **Gradient support** - Gradient backgrounds
- [ ] **Theme categories** - Organize themes by style
- [ ] **Theme search** - Find themes by name/color
- [ ] **Color suggestions** - AI-powered color recommendations
- [ ] **Accessibility check** - Contrast ratio validation

## Benefits

✅ **Full Personalization** - Create unique visual identity  
✅ **Easy Sharing** - Export themes as JSON  
✅ **Safe Experimentation** - Built-ins are protected  
✅ **Visual Editor** - No code required  
✅ **Live Preview** - See changes immediately  
✅ **Unlimited Themes** - Create as many as you want  

## Known Limitations

1. **Theme application not yet implemented** - Themes can be created but not applied (Coming in v1.2.0)
2. **Import via dialog only** - No file picker integration yet
3. **No undo/redo** - Changes are immediate
4. **No color history** - Recent colors not saved

## Changelog

### v1.1.0-dev (October 15, 2025)
- ✅ Initial implementation
- ✅ CustomTheme model with Hive
- ✅ CustomThemesService
- ✅ ThemeEditorPage with color picker
- ✅ CustomThemesPage with theme management
- ✅ Export/Import functionality
- ✅ Built-in themes (Dark, Light, Carrot)
- ✅ Integration with Profile page

---

**Next Steps:**
1. Implement theme application system
2. Add theme preview before applying
3. Create community theme repository
4. Add theme sharing via URL
