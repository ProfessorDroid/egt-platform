import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/account_remote.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/repositories.dart';
import 'core_providers.dart';

final _accountRepoProvider = Provider<AccountRepositoryImpl>((ref) {
  return AccountRepositoryImpl(AccountRemoteDataSource(ref.watch(apiClientProvider)));
});

final userRepositoryProvider =
    Provider<UserRepository>((ref) => ref.watch(_accountRepoProvider));
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => ref.watch(_accountRepoProvider));
final conversationRepositoryProvider =
    Provider<ConversationRepository>((ref) => ref.watch(_accountRepoProvider));
final documentRepositoryProvider =
    Provider<DocumentRepository>((ref) => ref.watch(_accountRepoProvider));

final profileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(userRepositoryProvider).me();
});

final companyProvider = FutureProvider<Company?>((ref) {
  return ref.watch(userRepositoryProvider).myCompany();
});

final addressesProvider = FutureProvider<List<Address>>((ref) {
  return ref.watch(userRepositoryProvider).myAddresses();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).notifications();
});

final notificationPrefsProvider = FutureProvider<NotificationPreferences>((ref) {
  return ref.watch(notificationRepositoryProvider).preferences();
});

final conversationsProvider = FutureProvider<List<ConversationSummary>>((ref) {
  return ref.watch(conversationRepositoryProvider).myConversations();
});

final conversationMessagesProvider =
    FutureProvider.family<List<ChatMessage>, ({String scope, String scopeId})>((ref, key) {
  return ref.watch(conversationRepositoryProvider).messages(
        scope: key.scope,
        scopeId: key.scopeId,
      );
});

final documentsProvider =
    FutureProvider.family<List<DocumentItem>, String?>((ref, category) {
  return ref.watch(documentRepositoryProvider).myDocuments(category: category);
});

final documentCategoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(documentRepositoryProvider).categories();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => !n.read).length,
        orElse: () => 0,
      );
});

final totalUnreadConversationsProvider = Provider<int>((ref) {
  return ref.watch(conversationsProvider).maybeWhen(
        data: (list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount),
        orElse: () => 0,
      );
});
