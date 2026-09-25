import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'src/core/config/app_config.dart';
import 'src/presentation/providers/core_providers.dart';

/// Staging flavor entrypoint: `flutter run --flavor staging -t lib/main_staging.dart`
void main() {
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.staging())],
      child: const EgtApp(),
    ),
  );
}
