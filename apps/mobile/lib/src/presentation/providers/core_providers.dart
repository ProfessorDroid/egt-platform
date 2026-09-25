import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/auth/session_manager.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/storage/secure_token_storage.dart';

/// App-wide singletons. Flavor [AppConfig] is overridden per entrypoint.

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('Override appConfigProvider in the flavor entrypoint');
});

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences();
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final session = SessionManager(ref.watch(secureTokenStorageProvider));
  ref.onDispose(session.dispose);
  return session;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.create(
    config: ref.watch(appConfigProvider),
    session: ref.watch(sessionManagerProvider),
  );
});

final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(enabled: ref.watch(appConfigProvider).enableAnalytics);
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
