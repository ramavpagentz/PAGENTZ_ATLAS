import 'package:flutter/material.dart';
import 'atlas_colors.dart';

class AtlasTheme {
  AtlasTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AtlasColors.pageBg,
      primaryColor: AtlasColors.accent,
      colorScheme: const ColorScheme.light(
        primary: AtlasColors.accent,
        secondary: AtlasColors.info,
        surface: AtlasColors.cardBg,
        error: AtlasColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AtlasColors.textPrimary, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: AtlasColors.textPrimary, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: AtlasColors.textPrimary),
        bodySmall: TextStyle(color: AtlasColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AtlasColors.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AtlasColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AtlasColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AtlasColors.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AtlasColors.textPrimary,
          side: const BorderSide(color: AtlasColors.cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
