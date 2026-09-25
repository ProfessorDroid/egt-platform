import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/trade_providers.dart';
import '../../widgets/status_labels.dart';

/// RFQ result: shown only after backend confirmation. Displays RFQ ID,
/// submitted date, product, quantity, destination, status, assignee, next step.
class RfqResultScreen extends ConsumerWidget {
  const RfqResultScreen({super.key, required this.rfqId});

  final String rfqId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rfq = ref.watch(rfqDetailProvider(rfqId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rfqResultTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: rfq.when(
              data: (r) => _ResultBody(rfq: r),
              loading: () => const EgtSkeletonList(itemCount: 2),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(rfqDetailProvider(rfqId))),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.rfq});
  final Rfq rfq;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(EgtDimens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: EgtColors.success.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  size: 40, color: EgtColors.success),
            ),
          ),
          const SizedBox(height: EgtDimens.s16),
          Center(
            child: Text(l10n.rfqResultTitle,
                style: Theme.of(context).textTheme.displaySmall),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(l10n.rfqResultBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: EgtDimens.s24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EgtDimens.s16),
              child: Column(
                children: [
                  _row(context, l10n.rfqResultId, rfq.id, mono: true),
                  _row(context, l10n.rfqResultSubmittedOn,
                      formatDateTime(rfq.submittedAt)),
                  _row(context, l10n.rfqResultProduct, rfq.productName),
                  _row(context, l10n.rfqResultQuantity, rfq.quantity),
                  _row(context, l10n.rfqResultDestination, rfq.destination),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 130,
                            child: Text(l10n.rfqResultStatus,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium)),
                        StatusChip.brand(
                            rfqStatusLabel(rfq.status, l10n)),
                      ],
                    ),
                  ),
                  _row(context, l10n.rfqResultAssignee,
                      rfq.assignee ?? l10n.rfqResultUnassigned),
                ],
              ),
            ),
          ),
          const SizedBox(height: EgtDimens.s16),
          Card(
            color: EgtColors.manifest,
            child: Padding(
              padding: const EdgeInsets.all(EgtDimens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.rfqResultNextStep,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(rfq.nextStep ?? l10n.rfqResultNextStepBody,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: EgtDimens.s24),
          EgtButton(
            label: l10n.rfqResultTrack,
            icon: Icons.timeline_outlined,
            onPressed: () => context.push('/conversations/rfq/${rfq.id}'),
          ),
          const SizedBox(height: 12),
          EgtOutlineButton(
            label: l10n.rfqMyRfqs,
            onPressed: () => context.go('/rfq/list'),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: Theme.of(context).textTheme.labelMedium)),
          Expanded(
            child: SelectableText(value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: mono ? 'monospace' : null,
                    fontWeight:
                        mono ? FontWeight.w600 : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}
