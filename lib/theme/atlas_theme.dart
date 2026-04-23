import 'package:flutter/material.dart';
import 'atlas_colors.dart';
import 'atlas_text.dart';

class AtlasTheme {
  AtlasTheme._();

  static ThemeData light() {
    const fontFamily = 'Inter';
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AtlasColors.pageBg,
      primaryColor: AtlasColors.accent,
      splashColor: AtlasColors.accent.withValues(alpha: 0.06),
      hoverColor: AtlasColors.accent.withValues(alpha: 0.04),
      colorScheme: const ColorScheme.light(
        primary: AtlasColors.accent,
        onPrimary: AtlasColors.textInverse,
        secondary: AtlasColors.info,
        surface: AtlasColors.cardBg,
        onSurface: AtlasColors.textPrimary,
        error: AtlasColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: AtlasText.display,
        headlineLarge: AtlasText.h1,
        headlineMedium: AtlasText.h2,
        titleMedium: AtlasText.h3,
        bodyMedium: AtlasText.body,
        bodySmall: AtlasText.small,
        labelLarge: AtlasText.button,
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.lg),
          side: const BorderSide(color: AtlasColors.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.cardBg,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AtlasSpace.md,
          vertical: AtlasSpace.md,
        ),
        hintStyle: const TextStyle(
          color: AtlasColors.textSubtle,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AtlasColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: AtlasColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.md),
          borderSide: const BorderSide(color: AtlasColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.md),
          borderSide: const BorderSide(color: AtlasColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.md),
          borderSide: const BorderSide(color: AtlasColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.md),
          borderSide: const BorderSide(color: AtlasColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.md),
          borderSide: const BorderSide(color: AtlasColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.accent,
          foregroundColor: AtlasColors.textInverse,
          disabledBackgroundColor: AtlasColors.accent.withValues(alpha: 0.4),
          disabledForegroundColor: AtlasColors.textInverse.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpace.lg, vertical: AtlasSpace.md),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AtlasRadius.md)),
          textStyle: AtlasText.buttonStrong,
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
              AtlasColors.accentActive.withValues(alpha: 0.18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AtlasColors.textPrimary,
          backgroundColor: AtlasColors.cardBg,
          side: const BorderSide(color: AtlasColors.cardBorder),
          padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpace.lg, vertical: AtlasSpace.md),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AtlasRadius.md)),
          textStyle: AtlasText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AtlasColors.accent,
          padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpace.md, vertical: AtlasSpace.sm),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AtlasRadius.sm)),
          textStyle: AtlasText.button.copyWith(color: AtlasColors.accent),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AtlasColors.textSecondary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AtlasRadius.sm)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AtlasColors.divider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AtlasColors.cardBg,
        elevation: 24,
        shadowColor: AtlasColors.shadowLg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasRadius.xxl)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AtlasColors.sidebarBg,
        contentTextStyle:
            AtlasText.small.copyWith(color: AtlasColors.textInverse),
        actionTextColor: AtlasColors.accentMuted,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasRadius.lg)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AtlasColors.sidebarBg,
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
        ),
        textStyle: AtlasText.tiny.copyWith(color: AtlasColors.textInverse),
        padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpace.sm, vertical: AtlasSpace.xs),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasRadius.xs)),
        side: const BorderSide(color: AtlasColors.cardBorder, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AtlasColors.accent;
          return Colors.transparent;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AtlasColors.cardBg;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AtlasColors.accent;
          return AtlasColors.cardBorder;
        }),
      ),
    );
  }
}
