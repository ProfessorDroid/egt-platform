import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../providers/core_providers.dart';
import '../../providers/growth_providers.dart';

/// Supplier application. No email field — EGT publishes no email address and
/// contact is by phone/WhatsApp only.
class SupplierApplyScreen extends ConsumerStatefulWidget {
  const SupplierApplyScreen({super.key});

  @override
  ConsumerState<SupplierApplyScreen> createState() =>
      _SupplierApplyScreenState();
}

class _SupplierApplyScreenState extends ConsumerState<SupplierApplyScreen> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _details = TextEditingController();
  final _certifications = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _phone.dispose();
    _details.dispose();
    _certifications.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_form.currentState!.validate()) return;
    final online = ref.read(connectivityServiceProvider).isOnline;
    if (!online) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.rfqOfflineBlocked)));
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.supplierApply,
      body: l10n.supplierNoAutopublish,
      confirmLabel: l10n.actionSubmit,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await ref.read(supplierRepositoryProvider).apply(
            companyName: _company.text.trim(),
            contactPerson: _contact.text.trim(),
            phone: _phone.text.trim(),
            productDetails: _details.text.trim(),
            certifications: _certifications.text.trim().isEmpty
                ? null
                : _certifications.text.trim(),
          );
      ref
          .read(analyticsProvider)
          .logEvent('supplier_application_submitted', {});
      ref.invalidate(mySupplierApplicationsProvider);
      if (mounted) context.go('/supplier');
    } on AppException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supplierApply)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(EgtDimens.s16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(EgtDimens.s12),
                    decoration: BoxDecoration(
                      color: EgtColors.manifest,
                      borderRadius:
                          BorderRadius.circular(EgtDimens.radius),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: EgtColors.steel, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(l10n.supplierNoAutopublish,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  EgtTextField(
                    label: l10n.supplierCompany,
                    controller: _company,
                    validator: (v) => requiredValidator(
                        v, l10n.rfqValidationRequired),
                  ),
                  EgtTextField(
                    label: l10n.supplierContactPerson,
                    controller: _contact,
                    validator: (v) => requiredValidator(
                        v, l10n.rfqValidationRequired),
                  ),
                  EgtTextField(
                    label: l10n.supplierPhone,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => requiredValidator(
                        v, l10n.rfqValidationRequired),
                  ),
                  EgtTextField(
                    label: l10n.supplierProductDetails,
                    hint: l10n.supplierProductDetailsHint,
                    controller: _details,
                    maxLines: 4,
                    validator: (v) => requiredValidator(
                        v, l10n.rfqValidationRequired),
                  ),
                  EgtTextField(
                    label: l10n.supplierCertifications,
                    controller: _certifications,
                  ),
                  const SizedBox(height: 24),
                  EgtButton(
                      label: l10n.supplierApply,
                      onPressed: _submit,
                      isLoading: _busy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
