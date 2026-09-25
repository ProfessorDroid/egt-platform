import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../providers/account_providers.dart';
import '../../providers/auth_providers.dart';

/// Account home: profile summary, company, addresses, orders/RFQs,
/// notifications, privacy, support, logout.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.accountLogoutTitle,
      body: l10n.accountLogoutBody,
      confirmLabel: l10n.accountLogout,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              children: [
                user.maybeWhen(
                  data: (u) => ListTile(
                    leading: CircleAvatar(
                      child: Text(
                          u.fullName.isNotEmpty ? u.fullName[0] : '?'),
                    ),
                    title: Text(u.fullName),
                    subtitle: Text(u.phone),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/account/profile'),
                  ),
                  orElse: () => ListTile(
                    title: Text(l10n.accountProfile),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/account/profile'),
                  ),
                ),
                const Divider(),
                _row(context,
                    icon: Icons.business_outlined,
                    label: l10n.accountCompany,
                    route: '/account/company'),
                _row(context,
                    icon: Icons.location_on_outlined,
                    label: l10n.accountAddresses,
                    route: '/account/addresses'),
                _row(context,
                    icon: Icons.request_quote_outlined,
                    label: l10n.accountMyRfqs,
                    route: '/rfq/list'),
                _row(context,
                    icon: Icons.shopping_bag_outlined,
                    label: l10n.accountOrders,
                    route: '/orders'),
                _row(context,
                    icon: Icons.receipt_long_outlined,
                    label: l10n.accountQuotations,
                    route: '/quotations'),
                _row(context,
                    icon: Icons.local_shipping_outlined,
                    label: l10n.accountShipments,
                    route: '/shipments/track'),
                _row(context,
                    icon: Icons.folder_outlined,
                    label: l10n.accountDocuments,
                    route: '/documents'),
                const Divider(),
                _row(context,
                    icon: Icons.notifications_outlined,
                    label: l10n.accountNotifications,
                    route: '/notifications/preferences'),
                _row(context,
                    icon: Icons.language_outlined,
                    label: l10n.accountLanguage,
                    route: '/account/language'),
                _row(context,
                    icon: Icons.security_outlined,
                    label: l10n.accountSecurity,
                    route: '/account/security'),
                _row(context,
                    icon: Icons.privacy_tip_outlined,
                    label: l10n.accountPrivacy,
                    route: '/account/privacy'),
                _row(context,
                    icon: Icons.headset_mic_outlined,
                    label: l10n.accountSupport,
                    route: '/account/support'),
                const Divider(),
                ListTile(
                  leading:
                      Icon(Icons.logout, color: EgtColors.error),
                  title: Text(l10n.accountLogout,
                      style: TextStyle(color: EgtColors.error)),
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context,
      {required IconData icon,
      required String label,
      required String route}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
