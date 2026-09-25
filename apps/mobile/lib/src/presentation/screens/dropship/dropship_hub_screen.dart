import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/growth.dart';
import '../../providers/growth_providers.dart';

/// Dropship hub: rendered only when the backend advertises dropship support.
/// Always distinguishes "EGT verified" from "Supplier-provided" listings —
/// the distinction is never blurred.
class DropshipHubScreen extends ConsumerWidget {
  const DropshipHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final supported = ref.watch(dropshipSupportedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dropshipTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: supported.when(
              data: (ok) {
                if (!ok) {
                  return EgtEmptyState(
                    icon: Icons.inventory_2_outlined,
                    body: l10n.dropshipUnavailable,
                  );
                }
                return const _DropshipListings();
              },
              loading: () => const EgtSkeletonList(),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(dropshipSupportedProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropshipListings extends ConsumerWidget {
  const _DropshipListings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final listings = ref.watch(dropshipListingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dropshipListingsProvider),
      child: listings.when(
        data: (list) {
          if (list.isEmpty) {
            return EgtEmptyState(
              icon: Icons.inventory_2_outlined,
              body: l10n.dropshipEmpty,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(EgtDimens.s16),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: EgtDimens.s12),
            itemBuilder: (_, i) => _DropshipCard(listing: list[i]),
          );
        },
        loading: () => const EgtSkeletonList(),
        error: (e, _) => EgtErrorView(
            error: e,
            onRetry: () => ref.invalidate(dropshipListingsProvider)),
      ),
    );
  }
}

class _DropshipCard extends StatelessWidget {
  const _DropshipCard({required this.listing});
  final DropshipListing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chip = listing.verifiedByEgt
        ? StatusChip.positive(l10n.dropshipVerified)
        : StatusChip.neutral(l10n.dropshipSupplier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(listing.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                chip,
              ],
            ),
            if (listing.moqLabel != null) ...[
              const SizedBox(height: 6),
              Text(listing.moqLabel!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: EgtColors.steel)),
            ],
          ],
        ),
      ),
    );
  }
}
