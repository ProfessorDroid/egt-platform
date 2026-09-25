import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'src/core/config/app_config.dart';
import 'src/presentation/providers/core_providers.dart';

/// Prod flavor entrypoint: `flutter run --flavor prod -t lib/main_prod.dart`
void main() {
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.prod())],
      child: const EgtApp(),
    ),
  );
}
