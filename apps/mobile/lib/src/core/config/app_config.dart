import 'app_flavor.dart';

/// Per-flavor runtime configuration.
///
/// Base URLs are placeholders for the NestJS backend (Phase 1, not yet
/// deployed). Update when the backend host is known.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
  });

  final AppFlavor flavor;
  final String baseUrl;
  final bool enableAnalytics;
  final bool enableCrashReporting;

  bool get isDev => flavor == AppFlavor.dev;

  factory AppConfig.dev() => const AppConfig(
        flavor: AppFlavor.dev,
        baseUrl: 'https://dev-api.eaglegoodstrading.com/api/v1',
        enableAnalytics: false,
        enableCrashReporting: false,
      );

  factory AppConfig.staging() => const AppConfig(
        flavor: AppFlavor.staging,
        baseUrl: 'https://sukhz-egt-staging-api.hf.space/api/v1',
        enableAnalytics: false,
      );

  factory AppConfig.prod() => const AppConfig(
        flavor: AppFlavor.prod,
        baseUrl: 'https://api.eaglegoodstrading.com/api/v1',
      );
}
