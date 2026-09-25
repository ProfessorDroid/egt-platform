import '../../domain/entities/catalog.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/catalog_remote.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._remote);
  final CatalogRemoteDataSource _remote;

  @override
  Future<HomeContent> getHomeContent() =>
      _remote.home().then((dto) => dto.toEntity());

  @override
  Future<List<Product>> getProducts({
    String? query,
    String? categoryId,
    String? sort,
    bool? privateLabelOnly,
  }) =>
      _remote
          .products(
              query: query,
              categoryId: categoryId,
              sort: sort,
              privateLabelOnly: privateLabelOnly)
          .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<List<Category>> getCategories() =>
      _remote.categories().then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<Product> getProduct(String id) =>
      _remote.product(id).then((dto) => dto.toEntity());
}
