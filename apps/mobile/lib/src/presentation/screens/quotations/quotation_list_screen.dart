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

class QuotationListScreen extends ConsumerWidget {
  const QuotationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(myQuotationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dashboardQuotations)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myQuotationsProvider),
              child: quotes.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EgtEmptyState(
                        icon: Icons.receipt_long_outlined);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: EgtDimens.s12),
                    itemBuilder: (_, i) => _QuoteCard(quote: list[i]),
                  );
                },
                loading: () => const EgtSkeletonList(),
                error: (e, _) => EgtErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(myQuotationsProvider)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final Quotation quote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    StatusChip chip;
    switch (quote.status) {
      case QuotationStatus.pending:
        chip = StatusChip.warning(l10n.quoteStatusPending);
        break;
      case QuotationStatus.accepted:
        chip = StatusChip.positive(l10n.quoteStatusAccepted);
        break;
      case QuotationStatus.revisionRequested:
        chip = StatusChip.neutral(l10n.quoteStatusRevisionRequested);
        break;
      case QuotationStatus.expired:
        chip = StatusChip.negative(l10n.quoteStatusExpired);
        break;
    }
    return Card(
      child: InkWell(
        onTap: () => context.push('/quotations/${quote.id}'),
        borderRadius: BorderRadius.circular(EgtDimens.radius),
        child: Padding(
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(quote.productName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  chip,
                ],
              ),
              const SizedBox(height: 6),
              Text('${l10n.quoteValidity}: ${formatDate(quote.validUntil)}',
                  style: Theme.of(context).textTheme.bodySmall),
              if (quote.totalDisplay != null) ...[
                const SizedBox(height: 4),
                Text(quote.totalDisplay!,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
