import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/account.dart';
import '../../providers/account_providers.dart';

/// Company profile (B2B buyer details).
class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _taxId = TextEditingController();
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    _city.dispose();
    _address.dispose();
    _taxId.dispose();
    super.dispose();
  }

  void _seed(Company? company) {
    if (_seeded || company == null) return;
    _name.text = company.name;
    _country.text = company.country ?? '';
    _city.text = company.city ?? '';
    _address.text = company.addressLine ?? '';
    _taxId.text = company.taxId ?? '';
    _seeded = true;
  }

  Future<void> _save(String? id) async {
    final l10n = context.l10n;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(userRepositoryProvider).saveCompany(Company(
            id: id ?? '',
            name: _name.text.trim(),
            country: _country.text.trim().isEmpty
                ? null
                : _country.text.trim(),
            city: _city.text.trim().isEmpty ? null : _city.text.trim(),
            addressLine: _address.text.trim().isEmpty
                ? null
                : _address.text.trim(),
            taxId: _taxId.text.trim().isEmpty ? null : _taxId.text.trim(),
          ));
      ref.invalidate(companyProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.accountProfileSaved)));
      }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final company = ref.watch(companyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountCompany)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: company.when(
              data: (c) {
                _seed(c);
                return Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    children: [
                      EgtTextField(
                        label: l10n.supplierCompany,
                        controller: _name,
                        validator: (v) => requiredValidator(
                            v, l10n.rfqValidationRequired),
                      ),
                      EgtTextField(
                          label: l10n.accountCountry,
                          controller: _country),
                      EgtTextField(
                          label: l10n.accountCity, controller: _city),
                      EgtTextField(
                          label: l10n.accountAddressLines,
                          controller: _address,
                          maxLines: 2),
                      EgtTextField(
                          label: l10n.accountTaxId, controller: _taxId),
                      const SizedBox(height: 24),
                      EgtButton(
                          label: l10n.actionSave,
                          onPressed: () => _save(c?.id),
                          isLoading: _busy),
                    ],
                  ),
                );
              },
              loading: () => const EgtSkeletonList(itemCount: 3),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(companyProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
