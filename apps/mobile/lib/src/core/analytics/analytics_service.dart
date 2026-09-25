import 'package:flutter/foundation.dart';

/// Analytics sink. Allowlisted event names only; PII/passwords are stripped
/// before anything leaves the device.
///
/// Events: app_opened, product_viewed, search_performed, rfq_started,
/// rfq_step_completed, rfq_completed, quote_viewed, quote_accepted,
/// shipment_tracked, document_downloaded.
class AnalyticsService {
  AnalyticsService({required bool enabled}) : _enabled = enabled;

  final bool _enabled;

  static const _allowedEvents = {
    'app_opened',
    'product_viewed',
    'search_performed',
    'rfq_started',
    'rfq_step_completed',
    'rfq_completed',
    'quote_viewed',
    'quote_accepted',
    'shipment_tracked',
    'document_downloaded',
  };

  static final _piiKey = RegExp(
      r'password|passwd|pwd|token|secret|email|phone|address|otp',
      caseSensitive: false);

  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    if (!_allowedEvents.contains(name)) {
      assert(false, 'Analytics event not allowlisted: $name');
      return;
    }
    final clean = <String, Object>{};
    params.forEach((key, value) {
      if (_piiKey.hasMatch(key)) return; // never send PII/passwords
      if (value != null) clean[key] = value.toString();
    });
    if (!_enabled) {
      debugPrint('[analytics:disabled] $name $clean');
      return;
    }
    // TODO: forward to the analytics backend / Firebase Analytics once the
    // backend sink exists. No PII leaves the device by construction above.
    debugPrint('[analytics] $name $clean');
  }
}
