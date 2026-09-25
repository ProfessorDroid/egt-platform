import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/trade_providers.dart';
import '../../widgets/status_labels.dart';

class RfqListScreen extends ConsumerWidget {
  const RfqListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rfqs = ref.watch(myRfqsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rfqMyRfqs)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/rfq/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.rfqNew),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myRfqsProvider),
              child: rfqs.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EgtEmptyState(
                      icon: Icons.request_quote_outlined,
                      actionLabel: l10n.rfqNew,
                      onAction: () => context.push('/rfq/new'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: EgtDimens.s12),
                    itemBuilder: (_, i) => _RfqCard(rfq: list[i]),
                  );
                },
                loading: () => const EgtSkeletonList(),
                error: (e, _) => EgtErrorView(
                    error: e, onRetry: () => ref.invalidate(myRfqsProvider)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RfqCard extends StatelessWidget {
  const _RfqCard({required this.rfq});
  final Rfq rfq;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: InkWell(
        onTap: () => context.push('/rfq/result/${rfq.id}'),
        borderRadius: BorderRadius.circular(EgtDimens.radius),
        child: Padding(
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(rfq.productName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  StatusChip.brand(rfqStatusLabel(rfq.status, l10n)),
                ],
              ),
              const SizedBox(height: 6),
              Text('${rfq.quantity} • ${rfq.destination}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                  '${l10n.rfqResultId}: ${rfq.id} • ${formatDate(rfq.submittedAt)}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      context.push('/conversations/rfq/${rfq.id}'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(l10n.convTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
