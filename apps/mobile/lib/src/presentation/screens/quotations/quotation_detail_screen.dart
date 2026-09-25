import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/core_providers.dart';
import '../../providers/trade_providers.dart';

/// Quotation detail: validity / lead time / payment terms from the backend
/// proforma only. Accept / Request Revision / Ask EGT with confirmations.
class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.quotationId});

  final String quotationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(quotationDetailProvider(quotationId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dashboardQuotations)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: quote.when(
              data: (q) => _DetailBody(quote: q),
              loading: () => const EgtSkeletonList(itemCount: 2),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(quotationDetailProvider(quotationId))),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.quote});
  final Quotation quote;

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.quoteAcceptTitle,
      body: l10n.quoteAcceptBody,
      confirmLabel: l10n.quoteAccept,
    );
    if (!confirmed) return;
    try {
      await ref.read(quotationRepositoryProvider).accept(quote.id);
      ref
          .read(analyticsProvider)
          .logEvent('quote_accepted', {'quote_id': quote.id});
      ref.invalidate(quotationDetailProvider(quote.id));
      ref.invalidate(myQuotationsProvider);
    } on AppException {
      if (context.mounted) _snack(context, l10n.errorGeneric);
    }
  }

  Future<void> _requestRevision(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quoteRevisionTitle),
        content: EgtTextField(
            hint: l10n.quoteRevisionHint, controller: note, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel)),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.actionSend)),
        ],
      ),
    );
    if (confirmed != true || note.text.trim().isEmpty) return;
    try {
      await ref
          .read(quotationRepositoryProvider)
          .requestRevision(quote.id, note.text.trim());
      ref.invalidate(quotationDetailProvider(quote.id));
      ref.invalidate(myQuotationsProvider);
    } on AppException {
      if (context.mounted) _snack(context, l10n.errorGeneric);
    }
  }

  Future<void> _askEgt(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final message = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quoteAskEgt),
        content: EgtTextField(
            hint: l10n.quoteRevisionHint,
            controller: message,
            maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel)),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.actionSend)),
        ],
      ),
    );
    if (sent != true || message.text.trim().isEmpty) return;
    try {
      await ref
          .read(quotationRepositoryProvider)
          .askEgt(quote.id, message.text.trim());
      if (context.mounted) _snack(context, l10n.contactSent);
    } on AppException {
      if (context.mounted) _snack(context, l10n.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAct = quote.status == QuotationStatus.pending;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(EgtDimens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quote.productName,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          if (quote.totalDisplay != null)
            Text(quote.totalDisplay!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: EgtColors.red, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EgtDimens.s16),
              child: Column(
                children: [
                  _term(context, l10n.quoteValidity,
                      formatDate(quote.validUntil)),
                  if (quote.leadTime != null)
                    _term(context, l10n.quoteLeadTime, quote.leadTime!),
                  if (quote.paymentTerms != null)
                    _term(context, l10n.quotePaymentTerms, quote.paymentTerms!),
                  if (quote.specSummary != null)
                    _term(context, l10n.productSpecs, quote.specSummary!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (canAct) ...[
            EgtButton(
                label: l10n.quoteAccept,
                icon: Icons.check_circle_outline,
                onPressed: () => _accept(context, ref)),
            const SizedBox(height: 12),
            EgtOutlineButton(
                label: l10n.quoteRequestRevision,
                icon: Icons.edit_outlined,
                onPressed: () => _requestRevision(context, ref)),
            const SizedBox(height: 12),
          ],
          EgtOutlineButton(
              label: l10n.quoteAskEgt,
              icon: Icons.chat_bubble_outline,
              onPressed: () => _askEgt(context, ref)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                context.push('/conversations/rfq/${quote.rfqId}'),
            icon: const Icon(Icons.forum_outlined),
            label: Text(l10n.convTitle),
          ),
        ],
      ),
    );
  }

  Widget _term(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child:
                    Text(label, style: Theme.of(context).textTheme.labelMedium)),
            Expanded(
                child:
                    Text(value, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}
