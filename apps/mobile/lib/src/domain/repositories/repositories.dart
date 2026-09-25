import '../entities/account.dart';
import '../entities/catalog.dart';
import '../entities/growth.dart';
import '../entities/trade.dart';

/// Repository contracts. Implementations live in `data/repositories/`.
/// All methods throw [AppException] (core/network/api_exception.dart) on failure.

abstract class AuthRepository {
  Future<UserProfile> login({required String phone, required String password});
  Future<UserProfile> register({required String fullName, required String phone, required String password, String? company});
  Future<UserProfile?> restoreSession();
  Future<void> logout();
  Future<void> logoutAllDevices();
  Future<String?> refreshTokens();
  Future<void> changePassword({required String currentPassword, required String newPassword});
}

abstract class CatalogRepository {
  Future<HomeContent> getHomeContent();
  Future<List<Product>> getProducts({String? query, String? categoryId, String? sort, bool? privateLabelOnly});
  Future<List<Category>> getCategories();
  Future<Product> getProduct(String id);
}

abstract class RfqRepository {
  /// Submits the wizard draft. Only resolves AFTER backend confirmation —
  /// the UI must never report success earlier.
  Future<Rfq> submit(RfqDraft draft);
  Future<List<Rfq>> myRfqs();
  Future<Rfq> getRfq(String id);
}

abstract class QuotationRepository {
  Future<List<Quotation>> myQuotations();
  Future<Quotation> getQuotation(String id);
  Future<Quotation> accept(String id);
  Future<Quotation> requestRevision(String id, String note);
  Future<void> askEgt(String id, String message);
}

abstract class OrderRepository {
  Future<List<Order>> myOrders();
  Future<Order> getOrder(String id);
  Future<List<Milestone>> getMilestones(String orderId);
}

abstract class ShipmentRepository {
  /// Tracks by order, shipment, or carrier tracking ID. Backend returns only
  /// EGT-verified updates — the UI labels every row "Last verified update".
  Future<Shipment> track(String id);
  Future<Shipment> getShipment(String id);
}

abstract class DocumentRepository {
  Future<List<DocumentItem>> myDocuments({String? category});
  Future<List<String>> categories();

  /// Returns a backend-issued signed URL (never a raw storage path).
  Future<Uri> signedDownloadUrl(String documentId);
}

abstract class PrivateLabelRepository {
  Future<PrivateLabelRequest> submit(PrivateLabelDraft draft);
  Future<List<PrivateLabelRequest>> myRequests();
  Future<PrivateLabelRequest> getRequest(String id);
}

abstract class SupplierRepository {
  Future<SupplierApplication> apply({
    required String companyName,
    required String contactPerson,
    required String phone,
    required String productDetails,
    String? certifications,
  });
  Future<List<SupplierApplication>> myApplications();
}

abstract class DropshipRepository {
  /// False when the backend has dropshipping disabled for this account/region.
  Future<bool> isSupported();
  Future<List<DropshipListing>> listings();
}

abstract class SearchRepository {
  Future<SearchResponse> search(String query);
}

abstract class ConversationRepository {
  Future<List<ConversationSummary>> myConversations();
  Future<List<ChatMessage>> messages({required String scope, required String scopeId});
  Future<ChatMessage> send({required String scope, required String scopeId, required String body});
  Future<void> markRead({required String scope, required String scopeId});
}

abstract class NotificationRepository {
  Future<List<AppNotification>> notifications();
  Future<NotificationPreferences> preferences();
  Future<NotificationPreferences> savePreferences(NotificationPreferences prefs);
  Future<void> markAllRead();
  Future<void> registerDevice({required String pushToken, required String platform});
}

abstract class UserRepository {
  Future<UserProfile> me();
  Future<UserProfile> updateProfile({String? fullName, String? email});
  Future<Company?> myCompany();
  Future<Company> saveCompany(Company company);
  Future<List<Address>> myAddresses();
  Future<Address> saveAddress(Address address);
  Future<void> deleteAddress(String id);
  Future<void> requestDataExport();
  Future<void> requestAccountDeletion();
  Future<void> sendContactEnquiry({required String name, required String phone, required String message, String? productInterest});
}

abstract class SavedRepository {
  Future<List<Product>> savedProducts();
  Future<void> saveProduct(String productId);
  Future<void> unsaveProduct(String productId);
  Future<bool> isSaved(String productId);
}
