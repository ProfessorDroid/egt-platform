import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../assets/brand_assets.dart';
import '../theme/egt_colors.dart';
import 'skeleton.dart';

/// Resolves a product image: local brand asset -> backend imageUrl -> placeholder.
/// Never invents product imagery.
class EgtProductImage extends StatelessWidget {
  const EgtProductImage({
    super.key,
    this.productId,
    this.imageUrl,
    this.localAssetKey,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  final String? productId;
  final String? imageUrl;
  final String? localAssetKey;
  final BoxFit fit;
  final double borderRadius;

  String? get _asset =>
      localAssetKey ??
      (productId != null ? BrandAssets.forProduct(productId!) : null);

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    final child = asset != null
        ? Image.asset(asset, fit: fit,
            errorBuilder: (_, __, ___) => _placeholder())
        : (imageUrl != null && imageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: fit,
                placeholder: (_, __) => const EgtSkeleton(height: double.infinity, radius: 0),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder();
    if (borderRadius <= 0) return SizedBox.expand(child: child);
    return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox.expand(child: child));
  }

  Widget _placeholder() => Container(
        color: EgtColors.manifest,
        child: const Center(
            child: Icon(Icons.inventory_2_outlined,
                size: 40, color: EgtColors.steel)),
      );
}
