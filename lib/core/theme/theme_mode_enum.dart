/// Available theme modes for the application
enum AppThemeMode {
  /// Dark theme (manga-style, original)
  dark('Dark', 'dark'),
  
  /// Light theme
  light('Light', 'light'),
  
  /// Carrot theme 🥕 (orange accent)
  carrot('Carrot 🥕', 'carrot');

  const AppThemeMode(this.label, this.value);

  /// Display name for UI
  final String label;
  
  /// Storage value
  final String value;

  /// Get theme mode from storage value
  static AppThemeMode fromValue(String value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => AppThemeMode.dark,
    );
  }
}
