/// Backend API endpoint paths (v1). These mirror the OpenAPI contract in
/// `packages/shared/openapi.yaml` (backend child owns that file — keep in sync).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authLogoutAll = '/auth/logout-all';
  static const String authMe = '/auth/me';

  // Catalogue
  static const String home = '/content/home';
  static const String products = '/catalog/products';
  static String product(String id) => '/catalog/products/$id';
  static const String categories = '/catalog/categories';

  // RFQ
  static const String rfqs = '/rfqs';
  static String rfq(String id) => '/rfqs/$id';
  static String rfqAttachments(String id) => '/rfqs/$id/attachments';

  // Quotations
  static const String quotations = '/quotations';
  static String quotation(String id) => '/quotations/$id';
  static String quotationAccept(String id) => '/quotations/$id/accept';
  static String quotationRequestRevision(String id) => '/quotations/$id/request-revision';
  static String quotationAsk(String id) => '/quotations/$id/ask';

  // Orders & shipments
  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderMilestones(String id) => '/orders/$id/milestones';
  static const String shipmentsTrack = '/shipments/track';
  static String shipment(String id) => '/shipments/$id';

  // Documents
  static const String documents = '/documents';
  static String documentSignedUrl(String id) => '/documents/$id/signed-url';

  // Private label
  static const String privateLabel = '/private-label';
  static String privateLabelRequest(String id) => '/private-label/$id';

  // Supplier portal
  static const String supplierApplications = '/supplier/applications';
  static const String supplierProducts = '/supplier/products';

  // Dropship hub (only if backend supports it)
  static const String dropshipSupport = '/dropship/support';
  static const String dropshipListings = '/dropship/listings';

  // Search / notifications / conversations
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String notificationPreferences = '/notifications/preferences';
  static const String notificationRegisterDevice = '/notifications/devices';
  static String conversation(String scope, String scopeId) => '/conversations/$scope/$scopeId';
  static String conversationMessages(String scope, String scopeId) =>
      '/conversations/$scope/$scopeId/messages';

  // Account
  static const String me = '/users/me';
  static const String myCompany = '/users/me/company';
  static const String myAddresses = '/users/me/addresses';
  static const String changePassword = '/users/me/password';
  static const String deleteAccountRequest = '/users/me/deletion-request';

  // Public
  static const String contactEnquiry = '/contact/enquiry';
}
