import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local prefs: theme/locale choices, draft RFQs, onboarding flags.
/// NEVER store tokens, passwords, or PII-adjacent secrets here.
class AppPreferences {
  static const _kLocale = 'prefs.locale';
  static const _kRfqDraft = 'prefs.rfq_draft';
  static const _kPrivateLabelDraft = 'prefs.private_label_draft';
  static const _kBiometricEnabled = 'prefs.biometric_enabled';
  static const _kOnboardingSeen = 'prefs.onboarding_seen';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readLocale() async => (await _prefs).getString(_kLocale);
  Future<void> saveLocale(String locale) async => (await _prefs).setString(_kLocale, locale);

  Future<String?> readRfqDraft() async => (await _prefs).getString(_kRfqDraft);
  Future<void> saveRfqDraft(String json) async => (await _prefs).setString(_kRfqDraft, json);
  Future<void> clearRfqDraft() async => (await _prefs).remove(_kRfqDraft);

  Future<String?> readPrivateLabelDraft() async =>
      (await _prefs).getString(_kPrivateLabelDraft);
  Future<void> savePrivateLabelDraft(String json) async =>
      (await _prefs).setString(_kPrivateLabelDraft, json);
  Future<void> clearPrivateLabelDraft() async =>
      (await _prefs).remove(_kPrivateLabelDraft);

  Future<bool> isBiometricEnabled() async =>
      (await _prefs).getBool(_kBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool v) async =>
      (await _prefs).setBool(_kBiometricEnabled, v);
}
