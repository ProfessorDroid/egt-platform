import '../../domain/entities/catalog.dart';
import '../../domain/entities/growth.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/growth_remote.dart';

class GrowthRepositoryImpl
    implements
        PrivateLabelRepository,
        SupplierRepository,
        DropshipRepository,
        SearchRepository,
        SavedRepository {
  GrowthRepositoryImpl(this._remote);
  final GrowthRemoteDataSource _remote;

  // --- PrivateLabelRepository ---
  @override
  Future<PrivateLabelRequest> submit(PrivateLabelDraft draft) =>
      _remote.submitPrivateLabel(draft).then((dto) => dto.toEntity());

  @override
  Future<List<PrivateLabelRequest>> myRequests() => _remote
      .myPrivateLabelRequests()
      .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<PrivateLabelRequest> getRequest(String id) async {
    final all = await myRequests();
    return all.firstWhere((r) => r.id == id);
  }

  // --- SupplierRepository ---
  @override
  Future<SupplierApplication> apply({
    required String companyName,
    required String contactPerson,
    required String phone,
    required String productDetails,
    String? certifications,
  }) =>
      _remote
          .applySupplier(
            companyName: companyName,
            contactPerson: contactPerson,
            phone: phone,
            productDetails: productDetails,
            certifications: certifications,
          )
          .then((dto) => dto.toEntity());

  @override
  Future<List<SupplierApplication>> myApplications() => _remote
      .mySupplierApplications()
      .then((list) => list.map((e) => e.toEntity()).toList());

  // --- DropshipRepository ---
  @override
  Future<bool> isSupported() => _remote.dropshipSupported();

  @override
  Future<List<DropshipListing>> listings() => _remote
      .dropshipListings()
      .then((list) => list.map((e) => e.toEntity()).toList());

  // --- SearchRepository ---
  @override
  Future<SearchResponse> search(String query) =>
      _remote.search(query).then((dto) => dto.toEntity());

  // --- SavedRepository ---
  @override
  Future<List<Product>> savedProducts() => _remote
      .savedProducts()
      .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<void> saveProduct(String productId) => _remote.saveProduct(productId);

  @override
  Future<void> unsaveProduct(String productId) => _remote.unsaveProduct(productId);

  @override
  Future<bool> isSaved(String productId) async {
    final saved = await savedProducts();
    return saved.any((p) => p.id == productId);
  }
}
