import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../assets/brand_assets.dart';
import '../l10n/app_localizations.dart';
import '../theme/egt_colors.dart';
import '../../presentation/providers/account_providers.dart';

/// Home app bar: logo left, notification (with badge) + account icons right.
class EgtHomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const EgtHomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return AppBar(
      title: Image.asset(BrandAssets.logo, height: 34, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(context.l10n.appName)),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: context.l10n.notifTitle,
              onPressed: () => context.push('/notifications'),
            ),
            if (unread > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: EgtColors.red, shape: BoxShape.circle),
                  child: Text('$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: context.l10n.accountTitle,
          onPressed: () => context.push('/account'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Dark-glass app bar variant for hero/immersive screens (optional use).
class EgtGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EgtGlassAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EgtColors.harborGlass,
      foregroundColor: EgtColors.onHarbor,
      title: Text(title),
      actions: actions,
    );
  }
}
