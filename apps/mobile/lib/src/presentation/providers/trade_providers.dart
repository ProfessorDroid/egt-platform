import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/trade_remote.dart';
import '../../data/repositories/trade_repository_impl.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/repositories.dart';
import 'core_providers.dart';

final _tradeRepoProvider = Provider<TradeRepositoryImpl>((ref) {
  return TradeRepositoryImpl(TradeRemoteDataSource(ref.watch(apiClientProvider)));
});

final rfqRepositoryProvider = Provider<RfqRepository>((ref) => ref.watch(_tradeRepoProvider));
final quotationRepositoryProvider =
    Provider<QuotationRepository>((ref) => ref.watch(_tradeRepoProvider));
final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => ref.watch(_tradeRepoProvider));
final shipmentRepositoryProvider =
    Provider<ShipmentRepository>((ref) => ref.watch(_tradeRepoProvider));

final myRfqsProvider = FutureProvider<List<Rfq>>((ref) {
  return ref.watch(rfqRepositoryProvider).myRfqs();
});

final rfqDetailProvider = FutureProvider.family<Rfq, String>((ref, id) {
  return ref.watch(rfqRepositoryProvider).getRfq(id);
});

final myQuotationsProvider = FutureProvider<List<Quotation>>((ref) {
  return ref.watch(quotationRepositoryProvider).myQuotations();
});

final quotationDetailProvider = FutureProvider.family<Quotation, String>((ref, id) {
  return ref.watch(quotationRepositoryProvider).getQuotation(id);
});

final myOrdersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).myOrders();
});

final orderDetailProvider = FutureProvider.family<Order, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).getOrder(id);
});

final orderMilestonesProvider = FutureProvider.family<List<Milestone>, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).getMilestones(orderId);
});
