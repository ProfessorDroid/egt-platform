import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../domain/entities/growth.dart';
import '../../providers/growth_providers.dart';

/// Authenticated global search. Results are backend-scoped: guests see the
/// catalogue only. RFQ/order/document suggestions echo the user's own records —
/// nothing is fabricated.
class GlobalSearchScreen extends ConsumerWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(EgtDimens.s16),
            child: EgtTextField(
              hint: l10n.searchHint,
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              onChanged: (q) =>
                  ref.read(searchQueryProvider.notifier).state = q,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l10n.searchScoped,
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.when(
              data: (res) => _ResultsView(results: res),
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorGeneric)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.results});
  final SearchResponse results;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (results.isEmpty) {
      return EgtEmptyState(
          icon: Icons.search_off_outlined, body: l10n.searchNoResults);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (results.products.isNotEmpty) ...[
          _SectionTitle(l10n.searchSectionProducts),
          for (final p in results.products)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(p.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(p.category,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => context.push('/products/${p.id}'),
            ),
        ],
        if (results.rfqs.isNotEmpty) ...[
          _SectionTitle(l10n.searchSectionRfqs),
          for (final r in results.rfqs)
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: Text(r.productName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(r.status),
              onTap: () => context.push('/rfq/result/${r.id}'),
            ),
        ],
        if (results.orders.isNotEmpty) ...[
          _SectionTitle(l10n.searchSectionOrders),
          for (final o in results.orders)
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: Text(o.productName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(o.status),
              onTap: () => context.push('/orders/${o.id}'),
            ),
        ],
        if (results.documents.isNotEmpty) ...[
          _SectionTitle(l10n.searchSectionDocuments),
          for (final d in results.documents)
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(d.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(d.category),
              onTap: () => context.push('/documents'),
            ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
