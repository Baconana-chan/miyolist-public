import 'package:flutter/material.dart';

/// Base class for theme color definitions
/// Extend this class to create new themes
abstract class ThemeColors {
  // Background colors
  Color get primaryBackground;
  Color get secondaryBackground;
  Color get cardBackground;
  
  // Text colors
  Color get primaryText;
  Color get secondaryText;
  Color get tertiaryText;
  
  // Accent colors
  Color get primaryAccent;
  Color get secondaryAccent;
  Color get tertiaryAccent;
  
  // Status colors
  Color get success;
  Color get warning;
  Color get error;
  Color get info;
  
  // Special colors
  Color get divider;
  Color get shadow;
  
  // Brightness
  Brightness get brightness;
}

/// Dark theme colors (original manga-style)
class DarkThemeColors implements ThemeColors {
  @override
  Color get primaryBackground => const Color(0xFF121212);
  
  @override
  Color get secondaryBackground => const Color(0xFF1A1A1A);
  
  @override
  Color get cardBackground => const Color(0xFF1E1E1E);
  
  @override
  Color get primaryText => const Color(0xFFFFFFFF);
  
  @override
  Color get secondaryText => const Color(0xFFB0B0B0);
  
  @override
  Color get tertiaryText => const Color(0xFF808080);
  
  @override
  Color get primaryAccent => const Color(0xFFE63946);
  
  @override
  Color get secondaryAccent => const Color(0xFF457B9D);
  
  @override
  Color get tertiaryAccent => const Color(0xFF2D2D2D);
  
  @override
  Color get success => const Color(0xFF4CAF50);
  
  @override
  Color get warning => const Color(0xFFFF9800);
  
  @override
  Color get error => const Color(0xFFE63946);
  
  @override
  Color get info => const Color(0xFF457B9D);
  
  @override
  Color get divider => const Color(0xFF2D2D2D);
  
  @override
  Color get shadow => const Color(0xFF000000);
  
  @override
  Brightness get brightness => Brightness.dark;
}

/// Light theme colors
class LightThemeColors implements ThemeColors {
  @override
  Color get primaryBackground => const Color(0xFFF5F5F5);
  
  @override
  Color get secondaryBackground => const Color(0xFFFFFFFF);
  
  @override
  Color get cardBackground => const Color(0xFFFFFFFF);
  
  @override
  Color get primaryText => const Color(0xFF1A1A1A);
  
  @override
  Color get secondaryText => const Color(0xFF666666);
  
  @override
  Color get tertiaryText => const Color(0xFF999999);
  
  @override
  Color get primaryAccent => const Color(0xFFD32F2F);
  
  @override
  Color get secondaryAccent => const Color(0xFF1976D2);
  
  @override
  Color get tertiaryAccent => const Color(0xFFE0E0E0);
  
  @override
  Color get success => const Color(0xFF388E3C);
  
  @override
  Color get warning => const Color(0xFFF57C00);
  
  @override
  Color get error => const Color(0xFFD32F2F);
  
  @override
  Color get info => const Color(0xFF1976D2);
  
  @override
  Color get divider => const Color(0xFFE0E0E0);
  
  @override
  Color get shadow => const Color(0xFF000000);
  
  @override
  Brightness get brightness => Brightness.light;
}

/// Carrot theme colors 🥕 (orange accent)
class CarrotThemeColors implements ThemeColors {
  @override
  Color get primaryBackground => const Color(0xFF1A1410);
  
  @override
  Color get secondaryBackground => const Color(0xFF2A2018);
  
  @override
  Color get cardBackground => const Color(0xFF332820);
  
  @override
  Color get primaryText => const Color(0xFFFFF8F0);
  
  @override
  Color get secondaryText => const Color(0xFFD4C4B0);
  
  @override
  Color get tertiaryText => const Color(0xFFA89680);
  
  @override
  Color get primaryAccent => const Color(0xFFFF6B35); // Bright carrot orange
  
  @override
  Color get secondaryAccent => const Color(0xFFF7931E); // Golden carrot
  
  @override
  Color get tertiaryAccent => const Color(0xFF4A3F35);
  
  @override
  Color get success => const Color(0xFF8BC34A); // Green leaves
  
  @override
  Color get warning => const Color(0xFFFFB74D);
  
  @override
  Color get error => const Color(0xFFFF5252);
  
  @override
  Color get info => const Color(0xFFFF8A65);
  
  @override
  Color get divider => const Color(0xFF4A3F35);
  
  @override
  Color get shadow => const Color(0xFF0D0A08);
  
  @override
  Brightness get brightness => Brightness.dark;
}
