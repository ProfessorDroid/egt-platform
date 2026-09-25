import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/account.dart';
import '../../providers/account_providers.dart';

/// Address book: billing/shipping addresses for RFQs and orders.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountAddresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddressEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.accountAddAddress),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(addressesProvider),
              child: addresses.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EgtEmptyState(
                      icon: Icons.location_on_outlined,
                      actionLabel: l10n.accountAddAddress,
                      onAction: () => showAddressEditor(context, ref, null),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: EgtDimens.s8),
                    itemBuilder: (_, i) =>
                        _AddressRow(address: list[i]),
                  );
                },
                loading: () => const EgtSkeletonList(),
                error: (e, _) => EgtErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(addressesProvider)),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Address add/edit dialog sheet.
Future<void> showAddressEditor(
    BuildContext context, WidgetRef ref, Address? existing) async {
  final l10n = context.l10n;
  final form = GlobalKey<FormState>();
  final label = TextEditingController(text: existing?.label ?? '');
  final lines = TextEditingController(text: existing?.lines ?? '');
  final city = TextEditingController(text: existing?.city ?? '');
  final country = TextEditingController(text: existing?.country ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountAddAddress),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EgtTextField(
                    label: l10n.accountAddressLabel,
                    controller: label,
                    validator: (v) => requiredValidator(
                        v, l10n.rfqValidationRequired)),
                EgtTextField(
                    label: l10n.accountAddressLines,
                    controller: lines,
                    maxLines: 2,
                    validator: (v) => requiredValidator(
                        v, l10n.rfqValidationRequired)),
                EgtTextField(
                    label: l10n.accountCity, controller: city),
                EgtTextField(
                    label: l10n.accountCountry, controller: country),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel)),
          ElevatedButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: Text(l10n.actionSave)),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await ref.read(userRepositoryProvider).saveAddress(Address(
            id: existing?.id ?? '',
            label: label.text.trim(),
            lines: lines.text.trim(),
            city: city.text.trim().isEmpty ? null : city.text.trim(),
            country:
                country.text.trim().isEmpty ? null : country.text.trim(),
            isDefault: existing?.isDefault ?? false,
          ));
      ref.invalidate(addressesProvider);
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

class _AddressRow extends ConsumerWidget {
  const _AddressRow({required this.address});
  final Address address;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.accountDeleteAddress,
      body: address.label,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(userRepositoryProvider).deleteAddress(address.id);
      ref.invalidate(addressesProvider);
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  Future<void> _setDefault(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(userRepositoryProvider).saveAddress(Address(
            id: address.id,
            label: address.label,
            lines: address.lines,
            city: address.city,
            country: address.country,
            isDefault: true,
          ));
      ref.invalidate(addressesProvider);
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorGeneric)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(address.label,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                if (address.isDefault)
                  Chip(label: Text(l10n.accountSetDefault)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                '${address.lines}\n${[address.city, address.country].whereType<String>().where((e) => e.isNotEmpty).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!address.isDefault)
                  TextButton(
                      onPressed: () => _setDefault(context, ref),
                      child: Text(l10n.accountSetDefault)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showAddressEditor(context, ref, address),
                  tooltip: l10n.actionEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref),
                  tooltip: l10n.actionDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
