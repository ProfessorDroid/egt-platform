/// Trade domain: RFQs, quotations, orders, shipments, milestones.

enum RfqStatus { draft, submitted, underReview, quoted, closed }

extension RfqStatusX on RfqStatus {
  String get key => toString().split('.').last;
  static RfqStatus fromKey(String? key) => RfqStatus.values.firstWhere(
        (e) => e.key == key,
        orElse: () => RfqStatus.submitted,
      );
}

enum Incoterm { exw, fob, cif, ddp, other }

extension IncotermX on Incoterm {
  String get key => toString().split('.').last.toUpperCase();
  static Incoterm fromKey(String? key) => Incoterm.values.firstWhere(
        (e) => e.key == key?.toUpperCase(),
        orElse: () => Incoterm.fob,
      );
}

/// The 12-step RFQ wizard draft. Persisted locally until submitted.
class RfqDraft {
  RfqDraft({
    this.productId,
    this.productName,
    this.customProductDetails,
    this.quantity,
    this.unit,
    this.packaging,
    this.privateLabel = false,
    this.destinationCountry,
    this.destinationPort,
    this.incoterm = Incoterm.fob,
    this.specs,
    this.notes,
    this.attachmentPaths = const [],
  });

  String? productId;
  String? productName;
  String? customProductDetails;
  String? quantity;
  String? unit;
  String? packaging;
  bool privateLabel;
  String? destinationCountry;
  String? destinationPort;
  Incoterm incoterm;
  String? specs;
  String? notes;
  List<String> attachmentPaths;

  String get displayProduct => productName ?? customProductDetails ?? '—';
  String get displayQuantity =>
      [quantity, unit].where((e) => e != null && e.isNotEmpty).join(' ');
  String get displayDestination =>
      [destinationPort, destinationCountry].where((e) => e != null && e.isNotEmpty).join(', ');

  bool get isProductStepValid =>
      (productName != null && productName!.isNotEmpty) ||
      (customProductDetails != null && customProductDetails!.trim().length >= 3);

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'customProductDetails': customProductDetails,
        'quantity': quantity,
        'unit': unit,
        'packaging': packaging,
        'privateLabel': privateLabel,
        'destinationCountry': destinationCountry,
        'destinationPort': destinationPort,
        'incoterm': incoterm.key,
        'specs': specs,
        'notes': notes,
        'attachmentPaths': attachmentPaths,
      };

  factory RfqDraft.fromJson(Map<String, dynamic> json) => RfqDraft(
        productId: json['productId'] as String?,
        productName: json['productName'] as String?,
        customProductDetails: json['customProductDetails'] as String?,
        quantity: json['quantity'] as String?,
        unit: json['unit'] as String?,
        packaging: json['packaging'] as String?,
        privateLabel: json['privateLabel'] as bool? ?? false,
        destinationCountry: json['destinationCountry'] as String?,
        destinationPort: json['destinationPort'] as String?,
        incoterm: IncotermX.fromKey(json['incoterm'] as String?),
        specs: json['specs'] as String?,
        notes: json['notes'] as String?,
        attachmentPaths: (json['attachmentPaths'] as List?)?.cast<String>() ?? const [],
      );
}

class Rfq {
  const Rfq({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.destination,
    required this.status,
    required this.submittedAt,
    this.assignee,
    this.nextStep,
  });

  final String id;
  final String productName;
  final String quantity;
  final String destination;
  final RfqStatus status;
  final DateTime submittedAt;
  final String? assignee;
  final String? nextStep;
}

enum QuotationStatus { pending, accepted, revisionRequested, expired }

class Quotation {
  const Quotation({
    required this.id,
    required this.rfqId,
    required this.productName,
    required this.status,
    required this.validUntil,
    this.leadTime,
    this.paymentTerms,
    this.totalDisplay,
    this.specSummary,
    this.documentIds = const [],
  });

  final String id;
  final String rfqId;
  final String productName;
  final QuotationStatus status;
  final DateTime validUntil;

  /// Lead time / payment terms / totals come ONLY from the backend proforma —
  /// never invented client-side.
  final String? leadTime;
  final String? paymentTerms;
  final String? totalDisplay;
  final String? specSummary;
  final List<String> documentIds;
}

enum OrderStatus { confirmed, inProduction, qualityCheck, shipped, delivered, cancelled }

class Order {
  const Order({
    required this.id,
    required this.productName,
    required this.status,
    required this.createdAt,
    this.quotationId,
    this.trackingIds = const [],
  });

  final String id;
  final String productName;
  final OrderStatus status;
  final DateTime createdAt;
  final String? quotationId;
  final List<String> trackingIds;
}

enum MilestoneStatus { done, current, upcoming }

/// Order-journey milestone. Labels and timestamps are backend-driven;
/// [key] is the stable contract key (see openapi.yaml).
class Milestone {
  const Milestone({
    required this.key,
    required this.label,
    required this.status,
    this.at,
    this.note,
  });

  final String key;
  final String label;
  final MilestoneStatus status;
  final DateTime? at;
  final String? note;
}

/// The 13 milestone contract keys for the order journey timeline.
/// Labels/dates always come from the backend DTO — these keys only give the
/// timeline a stable order. Keep in sync with `packages/shared/openapi.yaml`.
class MilestoneKeys {
  MilestoneKeys._();
  static const List<String> ordered = [
    'rfq_received',
    'quotation_sent',
    'quotation_accepted',
    'proforma_invoice',
    'advance_payment',
    'production',
    'quality_inspection',
    'packing',
    'shipment_booking',
    'customs_clearance',
    'shipped',
    'in_transit',
    'delivered',
  ];
}

class ShipmentUpdate {
  const ShipmentUpdate({
    required this.at,
    required this.message,
    required this.verifiedAt,
    this.location,
  });

  final DateTime at;
  final String message;
  final String? location;

  /// Every update is labeled "Last verified update" in the UI — the app never
  /// fabricates realtime carrier data.
  final DateTime verifiedAt;
}

class Shipment {
  const Shipment({
    required this.id,
    required this.status,
    this.orderId,
    this.trackingNumber,
    this.carrierLabel,
    this.updates = const [],
  });

  final String id;
  final String? orderId;
  final String status;
  final String? trackingNumber;
  final String? carrierLabel;
  final List<ShipmentUpdate> updates;
}
