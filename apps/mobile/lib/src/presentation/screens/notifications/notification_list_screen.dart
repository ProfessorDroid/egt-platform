import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/account.dart';
import '../../providers/account_providers.dart';

/// Notifications inbox with mark-all-read.
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifTitle),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: Text(l10n.notifMarkAllRead),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(notificationsProvider),
              child: notifications.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EgtEmptyState(
                        icon: Icons.notifications_outlined,
                        body: l10n.notifEmpty);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: EgtDimens.s8),
                    itemBuilder: (_, i) =>
                        _NotificationRow(notification: list[i]),
                  );
                },
                loading: () => const EgtSkeletonList(),
                error: (e, _) => EgtErrorView(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(notificationsProvider)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.read ? null : EgtColors.manifest,
      child: ListTile(
        leading: Icon(
            notification.read
                ? Icons.notifications_outlined
                : Icons.notifications_active_outlined,
            color:
                notification.read ? EgtColors.steel : EgtColors.red),
        title: Text(notification.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(formatDateTime(notification.at),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        isThreeLine: true,
        onTap: notification.deepLink == null
            ? null
            : () => context.push(notification.deepLink!),
      ),
    );
  }
}
