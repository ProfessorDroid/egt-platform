import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/catalog.dart';
import '../l10n/app_localizations.dart';
import '../theme/egt_colors.dart';
import '../theme/egt_dimens.dart';
import 'product_image.dart';

/// Product card for grids/lists. No prices anywhere — CTA is "Request B2B Quote".
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onQuote});

  final Product product;
  final VoidCallback? onQuote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: product.name,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/products/${product.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: EgtProductImage(
                  productId: product.id,
                  imageUrl: product.imageUrl,
                  localAssetKey: product.localAssetKey,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(EgtDimens.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.category,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: EgtColors.red)),
                    const SizedBox(height: 4),
                    Text(product.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (product.orderVolume != null) ...[
                      const SizedBox(height: 4),
                      Text(product.orderVolume!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onQuote ??
                            () => context.push('/rfq/new?productId=${product.id}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(l10n.productsRequestQuote,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
