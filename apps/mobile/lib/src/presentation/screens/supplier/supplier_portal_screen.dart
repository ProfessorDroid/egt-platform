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
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/growth.dart';
import '../../providers/growth_providers.dart';
import '../../widgets/status_labels.dart';

/// Supplier portal: application status list.
/// Listings NEVER auto-publish — everything waits for EGT review.
class SupplierPortalScreen extends ConsumerWidget {
  const SupplierPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final applications = ref.watch(mySupplierApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supplierTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(EgtDimens.s12),
              decoration: BoxDecoration(
                color: EgtColors.manifest,
                borderRadius: BorderRadius.circular(EgtDimens.radius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      color: EgtColors.steel, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.supplierNoAutopublish,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(mySupplierApplicationsProvider),
              child: applications.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EgtEmptyState(
                      icon: Icons.store_outlined,
                      actionLabel: l10n.supplierApply,
                      onAction: () => context.push('/supplier/apply'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: EgtDimens.s12),
                    itemBuilder: (_, i) =>
                        _ApplicationCard(application: list[i]),
                  );
                },
                loading: () => const EgtSkeletonList(),
                error: (e, _) => EgtErrorView(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(mySupplierApplicationsProvider)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/supplier/apply'),
        icon: const Icon(Icons.add),
        label: Text(l10n.supplierApply),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});
  final SupplierApplication application;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chip = application.isPending
        ? StatusChip.warning(
            supplierAppStatusLabel(application.status, l10n))
        : StatusChip.brand(
            supplierAppStatusLabel(application.status, l10n));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(application.companyName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                chip,
              ],
            ),
            const SizedBox(height: 6),
            Text(
                '${l10n.supplierSubmittedOn}: ${formatDate(application.submittedAt)}',
                style: Theme.of(context).textTheme.bodySmall),
            if (application.reviewerNote != null) ...[
              const SizedBox(height: 8),
              Text(application.reviewerNote!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
