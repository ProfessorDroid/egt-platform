import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/brand_assets.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../presentation/providers/auth_providers.dart';
import '../../../presentation/providers/core_providers.dart';

/// Splash: logo, brief fade/scale animation, config load + session restore.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    final reduceMotion = MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first)
        .disableAnimations;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
    _boot();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    try {
      await ref.read(connectivityServiceProvider).init();
      await ref.read(pushNotificationServiceProvider).initialize(
        onDeepLink: (link) {
          if (mounted) context.go(link);
        },
      );
      await ref.read(authStateProvider.notifier).restore();
      ref.read(analyticsProvider).logEvent('app_opened');
    } catch (_) {
      // Boot must never hard-fail; home renders empty states offline.
    }
    final elapsed = DateTime.now().difference(started);
    if (elapsed < const Duration(milliseconds: 1400)) {
      await Future.delayed(const Duration(milliseconds: 1400) - elapsed);
    }
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgtColors.paper,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(BrandAssets.logo, width: 180,
                    errorBuilder: (_, __, ___) => Text('EGT',
                        style: Theme.of(context).textTheme.displayLarge)),
                const SizedBox(height: 16),
                Text(context.l10n.splashTagline,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: EgtColors.steel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
