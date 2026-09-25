/// Growth domain: supplier portal, private label, dropship, search, saved items.

enum SupplierApplicationStatus { pendingReview, approved, changesRequired, rejected }

extension SupplierApplicationStatusX on SupplierApplicationStatus {
  String get key => toString().split('.').last;
  static SupplierApplicationStatus fromKey(String? key) =>
      SupplierApplicationStatus.values.firstWhere(
        (e) => e.key == key,
        orElse: () => SupplierApplicationStatus.pendingReview,
      );
}

class SupplierApplication {
  const SupplierApplication({
    required this.id,
    required this.companyName,
    required this.status,
    required this.submittedAt,
    this.reviewerNote,
  });

  final String id;
  final String companyName;
  final SupplierApplicationStatus status;
  final DateTime submittedAt;
  final String? reviewerNote;

  /// Supplier listings NEVER auto-publish — the EGT team reviews everything.
  bool get isPending => status == SupplierApplicationStatus.pendingReview;
}

enum PrivateLabelStatus { submitted, underReview, artworkPending, approved, inProduction, closed }

/// 9-step private-label request draft. Persisted locally until submitted.
class PrivateLabelDraft {
  PrivateLabelDraft({
    this.productId,
    this.productName,
    this.brandName,
    this.packagingType,
    this.size,
    this.labelRequirements,
    this.quantity,
    this.unit,
    this.destinationCountry,
    this.artworkPaths = const [],
  });

  String? productId;
  String? productName;
  String? brandName;
  String? packagingType;
  String? size;
  String? labelRequirements;
  String? quantity;
  String? unit;
  String? destinationCountry;
  List<String> artworkPaths;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'brandName': brandName,
        'packagingType': packagingType,
        'size': size,
        'labelRequirements': labelRequirements,
        'quantity': quantity,
        'unit': unit,
        'destinationCountry': destinationCountry,
        'artworkPaths': artworkPaths,
      };

  factory PrivateLabelDraft.fromJson(Map<String, dynamic> json) => PrivateLabelDraft(
        productId: json['productId'] as String?,
        productName: json['productName'] as String?,
        brandName: json['brandName'] as String?,
        packagingType: json['packagingType'] as String?,
        size: json['size'] as String?,
        labelRequirements: json['labelRequirements'] as String?,
        quantity: json['quantity'] as String?,
        unit: json['unit'] as String?,
        destinationCountry: json['destinationCountry'] as String?,
        artworkPaths: (json['artworkPaths'] as List?)?.cast<String>() ?? const [],
      );
}

class PrivateLabelRequest {
  const PrivateLabelRequest({
    required this.id,
    required this.productName,
    required this.brandName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String productName;
  final String brandName;
  final PrivateLabelStatus status;
  final DateTime createdAt;
}

class DropshipListing {
  const DropshipListing({
    required this.id,
    required this.title,
    required this.verifiedByEgt,
    this.imageUrl,
    this.moqLabel,
  });

  final String id;
  final String title;

  /// true -> "EGT verified" chip; false -> "Supplier-provided" chip.
  /// The distinction is always shown — never blurred.
  final bool verifiedByEgt;
  final String? imageUrl;
  final String? moqLabel;
}

class SearchResponse {
  const SearchResponse({
    this.products = const [],
    this.rfqs = const [],
    this.orders = const [],
    this.documents = const [],
  });

  /// Results are scoped by auth on the backend: guests see catalogue only.
  final List<SearchProductHit> products;
  final List<SearchRfqHit> rfqs;
  final List<SearchOrderHit> orders;
  final List<SearchDocumentHit> documents;

  bool get isEmpty =>
      products.isEmpty && rfqs.isEmpty && orders.isEmpty && documents.isEmpty;
}

class SearchProductHit {
  const SearchProductHit({required this.id, required this.name, required this.category});
  final String id;
  final String name;
  final String category;
}

class SearchRfqHit {
  const SearchRfqHit({required this.id, required this.productName, required this.status});
  final String id;
  final String productName;
  final String status;
}

class SearchOrderHit {
  const SearchOrderHit({required this.id, required this.productName, required this.status});
  final String id;
  final String productName;
  final String status;
}

class SearchDocumentHit {
  const SearchDocumentHit({required this.id, required this.name, required this.category});
  final String id;
  final String name;
  final String category;
}
