import '../../domain/entities/trade.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/trade_remote.dart';

class TradeRepositoryImpl
    implements RfqRepository, QuotationRepository, OrderRepository, ShipmentRepository {
  TradeRepositoryImpl(this._remote);
  final TradeRemoteDataSource _remote;

  // --- RfqRepository ---
  @override
  Future<Rfq> submit(RfqDraft draft) =>
      _remote.submitRfq(draft).then((dto) => dto.toEntity());

  @override
  Future<List<Rfq>> myRfqs() =>
      _remote.myRfqs().then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<Rfq> getRfq(String id) =>
      _remote.rfq(id).then((dto) => dto.toEntity());

  // --- QuotationRepository ---
  @override
  Future<List<Quotation>> myQuotations() => _remote
      .myQuotations()
      .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<Quotation> getQuotation(String id) =>
      _remote.quotation(id).then((dto) => dto.toEntity());

  @override
  Future<Quotation> accept(String id) =>
      _remote.acceptQuotation(id).then((dto) => dto.toEntity());

  @override
  Future<Quotation> requestRevision(String id, String note) =>
      _remote.requestRevision(id, note).then((dto) => dto.toEntity());

  @override
  Future<void> askEgt(String id, String message) => _remote.askEgt(id, message);

  // --- OrderRepository ---
  @override
  Future<List<Order>> myOrders() =>
      _remote.myOrders().then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<Order> getOrder(String id) =>
      _remote.order(id).then((dto) => dto.toEntity());

  @override
  Future<List<Milestone>> getMilestones(String orderId) => _remote
      .milestones(orderId)
      .then((list) => list.map((e) => e.toEntity()).toList());

  // --- ShipmentRepository ---
  @override
  Future<Shipment> track(String id) =>
      _remote.track(id).then((dto) => dto.toEntity());

  @override
  Future<Shipment> getShipment(String id) =>
      _remote.shipment(id).then((dto) => dto.toEntity());
}
