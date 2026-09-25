import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/milestone_timeline.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../providers/trade_providers.dart';
import '../../widgets/status_labels.dart';

/// Order detail with the 13-step backend-driven journey timeline.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final order = ref.watch(orderDetailProvider(orderId));
    final milestones = ref.watch(orderMilestonesProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ordersTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: order.when(
              data: (o) => SingleChildScrollView(
                padding: const EdgeInsets.all(EgtDimens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(o.productName,
                              style:
                                  Theme.of(context).textTheme.displaySmall),
                        ),
                        StatusChip.brand(orderStatusLabel(o.status, l10n)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${o.id} • ${formatDate(o.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (o.trackingIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: o.trackingIds
                            .map((t) => ActionChip(
                                  label: Text(t),
                                  onPressed: () => context.push(
                                      '/shipments/track?q=${Uri.encodeComponent(t)}'),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(l10n.dashboardJourney,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    milestones.when(
                      data: (ms) => ms.isEmpty
                          ? Text(l10n.emptyBody)
                          : MilestoneTimeline(milestones: ms),
                      loading: () => const EgtSkeletonList(itemCount: 2),
                      error: (e, _) => EgtErrorView(error: e),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/conversations/order/${o.id}'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(l10n.convTitle),
                    ),
                  ],
                ),
              ),
              loading: () => const EgtSkeletonList(itemCount: 3),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(orderDetailProvider(orderId))),
            ),
          ),
        ],
      ),
    );
  }
}
