import 'package:flutter/material.dart';

/// Brand color tokens — audited from the live site design system
/// (`assets/css/egt-ds-2026.css`). Do not invent new brand colors.
class EgtColors {
  EgtColors._();

  static const Color red = Color(0xFFC8102E); // --ds-red, primary accent
  static const Color redDeep = Color(0xFF9E0C24); // --ds-red-deep
  static const Color harbor = Color(0xFF0D2233); // --ds-harbor, dark navy
  static const Color harborGlass = Color(0xC4082234); // rgba(8,22,34,.78) header glass
  static const Color ink = Color(0xFF101820); // --ds-ink, body text
  static const Color steel = Color(0xFF5A6B7B); // --ds-steel, muted text
  static const Color paper = Color(0xFFFFFFFF); // --ds-paper
  static const Color manifest = Color(0xFFF2F5F7); // --ds-manifest, panel bg
  static const Color gold = Color(0xFFC8A24B); // --ds-gold, data accents

  // Functional
  static const Color success = Color(0xFF1B7A43);
  static const Color warning = Color(0xFFB7791F);
  static const Color error = Color(0xFFB3261E);
  static const Color border = Color(0xFFE2E8EE);
  static const Color onRed = Color(0xFFFFFFFF);
  static const Color onHarbor = Color(0xFFFFFFFF);
}
