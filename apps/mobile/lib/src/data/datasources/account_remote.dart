import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../domain/entities/account.dart';
import '../dto/account_dto.dart';

class AccountRemoteDataSource {
  AccountRemoteDataSource(this._api);
  final ApiClient _api;

  static List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) {
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.map((e) => f(e as Map<String, dynamic>)).toList();
  }

  Future<UserProfileDto> me() async {
    final res = await _api.get(ApiEndpoints.me);
    return UserProfileDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserProfileDto> updateProfile({String? fullName, String? email}) async {
    final res = await _api.patch(ApiEndpoints.me, data: {
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
    });
    return UserProfileDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CompanyDto?> myCompany() async {
    final res = await _api.get(ApiEndpoints.myCompany);
    if (res.data == null) return null;
    return CompanyDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CompanyDto> saveCompany(Company company) async {
    final res = await _api.put(ApiEndpoints.myCompany, data: CompanyDto.toJson(company));
    return CompanyDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AddressDto>> myAddresses() async {
    final res = await _api.get(ApiEndpoints.myAddresses);
    return _list(res.data, AddressDto.fromJson);
  }

  Future<AddressDto> saveAddress(Address address) async {
    final res = await _api.post(ApiEndpoints.myAddresses, data: AddressDto.toJson(address));
    return AddressDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete('${ApiEndpoints.myAddresses}/$id');
  }

  Future<List<AppNotificationDto>> notifications() async {
    final res = await _api.get(ApiEndpoints.notifications);
    return _list(res.data, AppNotificationDto.fromJson);
  }

  Future<void> markAllRead() async {
    await _api.post('${ApiEndpoints.notifications}/read-all');
  }

  Future<NotificationPreferences> preferences() async {
    final res = await _api.get(ApiEndpoints.notificationPreferences);
    return NotificationPreferences.fromJson(res.data as Map<String, dynamic>);
  }

  Future<NotificationPreferences> savePreferences(NotificationPreferences prefs) async {
    final res = await _api.put(ApiEndpoints.notificationPreferences, data: prefs.toJson());
    return NotificationPreferences.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> registerDevice({required String pushToken, required String platform}) async {
    await _api.post(ApiEndpoints.notificationRegisterDevice, data: {
      'pushToken': pushToken,
      'platform': platform,
    });
  }

  Future<List<ConversationSummaryDto>> conversations() async {
    final res = await _api.get('/conversations');
    return _list(res.data, ConversationSummaryDto.fromJson);
  }

  Future<List<ChatMessageDto>> messages({required String scope, required String scopeId}) async {
    final res = await _api.get(ApiEndpoints.conversationMessages(scope, scopeId));
    return _list(res.data, ChatMessageDto.fromJson);
  }

  Future<ChatMessageDto> sendMessage({
    required String scope,
    required String scopeId,
    required String body,
  }) async {
    final res = await _api.post(ApiEndpoints.conversationMessages(scope, scopeId),
        data: {'body': body});
    return ChatMessageDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markConversationRead({required String scope, required String scopeId}) async {
    await _api.post('${ApiEndpoints.conversation(scope, scopeId)}/read');
  }

  Future<List<DocumentItemDto>> documents({String? category}) async {
    final res = await _api.get(ApiEndpoints.documents,
        query: {if (category != null) 'category': category});
    return _list(res.data, DocumentItemDto.fromJson);
  }

  Future<List<String>> documentCategories() async {
    final res = await _api.get('${ApiEndpoints.documents}/categories');
    final data = res.data;
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list.cast<String>();
  }

  Future<Uri> signedDownloadUrl(String documentId) async {
    final res = await _api.get(ApiEndpoints.documentSignedUrl(documentId));
    final url = (res.data as Map)['url'] as String;
    return Uri.parse(url);
  }

  Future<void> requestDataExport() async {
    await _api.post('/users/me/data-export');
  }

  Future<void> requestAccountDeletion() async {
    await _api.post(ApiEndpoints.deleteAccountRequest);
  }

  Future<void> sendContactEnquiry({
    required String name,
    required String phone,
    required String message,
    String? productInterest,
  }) async {
    await _api.post(ApiEndpoints.contactEnquiry, data: {
      'name': name,
      'phone': phone,
      'message': message,
      if (productInterest != null) 'productInterest': productInterest,
    });
  }
}
