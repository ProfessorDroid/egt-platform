import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/l10n/app_localizations.dart';
import 'src/core/theme/egt_theme.dart';
import 'src/core/widgets/offline_banner.dart';
import 'src/presentation/providers/locale_providers.dart';
import 'src/presentation/router/app_router.dart';

/// Root widget. Flavor config is injected via [appConfigProvider] override
/// in the flavor entrypoints (main_dev/staging/prod.dart).
class EgtApp extends ConsumerWidget {
  const EgtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: EgtTheme.light(),
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => OfflineBannerOverlay(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
    );
  }
}
