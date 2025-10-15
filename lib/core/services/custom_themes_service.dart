import 'package:hive_flutter/hive_flutter.dart';
import '../models/custom_theme.dart';
import '../theme/theme_colors.dart';

/// Service for managing custom user-created themes
class CustomThemesService {
  static const String _boxName = 'custom_themes';
  Box<CustomTheme>? _box;

  /// Initialize the service
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<CustomTheme>(_boxName);
    } else {
      _box = Hive.box<CustomTheme>(_boxName);
    }

    // Add built-in themes if not already present
    await _addBuiltInThemes();
  }

  /// Add built-in themes as custom themes
  Future<void> _addBuiltInThemes() async {
    if (_box == null) return;

    // Check if built-in themes already exist
    final existingThemes = _box!.values.where((t) => t.isDefault).toList();
    if (existingThemes.isNotEmpty) return;

    // Add Dark theme
    final darkTheme = DarkThemeColors();
    await _box!.put(
      'dark',
      CustomTheme.fromThemeColors(
        id: 'dark',
        name: 'Dark (Original)',
        description: 'Original manga-style dark theme',
        primaryBackground: darkTheme.primaryBackground,
        secondaryBackground: darkTheme.secondaryBackground,
        cardBackground: darkTheme.cardBackground,
        primaryText: darkTheme.primaryText,
        secondaryText: darkTheme.secondaryText,
        tertiaryText: darkTheme.tertiaryText,
        primaryAccent: darkTheme.primaryAccent,
        secondaryAccent: darkTheme.secondaryAccent,
        tertiaryAccent: darkTheme.tertiaryAccent,
        success: darkTheme.success,
        warning: darkTheme.warning,
        error: darkTheme.error,
        info: darkTheme.info,
        divider: darkTheme.divider,
        shadow: darkTheme.shadow,
        isDark: true,
        isDefault: true,
      ),
    );

    // Add Light theme
    final lightTheme = LightThemeColors();
    await _box!.put(
      'light',
      CustomTheme.fromThemeColors(
        id: 'light',
        name: 'Light',
        description: 'Clean light theme',
        primaryBackground: lightTheme.primaryBackground,
        secondaryBackground: lightTheme.secondaryBackground,
        cardBackground: lightTheme.cardBackground,
        primaryText: lightTheme.primaryText,
        secondaryText: lightTheme.secondaryText,
        tertiaryText: lightTheme.tertiaryText,
        primaryAccent: lightTheme.primaryAccent,
        secondaryAccent: lightTheme.secondaryAccent,
        tertiaryAccent: lightTheme.tertiaryAccent,
        success: lightTheme.success,
        warning: lightTheme.warning,
        error: lightTheme.error,
        info: lightTheme.info,
        divider: lightTheme.divider,
        shadow: lightTheme.shadow,
        isDark: false,
        isDefault: true,
      ),
    );

    // Add Carrot theme
    final carrotTheme = CarrotThemeColors();
    await _box!.put(
      'carrot',
      CustomTheme.fromThemeColors(
        id: 'carrot',
        name: 'Carrot 🥕',
        description: 'Warm orange-accented theme',
        primaryBackground: carrotTheme.primaryBackground,
        secondaryBackground: carrotTheme.secondaryBackground,
        cardBackground: carrotTheme.cardBackground,
        primaryText: carrotTheme.primaryText,
        secondaryText: carrotTheme.secondaryText,
        tertiaryText: carrotTheme.tertiaryText,
        primaryAccent: carrotTheme.primaryAccent,
        secondaryAccent: carrotTheme.secondaryAccent,
        tertiaryAccent: carrotTheme.tertiaryAccent,
        success: carrotTheme.success,
        warning: carrotTheme.warning,
        error: carrotTheme.error,
        info: carrotTheme.info,
        divider: carrotTheme.divider,
        shadow: carrotTheme.shadow,
        isDark: true,
        isDefault: true,
      ),
    );
  }

  /// Get all custom themes
  List<CustomTheme> getAllThemes() {
    if (_box == null) return [];
    return _box!.values.toList()
      ..sort((a, b) {
        // Built-in themes first
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        // Then by name
        return a.name.compareTo(b.name);
      });
  }

  /// Get theme by ID
  CustomTheme? getTheme(String id) {
    if (_box == null) return null;
    return _box!.get(id);
  }

  /// Save or update a custom theme
  Future<void> saveTheme(CustomTheme theme) async {
    if (_box == null) return;
    await _box!.put(theme.id, theme);
  }

  /// Delete a custom theme (only user-created themes)
  Future<bool> deleteTheme(String id) async {
    if (_box == null) return false;

    final theme = _box!.get(id);
    if (theme == null || theme.isDefault) {
      return false; // Cannot delete built-in themes
    }

    await _box!.delete(id);
    return true;
  }

  /// Duplicate a theme
  Future<CustomTheme> duplicateTheme(CustomTheme source, String newName) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final duplicated = source.copyWith(
      id: newId,
      name: newName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: false,
    );

    await saveTheme(duplicated);
    return duplicated;
  }

  /// Export theme as JSON
  Map<String, dynamic> exportTheme(CustomTheme theme) {
    return {
      'name': theme.name,
      'description': theme.description,
      'colors': {
        'primaryBackground': theme.primaryBackground,
        'secondaryBackground': theme.secondaryBackground,
        'cardBackground': theme.cardBackground,
        'primaryText': theme.primaryText,
        'secondaryText': theme.secondaryText,
        'tertiaryText': theme.tertiaryText,
        'primaryAccent': theme.primaryAccent,
        'secondaryAccent': theme.secondaryAccent,
        'tertiaryAccent': theme.tertiaryAccent,
        'success': theme.success,
        'warning': theme.warning,
        'error': theme.error,
        'info': theme.info,
        'divider': theme.divider,
        'shadow': theme.shadow,
      },
      'isDark': theme.isDark,
    };
  }

  /// Import theme from JSON
  Future<CustomTheme> importTheme(Map<String, dynamic> json) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final theme = CustomTheme(
      id: newId,
      name: json['name'] as String,
      description: json['description'] as String?,
      primaryBackground: json['colors']['primaryBackground'] as int,
      secondaryBackground: json['colors']['secondaryBackground'] as int,
      cardBackground: json['colors']['cardBackground'] as int,
      primaryText: json['colors']['primaryText'] as int,
      secondaryText: json['colors']['secondaryText'] as int,
      tertiaryText: json['colors']['tertiaryText'] as int,
      primaryAccent: json['colors']['primaryAccent'] as int,
      secondaryAccent: json['colors']['secondaryAccent'] as int,
      tertiaryAccent: json['colors']['tertiaryAccent'] as int,
      success: json['colors']['success'] as int,
      warning: json['colors']['warning'] as int,
      error: json['colors']['error'] as int,
      info: json['colors']['info'] as int,
      divider: json['colors']['divider'] as int,
      shadow: json['colors']['shadow'] as int,
      isDark: json['isDark'] as bool,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: false,
    );

    await saveTheme(theme);
    return theme;
  }
}
