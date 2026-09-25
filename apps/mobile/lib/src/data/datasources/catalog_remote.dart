import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../dto/catalog_dto.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._api);
  final ApiClient _api;

  Future<HomeContentDto> home() async {
    final res = await _api.get(ApiEndpoints.home);
    return HomeContentDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ProductDto>> products({
    String? query,
    String? categoryId,
    String? sort,
    bool? privateLabelOnly,
  }) async {
    final res = await _api.get(ApiEndpoints.products, query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (categoryId != null) 'categoryId': categoryId,
      if (sort != null) 'sort': sort,
      if (privateLabelOnly == true) 'privateLabel': 'true',
    });
    final data = res.data;
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => ProductDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CategoryDto>> categories() async {
    final res = await _api.get(ApiEndpoints.categories);
    final data = res.data;
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductDto> product(String id) async {
    final res = await _api.get(ApiEndpoints.product(id));
    return ProductDto.fromJson(res.data as Map<String, dynamic>);
  }
}
