/// Catalogue domain: products, categories, home content.
/// All display data is backend-driven; empty states when the backend is silent.

class ProductDocument {
  const ProductDocument({required this.id, required this.name, this.mimeType});
  final String id;
  final String name;
  final String? mimeType;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.specs = const [],
    this.orderVolume,
    this.privateLabelAvailable = false,
    this.packagingOptions = const [],
    this.imageUrl,
    this.localAssetKey,
    this.documents = const [],
  });

  final String id;
  final String name;
  final String category;
  final String? description;

  /// Verbatim spec bullets from the catalogue (never invented).
  final List<String> specs;

  /// MOQ-style figure, e.g. "500 KG / 20ft FCL Bulk". Shown as-is, never a price.
  final String? orderVolume;
  final bool privateLabelAvailable;
  final List<String> packagingOptions;
  final String? imageUrl;
  final String? localAssetKey;
  final List<ProductDocument> documents;

  /// No prices are published anywhere — catalogue CTAs always say "Request B2B Quote".
  bool get hasImage => imageUrl != null || localAssetKey != null;
}

class Category {
  const Category({required this.id, required this.name, this.productCount});
  final String id;
  final String name;
  final int? productCount;
}

class StatTile {
  const StatTile({required this.value, required this.label});
  final String value;
  final String label;
}

class SectorTile {
  const SectorTile({required this.id, required this.name});
  final String id;
  final String name;
}

/// Home screen content contract. Every section is optional — the UI renders
/// graceful empty states for whatever the backend does not provide.
class HomeContent {
  const HomeContent({
    this.heroTitle,
    this.heroSubtitle,
    this.quickRfqCategories = const [],
    this.popularProducts = const [],
    this.sectors = const [],
    this.stats = const [],
    this.featuredProducts = const [],
  });

  final String? heroTitle;
  final String? heroSubtitle;
  final List<Category> quickRfqCategories;
  final List<Product> popularProducts;
  final List<SectorTile> sectors;
  final List<StatTile> stats;
  final List<Product> featuredProducts;

  bool get isEmpty =>
      quickRfqCategories.isEmpty &&
      popularProducts.isEmpty &&
      sectors.isEmpty &&
      stats.isEmpty &&
      featuredProducts.isEmpty;
}
