import '../../domain/entities/account.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/account_remote.dart';

class AccountRepositoryImpl
    implements
        UserRepository,
        NotificationRepository,
        ConversationRepository,
        DocumentRepository {
  AccountRepositoryImpl(this._remote);
  final AccountRemoteDataSource _remote;

  // --- UserRepository ---
  @override
  Future<UserProfile> me() => _remote.me().then((dto) => dto.toEntity());

  @override
  Future<UserProfile> updateProfile({String? fullName, String? email}) =>
      _remote.updateProfile(fullName: fullName, email: email).then((d) => d.toEntity());

  @override
  Future<Company?> myCompany() =>
      _remote.myCompany().then((dto) => dto?.toEntity());

  @override
  Future<Company> saveCompany(Company company) =>
      _remote.saveCompany(company).then((dto) => dto.toEntity());

  @override
  Future<List<Address>> myAddresses() =>
      _remote.myAddresses().then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<Address> saveAddress(Address address) =>
      _remote.saveAddress(address).then((dto) => dto.toEntity());

  @override
  Future<void> deleteAddress(String id) => _remote.deleteAddress(id);

  @override
  Future<void> requestDataExport() => _remote.requestDataExport();

  @override
  Future<void> requestAccountDeletion() => _remote.requestAccountDeletion();

  @override
  Future<void> sendContactEnquiry({
    required String name,
    required String phone,
    required String message,
    String? productInterest,
  }) =>
      _remote.sendContactEnquiry(
          name: name, phone: phone, message: message, productInterest: productInterest);

  // --- NotificationRepository ---
  @override
  Future<List<AppNotification>> notifications() => _remote
      .notifications()
      .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<NotificationPreferences> preferences() => _remote.preferences();

  @override
  Future<NotificationPreferences> savePreferences(NotificationPreferences prefs) =>
      _remote.savePreferences(prefs);

  @override
  Future<void> markAllRead() => _remote.markAllRead();

  @override
  Future<void> registerDevice({required String pushToken, required String platform}) =>
      _remote.registerDevice(pushToken: pushToken, platform: platform);

  // --- ConversationRepository ---
  @override
  Future<List<ConversationSummary>> myConversations() => _remote
      .conversations()
      .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<List<ChatMessage>> messages({required String scope, required String scopeId}) =>
      _remote
          .messages(scope: scope, scopeId: scopeId)
          .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<ChatMessage> send(
          {required String scope, required String scopeId, required String body}) =>
      _remote
          .sendMessage(scope: scope, scopeId: scopeId, body: body)
          .then((dto) => dto.toEntity());

  @override
  Future<void> markRead({required String scope, required String scopeId}) =>
      _remote.markConversationRead(scope: scope, scopeId: scopeId);

  // --- DocumentRepository ---
  @override
  Future<List<DocumentItem>> myDocuments({String? category}) => _remote
      .documents(category: category)
      .then((list) => list.map((e) => e.toEntity()).toList());

  @override
  Future<List<String>> categories() => _remote.documentCategories();

  @override
  Future<Uri> signedDownloadUrl(String documentId) =>
      _remote.signedDownloadUrl(documentId);
}
