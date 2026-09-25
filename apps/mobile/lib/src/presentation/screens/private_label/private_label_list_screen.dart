import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/growth.dart';
import '../../providers/growth_providers.dart';
import '../../widgets/status_labels.dart';

/// Private-label request list with backend-driven status.
class PrivateLabelListScreen extends ConsumerWidget {
  const PrivateLabelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requests = ref.watch(myPrivateLabelRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.plTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/private-label/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.plNew),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(myPrivateLabelRequestsProvider),
              child: requests.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EgtEmptyState(
                      icon: Icons.branding_watermark_outlined,
                      body: l10n.plResultBody,
                      actionLabel: l10n.plNew,
                      onAction: () => context.push('/private-label/new'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: EgtDimens.s12),
                    itemBuilder: (_, i) => _PlCard(request: list[i]),
                  );
                },
                loading: () => const EgtSkeletonList(),
                error: (e, _) => EgtErrorView(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(myPrivateLabelRequestsProvider)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlCard extends StatelessWidget {
  const _PlCard({required this.request});
  final PrivateLabelRequest request;

  @override
  Widget build(BuildContext context) {
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
                  child: Text(request.productName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                StatusChip.brand(
                    privateLabelStatusLabel(request.status, l10n)),
              ],
            ),
            const SizedBox(height: 6),
            Text('${request.brandName} • ${formatDate(request.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
