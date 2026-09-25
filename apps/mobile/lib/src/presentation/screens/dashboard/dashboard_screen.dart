import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/account_providers.dart';
import '../../providers/trade_providers.dart';
import '../../widgets/status_labels.dart';

/// Home dashboard: greeting, pending actions, and shortcuts.
/// All counts come from backend queries — no invented statistics.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _activeRfqStatuses = {
    RfqStatus.submitted,
    RfqStatus.underReview,
    RfqStatus.quoted,
  };
  static const _openOrderStatuses = {
    OrderStatus.confirmed,
    OrderStatus.inProduction,
    OrderStatus.qualityCheck,
    OrderStatus.shipped,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = ref
        .watch(profileProvider)
        .maybeWhen(data: (u) => u.fullName, orElse: () => null);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final rfqs = ref.watch(myRfqsProvider);
    final orders = ref.watch(myOrdersProvider);

    final firstName = name?.trim().split(RegExp(r'\s+')).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(firstName == null || firstName.isEmpty
            ? l10n.homeWelcome
            : '${l10n.homeWelcome}, $firstName'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text('$unread',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(profileProvider);
                ref.invalidate(myRfqsProvider);
                ref.invalidate(myOrdersProvider);
                ref.invalidate(notificationsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(EgtDimens.s16),
                children: [
                  rfqs.when(
                    data: (list) => _CountRow(
                        label: l10n.homeActiveRfqs,
                        count: list
                            .where((r) => _activeRfqStatuses.contains(r.status))
                            .length,
                        onTap: () => context.go('/rfq/list')),
                    loading: () => const _CountPlaceholder(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: EgtDimens.s8),
                  orders.when(
                    data: (list) => _CountRow(
                        label: l10n.homeOpenOrders,
                        count: list
                            .where((o) => _openOrderStatuses.contains(o.status))
                            .length,
                        onTap: () => context.go('/orders')),
                    loading: () => const _CountPlaceholder(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: EgtDimens.s24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: EgtDimens.s12,
                    crossAxisSpacing: EgtDimens.s12,
                    childAspectRatio: 1.6,
                    children: [
                      _Shortcut(
                          icon: Icons.add_box_outlined,
                          label: l10n.actionNewRfq,
                          onTap: () => context.push('/rfq/new')),
                      _Shortcut(
                          icon: Icons.inventory_2_outlined,
                          label: l10n.navProducts,
                          onTap: () => context.go('/products')),
                      _Shortcut(
                          icon: Icons.local_shipping_outlined,
                          label: l10n.homeTrackShipment,
                          onTap: () => context.push('/shipments/track')),
                      _Shortcut(
                          icon: Icons.headset_mic_outlined,
                          label: l10n.accountSupport,
                          onTap: () => context.push('/contact')),
                    ],
                  ),
                  const SizedBox(height: EgtDimens.s24),
                  Text(l10n.homeLatestRfqs,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  rfqs.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Text(l10n.rfqEmptyTitle,
                            style:
                                Theme.of(context).textTheme.bodyMedium);
                      }
                      return Column(
                        children: [
                          for (final r in list.take(5))
                            Card(
                              child: ListTile(
                                title: Text(r.productName),
                                subtitle: Text(
                                    '${rfqStatusLabel(r.status, l10n)} · ${r.quantity}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/rfq/${r.id}'),
                              ),
                            ),
                          TextButton(
                              onPressed: () => context.go('/rfq/list'),
                              child: Text(l10n.actionViewAll)),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text(l10n.errorGeneric,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow(
      {required this.label, required this.count, required this.onTap});
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(label,
              style: Theme.of(context).textTheme.titleMedium),
          trailing: Text('$count',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          onTap: onTap,
        ),
      );
}

class _CountPlaceholder extends StatelessWidget {
  const _CountPlaceholder();

  @override
  Widget build(BuildContext context) =>
      const Card(child: SizedBox(height: 72));
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 8),
                Text(label,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ),
      );
}
