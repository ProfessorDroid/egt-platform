/// Local brand asset paths + product-image resolution.
///
/// Brand assets were downloaded from the live site during the Phase 0 audit
/// into `assets/brand/`. Only 8 of the 16 verified products have a local
/// image; the rest resolve to the backend `imageUrl` or a neutral placeholder.
/// Never invent product images.
class BrandAssets {
  BrandAssets._();

  static const String logo = 'assets/brand/egt-logo.png';
  static const String heroShipping = 'assets/brand/hero-export-shipping.webp';

  /// Product id/slug -> local asset. Keys must match backend product slugs.
  static const Map<String, String> productImages = {
    'cotton-wiping-rags': 'assets/brand/product-cotton-wiping-rags.webp',
    'dishwash-liquid': 'assets/brand/product-dishwash-liquid.png',
    'car-wash-shampoo': 'assets/brand/product-car-wash-shampoo.png',
    'carnauba-wax': 'assets/brand/product-carnauba-wax.jpg',
    'floor-cleaner': 'assets/brand/product-floor-cleaner.png',
    'wheat-flour': 'assets/brand/product-wheat-flour.jpg',
    'biomass-pellets': 'assets/brand/product-biomass-pellets.jpg',
    'potatoes': 'assets/brand/product-potatoes.jpg',
  };

  static String? forProduct(String productId) => productImages[productId];
}
