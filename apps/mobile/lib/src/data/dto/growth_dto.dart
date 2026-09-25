import '../../domain/entities/growth.dart';
import 'catalog_dto.dart';

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

class SupplierApplicationDto {
  SupplierApplicationDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        companyName = json['companyName'] as String? ?? '',
        status = SupplierApplicationStatusX.fromKey(json['status'] as String?),
        submittedAt = _dt(json['submittedAt']) ?? DateTime.now(),
        reviewerNote = json['reviewerNote'] as String?;

  final String id;
  final String companyName;
  final SupplierApplicationStatus status;
  final DateTime submittedAt;
  final String? reviewerNote;

  SupplierApplication toEntity() => SupplierApplication(
      id: id, companyName: companyName, status: status,
      submittedAt: submittedAt, reviewerNote: reviewerNote);
}

class PrivateLabelRequestDto {
  PrivateLabelRequestDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        productName = json['productName'] as String? ?? '',
        brandName = json['brandName'] as String? ?? '',
        status = _status(json['status'] as String?),
        createdAt = _dt(json['createdAt']) ?? DateTime.now();

  final String id;
  final String productName;
  final String brandName;
  final PrivateLabelStatus status;
  final DateTime createdAt;

  static PrivateLabelStatus _status(String? s) => PrivateLabelStatus.values.firstWhere(
        (e) => e.toString().split('.').last == s,
        orElse: () => PrivateLabelStatus.submitted,
      );

  PrivateLabelRequest toEntity() => PrivateLabelRequest(
      id: id, productName: productName, brandName: brandName,
      status: status, createdAt: createdAt);

  static Map<String, dynamic> fromDraft(PrivateLabelDraft d) => {
        'productId': d.productId,
        'productName': d.productName,
        'brandName': d.brandName,
        'packagingType': d.packagingType,
        'size': d.size,
        'labelRequirements': d.labelRequirements,
        'quantity': d.quantity,
        'unit': d.unit,
        'destinationCountry': d.destinationCountry,
      };
}

class DropshipListingDto {
  DropshipListingDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        title = json['title'] as String? ?? '',
        verifiedByEgt = json['verifiedByEgt'] as bool? ?? false,
        imageUrl = json['imageUrl'] as String?,
        moqLabel = json['moqLabel'] as String?;

  final String id;
  final String title;
  final bool verifiedByEgt;
  final String? imageUrl;
  final String? moqLabel;

  DropshipListing toEntity() => DropshipListing(
      id: id, title: title, verifiedByEgt: verifiedByEgt,
      imageUrl: imageUrl, moqLabel: moqLabel);
}

class SearchResponseDto {
  SearchResponseDto.fromJson(Map<String, dynamic> json)
      : products = (json['products'] as List? ?? [])
            .map((e) => SearchProductHit(
                id: (e as Map)['id'] as String,
                name: e['name'] as String? ?? '',
                category: e['category'] as String? ?? ''))
            .toList(),
        rfqs = (json['rfqs'] as List? ?? [])
            .map((e) => SearchRfqHit(
                id: (e as Map)['id'] as String,
                productName: e['productName'] as String? ?? '',
                status: e['status'] as String? ?? ''))
            .toList(),
        orders = (json['orders'] as List? ?? [])
            .map((e) => SearchOrderHit(
                id: (e as Map)['id'] as String,
                productName: e['productName'] as String? ?? '',
                status: e['status'] as String? ?? ''))
            .toList(),
        documents = (json['documents'] as List? ?? [])
            .map((e) => SearchDocumentHit(
                id: (e as Map)['id'] as String,
                name: e['name'] as String? ?? '',
                category: e['category'] as String? ?? ''))
            .toList();

  final List<SearchProductHit> products;
  final List<SearchRfqHit> rfqs;
  final List<SearchOrderHit> orders;
  final List<SearchDocumentHit> documents;

  SearchResponse toEntity() => SearchResponse(
      products: products, rfqs: rfqs, orders: orders, documents: documents);
}
