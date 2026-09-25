import '../../domain/entities/trade.dart';

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

class RfqDto {
  RfqDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        productName = json['productName'] as String? ?? '',
        quantity = json['quantity'] as String? ?? '',
        destination = json['destination'] as String? ?? '',
        status = RfqStatusX.fromKey(json['status'] as String?),
        submittedAt = _dt(json['submittedAt']) ?? DateTime.now(),
        assignee = json['assignee'] as String?,
        nextStep = json['nextStep'] as String?;

  final String id;
  final String productName;
  final String quantity;
  final String destination;
  final RfqStatus status;
  final DateTime submittedAt;
  final String? assignee;
  final String? nextStep;

  Rfq toEntity() => Rfq(
        id: id,
        productName: productName,
        quantity: quantity,
        destination: destination,
        status: status,
        submittedAt: submittedAt,
        assignee: assignee,
        nextStep: nextStep,
      );

  /// Draft -> request body for POST /rfqs.
  static Map<String, dynamic> fromDraft(RfqDraft d) => {
        'productId': d.productId,
        'productName': d.productName,
        'customProductDetails': d.customProductDetails,
        'quantity': d.quantity,
        'unit': d.unit,
        'packaging': d.packaging,
        'privateLabel': d.privateLabel,
        'destinationCountry': d.destinationCountry,
        'destinationPort': d.destinationPort,
        'incoterm': d.incoterm.key,
        'specs': d.specs,
        'notes': d.notes,
      };
}

class QuotationDto {
  QuotationDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        rfqId = json['rfqId'] as String? ?? '',
        productName = json['productName'] as String? ?? '',
        status = _status(json['status'] as String?),
        validUntil = _dt(json['validUntil']) ?? DateTime.now(),
        leadTime = json['leadTime'] as String?,
        paymentTerms = json['paymentTerms'] as String?,
        totalDisplay = json['totalDisplay'] as String?,
        specSummary = json['specSummary'] as String?;

  final String id;
  final String rfqId;
  final String productName;
  final QuotationStatus status;
  final DateTime validUntil;
  final String? leadTime;
  final String? paymentTerms;
  final String? totalDisplay;
  final String? specSummary;

  static QuotationStatus _status(String? s) {
    switch (s) {
      case 'accepted':
        return QuotationStatus.accepted;
      case 'revisionRequested':
        return QuotationStatus.revisionRequested;
      case 'expired':
        return QuotationStatus.expired;
      default:
        return QuotationStatus.pending;
    }
  }

  Quotation toEntity() => Quotation(
        id: id,
        rfqId: rfqId,
        productName: productName,
        status: status,
        validUntil: validUntil,
        leadTime: leadTime,
        paymentTerms: paymentTerms,
        totalDisplay: totalDisplay,
        specSummary: specSummary,
      );
}

class MilestoneDto {
  MilestoneDto.fromJson(Map<String, dynamic> json)
      : key = json['key'] as String,
        label = json['label'] as String? ?? json['key'] as String,
        status = _status(json['status'] as String?),
        at = _dt(json['at']),
        note = json['note'] as String?;

  final String key;
  final String label;
  final MilestoneStatus status;
  final DateTime? at;
  final String? note;

  static MilestoneStatus _status(String? s) {
    switch (s) {
      case 'done':
        return MilestoneStatus.done;
      case 'current':
        return MilestoneStatus.current;
      default:
        return MilestoneStatus.upcoming;
    }
  }

  Milestone toEntity() =>
      Milestone(key: key, label: label, status: status, at: at, note: note);
}

class OrderDto {
  OrderDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        productName = json['productName'] as String? ?? '',
        status = _status(json['status'] as String?),
        createdAt = _dt(json['createdAt']) ?? DateTime.now(),
        quotationId = json['quotationId'] as String?,
        trackingIds = (json['trackingIds'] as List?)?.cast<String>() ?? const [];

  final String id;
  final String productName;
  final OrderStatus status;
  final DateTime createdAt;
  final String? quotationId;
  final List<String> trackingIds;

  static OrderStatus _status(String? s) => OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == s,
        orElse: () => OrderStatus.confirmed,
      );

  Order toEntity() => Order(
        id: id,
        productName: productName,
        status: status,
        createdAt: createdAt,
        quotationId: quotationId,
        trackingIds: trackingIds,
      );
}

class ShipmentDto {
  ShipmentDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        orderId = json['orderId'] as String?,
        status = json['status'] as String? ?? '',
        trackingNumber = json['trackingNumber'] as String?,
        carrierLabel = json['carrierLabel'] as String?,
        updates = (json['updates'] as List? ?? [])
            .map((e) => ShipmentUpdate(
                  at: _dt((e as Map)['at']) ?? DateTime.now(),
                  message: e['message'] as String? ?? '',
                  location: e['location'] as String?,
                  verifiedAt:
                      _dt(e['verifiedAt']) ?? _dt(e['at']) ?? DateTime.now(),
                ))
            .toList();

  final String id;
  final String? orderId;
  final String status;
  final String? trackingNumber;
  final String? carrierLabel;
  final List<ShipmentUpdate> updates;

  Shipment toEntity() => Shipment(
        id: id,
        orderId: orderId,
        status: status,
        trackingNumber: trackingNumber,
        carrierLabel: carrierLabel,
        updates: updates,
      );
}
