import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_preferences.dart';
import 'core_providers.dart';

/// App locale: null = follow system. Persisted in [AppPreferences].
/// Punjabi/Hindi ARBs are untranslated stubs — they fall back to English
/// per-key until professionally translated.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(null) {
    _load();
  }

  final AppPreferences _prefs;

  Future<void> _load() async {
    final code = await _prefs.readLocale();
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.saveLocale('');
    } else {
      await _prefs.saveLocale(locale.languageCode);
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(appPreferencesProvider));
});
