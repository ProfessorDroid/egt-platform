import 'package:flutter/material.dart';

import 'egt_colors.dart';
import 'egt_dimens.dart';
import 'egt_typography.dart';

/// App theme: clean white foundation, EGT red accent, charcoal typography.
/// No cheap gradients — flat surfaces, premium spacing.
class EgtTheme {
  EgtTheme._();

  static ThemeData light() {
    final textTheme = EgtTypography.textTheme();
    final colorScheme = const ColorScheme.light(
      primary: EgtColors.red,
      onPrimary: EgtColors.onRed,
      secondary: EgtColors.harbor,
      onSecondary: EgtColors.onHarbor,
      surface: EgtColors.paper,
      onSurface: EgtColors.ink,
      surfaceContainerHighest: EgtColors.manifest,
      error: EgtColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: EgtColors.paper,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: EgtColors.paper,
        foregroundColor: EgtColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EgtColors.red,
          foregroundColor: EgtColors.onRed,
          minimumSize: const Size(64, EgtDimens.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EgtDimens.radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EgtColors.red,
          side: const BorderSide(color: EgtColors.red, width: 1.2),
          minimumSize: const Size(64, EgtDimens.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EgtDimens.radius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: EgtColors.red),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EgtColors.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EgtDimens.radius),
          borderSide: const BorderSide(color: EgtColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EgtDimens.radius),
          borderSide: const BorderSide(color: EgtColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EgtDimens.radius),
          borderSide: const BorderSide(color: EgtColors.red, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EgtDimens.radius),
          borderSide: const BorderSide(color: EgtColors.error),
        ),
        labelStyle: const TextStyle(color: EgtColors.steel),
        hintStyle: const TextStyle(color: EgtColors.steel),
      ),
      cardTheme: CardThemeData(
        color: EgtColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EgtDimens.radius),
          side: const BorderSide(color: EgtColors.border),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: EgtColors.manifest,
        labelStyle: TextStyle(color: EgtColors.ink, fontSize: 12),
        side: BorderSide(color: EgtColors.border),
      ),
      dividerTheme: const DividerThemeData(color: EgtColors.border, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: EgtColors.paper,
        selectedItemColor: EgtColors.red,
        unselectedItemColor: EgtColors.steel,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
