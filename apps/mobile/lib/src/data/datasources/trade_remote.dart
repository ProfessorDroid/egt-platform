import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../domain/entities/trade.dart';
import '../dto/trade_dto.dart';

class TradeRemoteDataSource {
  TradeRemoteDataSource(this._api);
  final ApiClient _api;

  // --- RFQ ---
  Future<RfqDto> submitRfq(RfqDraft draft) async {
    final res = await _api.post(ApiEndpoints.rfqs, data: RfqDto.fromDraft(draft));
    final dto = RfqDto.fromJson(res.data as Map<String, dynamic>);
    // Attachments upload AFTER the RFQ exists, so a failed upload can never
    // fake a successful submission.
    for (final path in draft.attachmentPaths) {
      await uploadRfqAttachment(dto.id, path);
    }
    return dto;
  }

  Future<void> uploadRfqAttachment(String rfqId, String filePath) async {
    final fileName = filePath.split('/').last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await _api.post(ApiEndpoints.rfqAttachments(rfqId), data: form);
  }

  Future<List<RfqDto>> myRfqs() async {
    final res = await _api.get(ApiEndpoints.rfqs);
    final data = res.data;
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => RfqDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RfqDto> rfq(String id) async {
    final res = await _api.get(ApiEndpoints.rfq(id));
    return RfqDto.fromJson(res.data as Map<String, dynamic>);
  }

  // --- Quotations ---
  Future<List<QuotationDto>> myQuotations() async {
    final res = await _api.get(ApiEndpoints.quotations);
    final data = res.data;
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => QuotationDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<QuotationDto> quotation(String id) async {
    final res = await _api.get(ApiEndpoints.quotation(id));
    return QuotationDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<QuotationDto> acceptQuotation(String id) async {
    final res = await _api.post(ApiEndpoints.quotationAccept(id));
    return QuotationDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<QuotationDto> requestRevision(String id, String note) async {
    final res = await _api.post(ApiEndpoints.quotationRequestRevision(id),
        data: {'note': note});
    return QuotationDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> askEgt(String id, String message) async {
    await _api.post(ApiEndpoints.quotationAsk(id), data: {'message': message});
  }

  // --- Orders ---
  Future<List<OrderDto>> myOrders() async {
    final res = await _api.get(ApiEndpoints.orders);
    final data = res.data;
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => OrderDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderDto> order(String id) async {
    final res = await _api.get(ApiEndpoints.order(id));
    return OrderDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MilestoneDto>> milestones(String orderId) async {
    final res = await _api.get(ApiEndpoints.orderMilestones(orderId));
    final data = res.data;
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => MilestoneDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Shipments ---
  Future<ShipmentDto> track(String id) async {
    final res = await _api.get(ApiEndpoints.shipmentsTrack, query: {'q': id});
    return ShipmentDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ShipmentDto> shipment(String id) async {
    final res = await _api.get(ApiEndpoints.shipment(id));
    return ShipmentDto.fromJson(res.data as Map<String, dynamic>);
  }
}
