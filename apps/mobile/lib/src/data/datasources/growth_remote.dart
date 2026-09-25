import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/growth.dart';
import '../../domain/entities/trade.dart';
import '../dto/catalog_dto.dart';
import '../dto/growth_dto.dart';
import '../dto/trade_dto.dart';

class GrowthRemoteDataSource {
  GrowthRemoteDataSource(this._api);
  final ApiClient _api;

  static List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) {
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => f(e as Map<String, dynamic>)).toList();
  }

  // --- Private label ---
  Future<PrivateLabelRequestDto> submitPrivateLabel(PrivateLabelDraft draft) async {
    final res = await _api.post(ApiEndpoints.privateLabel,
        data: PrivateLabelRequestDto.fromDraft(draft));
    return PrivateLabelRequestDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PrivateLabelRequestDto>> myPrivateLabelRequests() async {
    final res = await _api.get(ApiEndpoints.privateLabel);
    return _list(res.data, PrivateLabelRequestDto.fromJson);
  }

  // --- Supplier ---
  Future<SupplierApplicationDto> applySupplier({
    required String companyName,
    required String contactPerson,
    required String phone,
    required String productDetails,
    String? certifications,
  }) async {
    final res = await _api.post(ApiEndpoints.supplierApplications, data: {
      'companyName': companyName,
      'contactPerson': contactPerson,
      'phone': phone,
      'productDetails': productDetails,
      if (certifications != null && certifications.isNotEmpty)
        'certifications': certifications,
    });
    return SupplierApplicationDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SupplierApplicationDto>> mySupplierApplications() async {
    final res = await _api.get(ApiEndpoints.supplierApplications);
    return _list(res.data, SupplierApplicationDto.fromJson);
  }

  // --- Dropship ---
  Future<bool> dropshipSupported() async {
    final res = await _api.get(ApiEndpoints.dropshipSupport);
    return (res.data as Map)['supported'] as bool? ?? false;
  }

  Future<List<DropshipListingDto>> dropshipListings() async {
    final res = await _api.get(ApiEndpoints.dropshipListings);
    return _list(res.data, DropshipListingDto.fromJson);
  }

  // --- Search ---
  Future<SearchResponseDto> search(String query) async {
    final res = await _api.get(ApiEndpoints.search, query: {'q': query});
    return SearchResponseDto.fromJson(res.data as Map<String, dynamic>);
  }

  // --- Saved products ---
  Future<List<ProductDto>> savedProducts() async {
    final res = await _api.get('/users/me/saved-products');
    return _list(res.data, ProductDto.fromJson);
  }

  Future<void> saveProduct(String productId) async {
    await _api.post('/users/me/saved-products', data: {'productId': productId});
  }

  Future<void> unsaveProduct(String productId) async {
    await _api.delete('/users/me/saved-products/$productId');
  }
}
