import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_colors.dart';
import 'theme_mode_enum.dart';

class AppTheme {
  // Current theme colors (will be updated based on selected theme)
  static ThemeColors _colors = DarkThemeColors();
  
  // Backward compatibility - Dark theme colors (deprecated, use _colors instead)
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color secondaryBlack = Color(0xFF2D2D2D);
  static const Color accentRed = Color(0xFFE63946);
  static const Color accentBlue = Color(0xFF457B9D);
  static const Color accentGold = Color(0xFFFFC107);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFFB0B0B0);
  static const Color backgroundGray = Color(0xFF121212);
  static const Color cardGray = Color(0xFF1E1E1E);
  static const Color borderGray = Color(0xFF3A3A3A);
  
  // Manga ink effect colors
  static const Color inkBlack = Color(0xFF000000);
  static const Color paperWhite = Color(0xFFF8F8F8);
  
  /// Get theme colors instance for the selected theme mode
  static ThemeColors getThemeColors(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return DarkThemeColors();
      case AppThemeMode.light:
        return LightThemeColors();
      case AppThemeMode.carrot:
        return CarrotThemeColors();
    }
  }
  
  /// Update current theme colors (call when theme changes)
  static void updateColors(AppThemeMode mode) {
    _colors = getThemeColors(mode);
  }
  
  /// Get current theme colors
  static ThemeColors get colors => _colors;
  
  /// Build ThemeData for the given theme mode
  static ThemeData getTheme(AppThemeMode mode) {
    final colors = getThemeColors(mode);
    
    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      scaffoldBackgroundColor: colors.primaryBackground,
      
      colorScheme: ColorScheme(
        brightness: colors.brightness,
        primary: colors.primaryAccent,
        onPrimary: colors.primaryText,
        secondary: colors.secondaryAccent,
        onSecondary: colors.primaryText,
        error: colors.error,
        onError: colors.primaryText,
        surface: colors.cardBackground,
        onSurface: colors.primaryText,
      ),
      
      // Typography with consistent fonts across themes
      textTheme: TextTheme(
        displayLarge: GoogleFonts.notoSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors.primaryText,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.notoSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colors.primaryText,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.notoSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colors.primaryText,
        ),
        titleMedium: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: colors.primaryText,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: colors.primaryText,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: colors.secondaryText,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: colors.secondaryBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.primaryText,
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: colors.primaryText,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primaryAccent, width: 2),
        ),
        labelStyle: TextStyle(color: colors.secondaryText),
        hintStyle: TextStyle(color: colors.tertiaryText),
      ),
      
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      
      iconTheme: IconThemeData(
        color: colors.primaryText,
      ),
    );
  }
  
  /// Legacy method for backward compatibility
  static ThemeData get darkTheme => getTheme(AppThemeMode.dark);
  
  // Manga panel decoration (adapts to current theme)
  static BoxDecoration get mangaPanelDecoration => BoxDecoration(
    color: _colors.cardBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: _colors.brightness == Brightness.dark ? inkBlack : _colors.divider,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: _colors.shadow.withOpacity(0.3),
        offset: const Offset(4, 4),
        blurRadius: 0,
      ),
    ],
  );
}
