import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_mode_enum.dart';

/// Provider for managing app theme
@injectable
class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  AppThemeMode _currentMode = AppThemeMode.dark;

  ThemeProvider(this._storage) {
    _loadTheme();
  }

  /// Get current theme mode
  AppThemeMode get currentMode => _currentMode;

  /// Get current theme data
  ThemeData get currentTheme => AppTheme.getTheme(_currentMode);

  /// Load theme from storage
  Future<void> _loadTheme() async {
    final settings = await _storage.getUserSettings();
    if (settings != null) {
      _currentMode = AppThemeMode.fromValue(settings.themeMode);
      AppTheme.updateColors(_currentMode);
      notifyListeners();
    }
  }

  /// Change theme and save to storage
  Future<void> setTheme(AppThemeMode mode) async {
    if (_currentMode == mode) return;

    _currentMode = mode;
    AppTheme.updateColors(mode);

    // Save to storage
    final settings = await _storage.getUserSettings();
    if (settings != null) {
      final updated = settings.copyWith(
        themeMode: mode.value,
        updatedAt: DateTime.now(),
      );
      await _storage.saveUserSettings(updated);
    }

    notifyListeners();
  }

  /// Cycle through themes (for quick switching)
  Future<void> cycleTheme() async {
    final modes = AppThemeMode.values;
    final currentIndex = modes.indexOf(_currentMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setTheme(modes[nextIndex]);
  }
}
