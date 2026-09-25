import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../providers/account_providers.dart';

/// Privacy: data handling statement, export request, deletion request.
/// Deletion requires EGT confirmation by phone — never instant.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  Future<void> _requestExport(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref.read(userRepositoryProvider).requestDataExport();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.contactSent)));
      }
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.privacyDeleteTitle,
      body: l10n.privacyDeleteBody,
      confirmLabel: l10n.privacyDeleteAccount,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(userRepositoryProvider).requestAccountDeletion();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.contactSent)));
      }
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              children: [
                Text(l10n.privacyBody,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: EgtDimens.s24),
                OutlinedButton.icon(
                  onPressed: () => _requestExport(context, ref),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.privacyDataRequest),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _requestDeletion(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.privacyDeleteAccount),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: EgtColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
