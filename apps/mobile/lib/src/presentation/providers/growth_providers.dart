import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/growth_remote.dart';
import '../../data/repositories/growth_repository_impl.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/growth.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/repositories.dart';
import 'core_providers.dart';

final _growthRepoProvider = Provider<GrowthRepositoryImpl>((ref) {
  return GrowthRepositoryImpl(GrowthRemoteDataSource(ref.watch(apiClientProvider)));
});

final privateLabelRepositoryProvider =
    Provider<PrivateLabelRepository>((ref) => ref.watch(_growthRepoProvider));
final supplierRepositoryProvider =
    Provider<SupplierRepository>((ref) => ref.watch(_growthRepoProvider));
final dropshipRepositoryProvider =
    Provider<DropshipRepository>((ref) => ref.watch(_growthRepoProvider));
final searchRepositoryProvider =
    Provider<SearchRepository>((ref) => ref.watch(_growthRepoProvider));
final savedRepositoryProvider =
    Provider<SavedRepository>((ref) => ref.watch(_growthRepoProvider));

final myPrivateLabelRequestsProvider = FutureProvider<List<PrivateLabelRequest>>((ref) {
  return ref.watch(privateLabelRepositoryProvider).myRequests();
});

final mySupplierApplicationsProvider = FutureProvider<List<SupplierApplication>>((ref) {
  return ref.watch(supplierRepositoryProvider).myApplications();
});

final dropshipSupportedProvider = FutureProvider<bool>((ref) {
  return ref.watch(dropshipRepositoryProvider).isSupported();
});

final dropshipListingsProvider = FutureProvider<List<DropshipListing>>((ref) {
  return ref.watch(dropshipRepositoryProvider).listings();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<SearchResponse>((ref) {
  final q = ref.watch(searchQueryProvider).trim();
  if (q.isEmpty) return Future.value(const SearchResponse());
  return ref.watch(searchRepositoryProvider).search(q);
});

final savedProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(savedRepositoryProvider).savedProducts();
});

final isProductSavedProvider = FutureProvider.family<bool, String>((ref, productId) {
  return ref.watch(savedRepositoryProvider).isSaved(productId);
});
