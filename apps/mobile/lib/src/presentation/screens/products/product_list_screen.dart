import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/catalog.dart';
import '../../providers/catalog_providers.dart';

/// Catalogue: search, filters (category / MOQ-style order volume /
/// private-label / packaging), sort. NO prices — "Request B2B Quote".
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = ref.watch(productsProvider);
    final query = ref.watch(productQueryProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBar(
              controller: _search,
              hintText: l10n.productsSearchHint,
              leading: const Icon(Icons.search),
              trailing: query.query.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          ref.read(productQueryProvider.notifier).state =
                              query.copyWith(query: '');
                        },
                      )
                    ]
                  : null,
              onChanged: (v) => ref
                  .read(productQueryProvider.notifier)
                  .state = query.copyWith(query: v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: categories.maybeWhen(
                    data: (cats) => DropdownButtonFormField<String?>(
                      value: query.categoryId,
                      decoration: InputDecoration(
                          labelText: l10n.productsFilters,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8)),
                      items: [
                        DropdownMenuItem<String?>(
                            value: null, child: Text(l10n.productsFilters)),
                        for (final c in cats)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => ref
                          .read(productQueryProvider.notifier)
                          .state = query.copyWith(categoryId: v),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: query.sort,
                  hint: Text(l10n.productsSort),
                  items: [
                    DropdownMenuItem(
                        value: null, child: Text(l10n.productsSort)),
                    DropdownMenuItem(
                        value: 'name', child: Text(l10n.productsSortName)),
                    DropdownMenuItem(
                        value: 'category',
                        child: Text(l10n.productsSortCategory)),
                  ],
                  onChanged: (v) => ref
                      .read(productQueryProvider.notifier)
                      .state = query.copyWith(sort: v),
                ),
              ],
            ),
          ),
          FilterChip(
            label: Text(l10n.productPrivateLabel),
            selected: query.privateLabelOnly,
            onSelected: (v) => ref
                .read(productQueryProvider.notifier)
                .state = query.copyWith(privateLabelOnly: v),
          ),
          Expanded(
            child: products.when(
              data: (list) {
                if (list.isEmpty) {
                  return EgtEmptyState(
                    title: l10n.productsNoResults,
                    actionLabel: l10n.actionClear,
                    onAction: () {
                      _search.clear();
                      ref.read(productQueryProvider.notifier).state =
                          const ProductQuery();
                    },
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(l10n.productsResults(list.length),
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(EgtDimens.s16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            ProductCard(product: list[i]),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const EgtSkeletonGrid(),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(productsProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
