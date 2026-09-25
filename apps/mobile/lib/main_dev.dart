import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'src/core/config/app_config.dart';
import 'src/presentation/providers/core_providers.dart';

/// Dev flavor entrypoint: `flutter run --flavor dev -t lib/main_dev.dart`
void main() {
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.dev())],
      child: const EgtApp(),
    ),
  );
}
