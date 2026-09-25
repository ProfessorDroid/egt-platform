import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/company/company_info.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/launch_helper.dart';
import '../../../core/widgets/offline_banner.dart';

/// Support hub: phone/WhatsApp contact, business hours, link to enquiry form.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSupport)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              children: [
                Text(l10n.accountSupportBody,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: EgtDimens.s16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.call_outlined),
                        title: Text(CompanyInfo.phoneDisplay),
                        subtitle: Text(l10n.contactCall),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: LaunchHelper.callPhone,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.chat_outlined),
                        title: Text(l10n.contactWhatsapp),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => LaunchHelper.openWhatsApp(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.schedule_outlined),
                        title: Text(CompanyInfo.hoursWeekday),
                        subtitle: Text(
                            '${CompanyInfo.hoursSaturday}\n${CompanyInfo.hoursSunday}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EgtDimens.s16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/contact'),
                  icon: const Icon(Icons.mail_outline),
                  label: Text(l10n.contactEnquiryTitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
