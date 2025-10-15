import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'custom_theme.g.dart';

/// Custom theme model for user-created themes
@HiveType(typeId: 23)
class CustomTheme extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  // Background colors
  @HiveField(3)
  final int primaryBackground;

  @HiveField(4)
  final int secondaryBackground;

  @HiveField(5)
  final int cardBackground;

  // Text colors
  @HiveField(6)
  final int primaryText;

  @HiveField(7)
  final int secondaryText;

  @HiveField(8)
  final int tertiaryText;

  // Accent colors
  @HiveField(9)
  final int primaryAccent;

  @HiveField(10)
  final int secondaryAccent;

  @HiveField(11)
  final int tertiaryAccent;

  // Status colors
  @HiveField(12)
  final int success;

  @HiveField(13)
  final int warning;

  @HiveField(14)
  final int error;

  @HiveField(15)
  final int info;

  // Special colors
  @HiveField(16)
  final int divider;

  @HiveField(17)
  final int shadow;

  // Brightness
  @HiveField(18)
  final bool isDark;

  @HiveField(19)
  final DateTime createdAt;

  @HiveField(20)
  final DateTime updatedAt;

  @HiveField(21)
  final bool isDefault; // Is this a built-in theme?

  CustomTheme({
    required this.id,
    required this.name,
    this.description,
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.divider,
    required this.shadow,
    required this.isDark,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  /// Create CustomTheme from existing theme colors
  factory CustomTheme.fromThemeColors({
    required String id,
    required String name,
    String? description,
    required Color primaryBackground,
    required Color secondaryBackground,
    required Color cardBackground,
    required Color primaryText,
    required Color secondaryText,
    required Color tertiaryText,
    required Color primaryAccent,
    required Color secondaryAccent,
    required Color tertiaryAccent,
    required Color success,
    required Color warning,
    required Color error,
    required Color info,
    required Color divider,
    required Color shadow,
    required bool isDark,
    bool isDefault = false,
  }) {
    return CustomTheme(
      id: id,
      name: name,
      description: description,
      primaryBackground: primaryBackground.value,
      secondaryBackground: secondaryBackground.value,
      cardBackground: cardBackground.value,
      primaryText: primaryText.value,
      secondaryText: secondaryText.value,
      tertiaryText: tertiaryText.value,
      primaryAccent: primaryAccent.value,
      secondaryAccent: secondaryAccent.value,
      tertiaryAccent: tertiaryAccent.value,
      success: success.value,
      warning: warning.value,
      error: error.value,
      info: info.value,
      divider: divider.value,
      shadow: shadow.value,
      isDark: isDark,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: isDefault,
    );
  }

  /// Convert to Color objects
  Color get primaryBackgroundColor => Color(primaryBackground);
  Color get secondaryBackgroundColor => Color(secondaryBackground);
  Color get cardBackgroundColor => Color(cardBackground);
  Color get primaryTextColor => Color(primaryText);
  Color get secondaryTextColor => Color(secondaryText);
  Color get tertiaryTextColor => Color(tertiaryText);
  Color get primaryAccentColor => Color(primaryAccent);
  Color get secondaryAccentColor => Color(secondaryAccent);
  Color get tertiaryAccentColor => Color(tertiaryAccent);
  Color get successColor => Color(success);
  Color get warningColor => Color(warning);
  Color get errorColor => Color(error);
  Color get infoColor => Color(info);
  Color get dividerColor => Color(divider);
  Color get shadowColor => Color(shadow);

  CustomTheme copyWith({
    String? id,
    String? name,
    String? description,
    int? primaryBackground,
    int? secondaryBackground,
    int? cardBackground,
    int? primaryText,
    int? secondaryText,
    int? tertiaryText,
    int? primaryAccent,
    int? secondaryAccent,
    int? tertiaryAccent,
    int? success,
    int? warning,
    int? error,
    int? info,
    int? divider,
    int? shadow,
    bool? isDark,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      tertiaryAccent: tertiaryAccent ?? this.tertiaryAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
