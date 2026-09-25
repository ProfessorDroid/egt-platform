import 'package:flutter/material.dart';

import 'egt_colors.dart';

/// Typography. Display = Archivo, body = DM Sans (self-hosted on the website).
/// The mobile app references the family names with system fallbacks; see
/// docs/mobile-build.md for bundling the TTFs (the site ships woff2, which
/// Flutter cannot consume directly).
class EgtTypography {
  EgtTypography._();

  static const String displayFamily = 'Archivo';
  static const String bodyFamily = 'DM Sans';

  static const List<String> displayFallbacks = [displayFamily, bodyFamily, 'system-ui', 'sans-serif'];
  static const List<String> bodyFallbacks = [bodyFamily, 'system-ui', 'sans-serif'];

  static TextTheme textTheme() {
    const ink = EgtColors.ink;
    const steel = EgtColors.steel;
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: displayFamily, fontSize: 32, fontWeight: FontWeight.w800, color: ink, height: 1.15),
      displayMedium: TextStyle(fontFamily: displayFamily, fontSize: 26, fontWeight: FontWeight.w700, color: ink, height: 1.2),
      displaySmall: TextStyle(fontFamily: displayFamily, fontSize: 22, fontWeight: FontWeight.w700, color: ink, height: 1.25),
      headlineMedium: TextStyle(fontFamily: displayFamily, fontSize: 20, fontWeight: FontWeight.w700, color: ink),
      headlineSmall: TextStyle(fontFamily: displayFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      titleLarge: TextStyle(fontFamily: displayFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
      bodyLarge: TextStyle(fontSize: 16, color: ink, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: steel, height: 1.45),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: steel),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: steel),
    );
  }
}
