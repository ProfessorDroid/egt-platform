import '../../domain/entities/catalog.dart';

/// DTOs for catalogue endpoints. Field names mirror the OpenAPI contract
/// (`packages/shared/openapi.yaml`); keep in sync with the backend child.

class ProductDto {
  ProductDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        category = json['category'] as String? ?? '',
        description = json['description'] as String?,
        specs = (json['specs'] as List?)?.cast<String>() ?? const [],
        orderVolume = json['orderVolume'] as String?,
        privateLabelAvailable = json['privateLabelAvailable'] as bool? ?? false,
        packagingOptions =
            (json['packagingOptions'] as List?)?.cast<String>() ?? const [],
        imageUrl = json['imageUrl'] as String?,
        localAssetKey = json['localAssetKey'] as String?;

  final String id;
  final String name;
  final String category;
  final String? description;
  final List<String> specs;
  final String? orderVolume;
  final bool privateLabelAvailable;
  final List<String> packagingOptions;
  final String? imageUrl;
  final String? localAssetKey;

  Product toEntity() => Product(
        id: id,
        name: name,
        category: category,
        description: description,
        specs: specs,
        orderVolume: orderVolume,
        privateLabelAvailable: privateLabelAvailable,
        packagingOptions: packagingOptions,
        imageUrl: imageUrl,
        localAssetKey: localAssetKey,
      );
}

class CategoryDto {
  CategoryDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        productCount = json['productCount'] as int?;

  final String id;
  final String name;
  final int? productCount;

  Category toEntity() => Category(id: id, name: name, productCount: productCount);
}

class HomeContentDto {
  HomeContentDto.fromJson(Map<String, dynamic> json)
      : heroTitle = json['heroTitle'] as String?,
        heroSubtitle = json['heroSubtitle'] as String?,
        quickRfqCategories = (json['quickRfqCategories'] as List? ?? [])
            .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>).toEntity())
            .toList(),
        popularProducts = (json['popularProducts'] as List? ?? [])
            .map((e) => ProductDto.fromJson(e as Map<String, dynamic>).toEntity())
            .toList(),
        sectors = (json['sectors'] as List? ?? [])
            .map((e) => SectorTile(
                id: (e as Map)['id'] as String, name: e['name'] as String))
            .toList(),
        stats = (json['stats'] as List? ?? [])
            .map((e) => StatTile(
                value: (e as Map)['value'] as String,
                label: e['label'] as String))
            .toList(),
        featuredProducts = (json['featuredProducts'] as List? ?? [])
            .map((e) => ProductDto.fromJson(e as Map<String, dynamic>).toEntity())
            .toList();

  final String? heroTitle;
  final String? heroSubtitle;
  final List<Category> quickRfqCategories;
  final List<Product> popularProducts;
  final List<SectorTile> sectors;
  final List<StatTile> stats;
  final List<Product> featuredProducts;

  HomeContent toEntity() => HomeContent(
        heroTitle: heroTitle,
        heroSubtitle: heroSubtitle,
        quickRfqCategories: quickRfqCategories,
        popularProducts: popularProducts,
        sectors: sectors,
        stats: stats,
        featuredProducts: featuredProducts,
      );
}
