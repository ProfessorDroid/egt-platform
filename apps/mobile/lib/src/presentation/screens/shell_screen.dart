import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/egt_colors.dart';
import '../../core/theme/egt_dimens.dart';

/// Bottom nav: Home / Products / RFQ (center, prominent) / Orders / Account.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: EgtColors.paper,
            border: Border(top: BorderSide(color: EgtColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _Tab(
                icon: Icons.home_outlined, activeIcon: Icons.home,
                label: l10n.navHome,
                selected: shell.currentIndex == 0,
                onTap: () => _go(0),
              ),
              _Tab(
                icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2,
                label: l10n.navProducts,
                selected: shell.currentIndex == 1,
                onTap: () => _go(1),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: l10n.navRfq,
                  child: GestureDetector(
                    onTap: () => _go(2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: EgtColors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: EgtColors.red.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.request_quote,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 2),
                        Text(l10n.navRfq,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: shell.currentIndex == 2
                                    ? EgtColors.red
                                    : EgtColors.steel)),
                      ],
                    ),
                  ),
                ),
              ),
              _Tab(
                icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping,
                label: l10n.navOrders,
                selected: shell.currentIndex == 3,
                onTap: () => _go(3),
              ),
              _Tab(
                icon: Icons.person_outline, activeIcon: Icons.person,
                label: l10n.navAccount,
                selected: shell.currentIndex == 4,
                onTap: () => _go(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? EgtColors.red : EgtColors.steel;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EgtDimens.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
