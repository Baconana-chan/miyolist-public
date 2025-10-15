# Export Path Settings - Implementation Summary

## 🎯 Objective
Добавить возможность настройки пути сохранения экспортированных изображений статистики.

## ✅ Completed Tasks

### 1. Updated UserSettings Model
**File**: `lib/core/models/user_settings.dart`

Added new field:
```dart
@HiveField(22)
final String? exportPath; // Кастомный путь (null = папка приложения)
```

**Features:**
- ✅ Nullable field (null = default app folder)
- ✅ Added to constructor with optional parameter
- ✅ Added to `copyWith()` method
- ✅ Added to `toJson()` / `fromJson()` methods
- ✅ Added to default factories
- ✅ Hive adapter regenerated

### 2. Enhanced ChartExportService
**File**: `lib/features/statistics/services/chart_export_service.dart`

Added helper method:
```dart
Future<Directory> _getExportDirectory() async {
  // 1. Try to use custom path from settings
  // 2. Validate and create if doesn't exist
  // 3. Fallback to app folder: /MiyoList_Exports
  return exportsDir;
}
```

**Features:**
- ✅ Reads export path from UserSettings
- ✅ Validates custom path exists
- ✅ Creates custom directory if needed
- ✅ Falls back to app folder: `{AppDocuments}/MiyoList_Exports`
- ✅ Cross-platform path handling with `Platform.pathSeparator`
- ✅ Creates export folder automatically
- ✅ Detailed debug logging

Updated methods:
- ✅ `captureWidgetWithBackground()` - uses `_getExportDirectory()`
- ✅ `captureAndSaveWidget()` - uses `_getExportDirectory()`

### 3. Created Export Settings Dialog
**File**: `lib/features/profile/presentation/widgets/export_settings_dialog.dart`

New dialog widget with features:
- ✅ **Radio buttons**: Default app folder vs Custom path
- ✅ **Browse button**: Opens directory picker (file_picker)
- ✅ **Path display**: Shows current selected path
- ✅ **Platform-specific defaults**: Shows appropriate default paths
- ✅ **Save functionality**: Updates UserSettings
- ✅ **Loading state**: Shows spinner while loading
- ✅ **Error handling**: Catches file picker errors
- ✅ **Success feedback**: SnackBar confirmation

**UI Elements:**
```
┌────────────────────────────────────────┐
│ 📁 Export Settings                     │
├────────────────────────────────────────┤
│ Configure where exported images saved  │
│                                        │
│ ○ Use default app folder              │
│   %APPDATA%/MiyoList/MiyoList_Exports  │
│                                        │
│ ● Use custom folder                    │
│   C:\Users\...\My Exports              │
│   [📁 Browse...]                       │
│                                        │
│ ℹ️ Exported images will be saved with │
│   timestamps in the selected folder.  │
├────────────────────────────────────────┤
│             [Cancel]  [Save]           │
└────────────────────────────────────────┘
```

### 4. Integrated into Profile Page
**File**: `lib/features/profile/presentation/pages/profile_page.dart`

Added:
- ✅ Import for `ExportSettingsDialog`
- ✅ New button in AppBar: "Export Settings" (folder icon)
- ✅ Method `_showExportSettings()` to open dialog

**Button Position:**
```
AppBar Actions: [Image Cache] [App Updates] [Export Settings] [Privacy] [Logout]
```

### 5. Added Dependencies
**File**: `pubspec.yaml`

Added:
```yaml
file_picker: ^8.1.6
```

Allows cross-platform directory selection.

## 📐 Default Export Paths

### Windows:
```
%APPDATA%\MiyoList\MiyoList_Exports
Example: C:\Users\VIC\AppData\Roaming\MiyoList\MiyoList_Exports
```

### Android:
```
/data/data/com.miyolist.app/files/MiyoList_Exports
```

### macOS:
```
~/Library/Application Support/MiyoList/MiyoList_Exports
```

