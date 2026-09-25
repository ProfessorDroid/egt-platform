import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/trade_providers.dart';
import '../../widgets/status_labels.dart';

/// Shipment detail. Every update is labeled "Last verified update" and the
/// banner states live carrier data isn't integrated — never fake realtime info.
class ShipmentDetailScreen extends ConsumerWidget {
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipment = ref.watch(shipmentDetailProvider(shipmentId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.shipmentTrackTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: shipment.when(
              data: (s) => SingleChildScrollView(
                padding: const EdgeInsets.all(EgtDimens.s16),
                child: ShipmentCard(shipment: s),
              ),
              loading: () => const EgtSkeletonList(itemCount: 2),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(shipmentDetailProvider(shipmentId))),
            ),
          ),
        ],
      ),
    );
  }
}

final shipmentDetailProvider =
    FutureProvider.family<Shipment, String>((ref, id) {
  return ref.watch(shipmentRepositoryProvider).getShipment(id);
});

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({super.key, required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(EgtDimens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shipmentStatusLabel(shipment.status, l10n),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: EgtColors.red)),
                const SizedBox(height: 8),
                if (shipment.trackingNumber != null)
                  Text(shipment.trackingNumber!,
                      style: Theme.of(context).textTheme.titleSmall),
                if (shipment.carrierLabel != null)
                  Text(shipment.carrierLabel!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(EgtDimens.s12),
          decoration: BoxDecoration(
            color: EgtColors.manifest,
            borderRadius: BorderRadius.circular(EgtDimens.radius),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: EgtColors.steel, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.shipmentNoCarrier,
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final u in shipment.updates) _UpdateRow(update: u),
        if (shipment.updates.isEmpty) Text(l10n.emptyBody),
      ],
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.update});
  final ShipmentUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(update.message,
                style: Theme.of(context).textTheme.bodyMedium),
            if (update.location != null)
              Text(update.location!,
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              '${l10n.shipmentLastVerified}: ${formatDateTime(update.verifiedAt)}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: EgtColors.steel),
            ),
          ],
        ),
      ),
    );
  }
}
