import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/catalog_remote.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/repositories/repositories.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(CatalogRemoteDataSource(ref.watch(apiClientProvider)));
});

final homeContentProvider = FutureProvider<HomeContent>((ref) {
  return ref.watch(catalogRepositoryProvider).getHomeContent();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogRepositoryProvider).getCategories();
});

/// Product list query state (search / filters / sort).
class ProductQuery {
  const ProductQuery({
    this.query = '',
    this.categoryId,
    this.sort,
    this.privateLabelOnly = false,
  });

  final String query;
  final String? categoryId;
  final String? sort; // 'name' | 'category'
  final bool privateLabelOnly;

  static const _unset = Object();

  /// Passing `categoryId: null` or `sort: null` clears that filter —
  /// pass [_unset] (the default) to leave it unchanged.
  ProductQuery copyWith({
    String? query,
    Object? categoryId = _unset,
    Object? sort = _unset,
    bool? privateLabelOnly,
  }) =>
      ProductQuery(
        query: query ?? this.query,
        categoryId:
            identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
        sort: identical(sort, _unset) ? this.sort : sort as String?,
        privateLabelOnly: privateLabelOnly ?? this.privateLabelOnly,
      );
}

final productQueryProvider = StateProvider<ProductQuery>((ref) => const ProductQuery());

final productsProvider = FutureProvider<List<Product>>((ref) {
  final q = ref.watch(productQueryProvider);
  return ref.watch(catalogRepositoryProvider).getProducts(
        query: q.query.isEmpty ? null : q.query,
        categoryId: q.categoryId,
        sort: q.sort,
        privateLabelOnly: q.privateLabelOnly,
      );
});

final productDetailProvider = FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).getProduct(id);
});
