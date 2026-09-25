import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'src/core/config/app_config.dart';
import 'src/presentation/providers/core_providers.dart';

/// Default entrypoint. Prefer the flavor entrypoints:
/// `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`.
void main() {
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.dev())],
      child: const EgtApp(),
    ),
  );
}