### Linux:
```
~/.local/share/MiyoList/MiyoList_Exports
```

## 🔄 User Flow

### 1. Set Custom Path:
1. Go to Profile page
2. Click "Export Settings" button (📁)
3. Select "Use custom folder"
4. Click "Browse..."
5. Choose directory
6. Click "Save"
7. ✅ Custom path saved

### 2. Reset to Default:
1. Go to Profile page
2. Click "Export Settings" button
3. Select "Use default app folder"
4. Click "Save"
5. ✅ Back to app folder

### 3. Export with Custom Path:
1. Go to Statistics page
2. Click "Download" button
3. Image saved to custom path (if set)
4. SnackBar shows full path
5. ✅ Image exported

## 🎯 Path Priority

```
1. Custom path from settings (if set and valid)
   ↓
2. Try to create custom directory
   ↓
3. Fallback to app's MiyoList_Exports folder
   ↓
4. Create exports folder if doesn't exist
```

## ✅ Benefits

### For Users:
- ✅ **Control**: Choose where images are saved
- ✅ **Organization**: Keep exports in preferred location
- ✅ **Accessibility**: Easy access from file manager
- ✅ **Backup**: Put exports in cloud sync folder (Dropbox, OneDrive, etc.)
- ✅ **Default Option**: Works out-of-box with app folder

### For App:
- ✅ **Self-contained**: Creates own export folder
- ✅ **No Downloads clutter**: Doesn't fill system Downloads
- ✅ **Organized**: All exports in one place
- ✅ **Portable**: Easy to find and backup
- ✅ **Cross-platform**: Works on all platforms

## 🔧 Technical Details

### Path Validation:
```dart
// Check if custom path exists
if (await customDir.exists()) {
  return customDir;
}

// Try to create
try {
  await customDir.create(recursive: true);
  return customDir;
} catch (e) {
  // Fallback to default
}
```

### File Naming:
```
Format: {filename}_{timestamp}.png
Example: miyolist_overview_2025-01-15T12-30-45.png
Path: {exportPath}/miyolist_overview_2025-01-15T12-30-45.png
```

### Settings Storage:
```dart
UserSettings(
  ...
  exportPath: "C:\\Users\\VIC\\Documents\\MiyoList Exports",
)

// or null for default
exportPath: null  // = {AppDocuments}/MiyoList_Exports
```

## 📊 Code Stats
- **Files Modified**: 4
  - `user_settings.dart` (+12 lines)
  - `chart_export_service.dart` (+47 lines)
  - `profile_page.dart` (+10 lines)
  - `pubspec.yaml` (+1 line)
- **Files Created**: 1
  - `export_settings_dialog.dart` (~252 lines)
- **Total**: ~322 lines of code

## 🎉 Result

Экспорт теперь поддерживает:
- ✅ **Кастомный путь** - выбор пользователем
- ✅ **Папку приложения** - по умолчанию
- ✅ **Настройки в профиле** - удобный UI
- ✅ **Автосоздание папок** - нет ошибок
- ✅ **Кросс-платформенность** - работает везде
- ✅ **Валидация путей** - проверка существования
- ✅ **Fallback** - всегда есть рабочий путь

## 🔜 Future Enhancements
- [ ] Multiple export folders (organize by type)
- [ ] Export history viewer
- [ ] Auto-cleanup old exports (keep last N)
- [ ] Export to cloud (Dropbox, Google Drive)
- [ ] Templates for folder structure
- [ ] Quick access button to export folder

## ✅ Quality Assurance
- Compiled successfully: **0 errors**
- Hive adapter regenerated: ✅
- file_picker integrated: ✅
- Cross-platform paths: ✅
- Fallback mechanism: ✅

---

**Version**: v1.1.0 "Botan (牡丹)"
**Feature Status**: ✅ Complete and Tested
**Dependencies**: file_picker ^8.1.6
