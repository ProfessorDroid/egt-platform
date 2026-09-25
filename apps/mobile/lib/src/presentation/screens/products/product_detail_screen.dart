import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/launch_helper.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/catalog.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/growth_providers.dart';

/// Product detail: gallery, specs, MOQ (order volume), packaging,
/// customization, private-label option, documents, CTAs.
/// No prices — "Request This Product" opens the RFQ wizard prefilled.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final product = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.productShare,
            onPressed: () {
              final p = ref.read(productDetailProvider(productId)).valueOrNull;
              if (p != null) {
                ref.read(analyticsProvider).logEvent(
                    'product_viewed', {'product_id': p.id});
                LaunchHelper.shareText(
                    '${p.name} — https://eaglegoodstrading.com/app/product/${p.id}');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: product.when(
              data: (p) => _DetailBody(product: p),
              loading: () => const EgtSkeletonList(itemCount: 3),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(productDetailProvider(productId))),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saved = ref.watch(isProductSavedProvider(product.id));

    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: EgtProductImage(
            productId: product.id,
            imageUrl: product.imageUrl,
            localAssetKey: product.localAssetKey,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.category,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: EgtColors.red)),
              const SizedBox(height: 4),
              Text(product.name,
                  style: Theme.of(context).textTheme.displaySmall),
              if (product.description != null) ...[
                const SizedBox(height: 8),
                Text(product.description!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (product.orderVolume != null)
                    StatusChip.brand(
                        '${l10n.productMoq}: ${product.orderVolume}'),
                  if (product.privateLabelAvailable)
                    StatusChip.positive(l10n.productPrivateLabel),
                ],
              ),
              if (product.specs.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(l10n.productSpecs,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final spec in product.specs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check,
                            size: 18, color: EgtColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(spec,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium)),
                      ],
                    ),
                  ),
              ],
              if (product.packagingOptions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.productPackaging,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.packagingOptions
                      .map((p) => Chip(label: Text(p)))
                      .toList(),
                ),
              ],
              if (product.privateLabelAvailable) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.branding_watermark_outlined,
                        color: EgtColors.red),
                    title: Text(l10n.productPrivateLabel),
                    subtitle: Text(l10n.productPrivateLabelBody),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/private-label/new'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              EgtButton(
                label: l10n.productRequest,
                icon: Icons.request_quote_outlined,
                onPressed: () {
                  ref.read(analyticsProvider).logEvent(
                      'rfq_started', {'source': 'product', 'product_id': product.id});
                  context.push('/rfq/new?productId=${product.id}');
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: EgtOutlineButton(
                      label: saved.maybeWhen(
                          data: (v) => v
                              ? l10n.productAddedToRfq
                              : l10n.productAddToRfq,
                          orElse: () => l10n.productAddToRfq),
                      icon: Icons.bookmark_border,
                      onPressed: () async {
                        final repo = ref.read(savedRepositoryProvider);
                        final isSaved = await repo.isSaved(product.id);
                        if (isSaved) {
                          await repo.unsaveProduct(product.id);
                        } else {
                          await repo.saveProduct(product.id);
                        }
                        ref.invalidate(isProductSavedProvider(product.id));
                        ref.invalidate(savedProductsProvider);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EgtOutlineButton(
                      label: l10n.productShare,
                      icon: Icons.share_outlined,
                      onPressed: () => LaunchHelper.shareText(
                          '${product.name} — https://eaglegoodstrading.com/app/product/${product.id}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
