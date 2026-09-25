import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push notification wiring — STRUCTURE ONLY.
///
/// Requires from Sukh / Firebase console (not bundled):
/// - `android/app/google-services.json`
/// - `ios/Runner/GoogleService-Info.plist`
/// Without those files this service no-ops safely and the app still runs.
class PushNotificationService {
  FirebaseMessaging? _messaging;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize({void Function(String deepLink)? onDeepLink}) async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      await _messaging!.requestPermission();
      _messaging!.onTokenRefresh.listen((token) {
        debugPrint('[push] token refreshed');
        // Registered with the backend by NotificationRepository.registerDevice
        // once the user is signed in (see auth_providers).
      });
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[push] foreground: ${message.notification?.title}');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final link = message.data['deepLink'] as String?;
        if (link != null && onDeepLink != null) onDeepLink(link);
      });
      _initialized = true;
    } catch (e) {
      // Firebase config missing (no google-services.json yet) — safe no-op.
      debugPrint('[push] not configured: $e');
    }
  }

  Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      return await _messaging?.getToken();
    } catch (_) {
      return null;
    }
  }

  String get platform => Platform.isIOS ? 'ios' : 'android';
}
