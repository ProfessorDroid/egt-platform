import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/company/company_info.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/launch_helper.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../providers/account_providers.dart';

/// Contact: phone/WhatsApp only (no published email exists). Address, hours,
/// and phone come from audited [CompanyInfo] constants.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _interest = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _interest.dispose();
    _message.dispose();
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
    setState(() => _busy = true);
    try {
      await ref.read(userRepositoryProvider).sendContactEnquiry(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            message: _message.text.trim(),
            productInterest: _interest.text.trim().isEmpty
                ? null
                : _interest.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.contactSent)));
        _name.clear();
        _phone.clear();
        _interest.clear();
        _message.clear();
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(CompanyInfo.phoneDisplay),
                          subtitle: Text(l10n.contactCall),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.call),
                                tooltip: l10n.actionCall,
                                onPressed: LaunchHelper.callPhone,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_outlined),
                                tooltip: l10n.actionWhatsapp,
                                onPressed: () =>
                                    LaunchHelper.openWhatsApp(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(CompanyInfo.address,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium),
                          subtitle: Text(l10n.contactAddress),
                          onTap: LaunchHelper.openMaps,
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule_outlined),
                          title: Text(CompanyInfo.hoursWeekday,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium),
                          subtitle: Text(l10n.contactHours),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: EgtDimens.s24),
                Text(l10n.contactEnquiryTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      EgtTextField(
                        label: l10n.contactName,
                        controller: _name,
                        validator: (v) => requiredValidator(
                            v, l10n.rfqValidationRequired),
                      ),
                      EgtTextField(
                        label: l10n.contactPhone,
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => requiredValidator(
                            v, l10n.rfqValidationRequired),
                      ),
                      EgtTextField(
                        label: l10n.contactProductInterest,
                        controller: _interest,
                      ),
                      EgtTextField(
                        label: l10n.contactMessage,
                        controller: _message,
                        maxLines: 5,
                        validator: (v) => requiredValidator(
                            v, l10n.rfqValidationRequired),
                      ),
                      const SizedBox(height: 16),
                      EgtButton(
                          label: l10n.actionSend,
                          onPressed: _submit,
                          isLoading: _busy),
                      const SizedBox(height: 12),
                      EgtOutlineButton(
                        label: l10n.contactRfqCta,
                        onPressed: () => context.push('/rfq/new'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
