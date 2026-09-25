import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/account.dart';
import '../../providers/account_providers.dart';

/// Notification channel preferences (order / shipment / quotation / RFQ /
/// messages / marketing opt-out).
class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifPrefs)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: prefs.when(
              data: (p) => ListView(
                padding: const EdgeInsets.all(EgtDimens.s16),
                children: [
                  _toggle(
                      context, ref, l10n.notifRfq, p.rfqUpdates,
                      (v) => p.copyWith(rfqUpdates: v)),
                  _toggle(
                      context, ref, l10n.notifQuotation, p.quotationUpdates,
                      (v) => p.copyWith(quotationUpdates: v)),
                  _toggle(
                      context, ref, l10n.notifOrder, p.orderUpdates,
                      (v) => p.copyWith(orderUpdates: v)),
                  _toggle(
                      context, ref, l10n.notifShipment, p.shipmentUpdates,
                      (v) => p.copyWith(shipmentUpdates: v)),
                  _toggle(
                      context, ref, l10n.notifMessages, p.messages,
                      (v) => p.copyWith(messages: v)),
                  _toggle(
                      context, ref, l10n.notifMarketing, p.marketing,
                      (v) => p.copyWith(marketing: v)),
                ],
              ),
              loading: () => const EgtSkeletonList(),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(notificationPrefsProvider)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool value,
    NotificationPreferences Function(bool) update,
  ) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: (v) async {
        try {
          await ref
              .read(notificationRepositoryProvider)
              .savePreferences(update(v));
          ref.invalidate(notificationPrefsProvider);
        } on AppException {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.errorGeneric)));
          }
        }
      },
    );
  }
}
