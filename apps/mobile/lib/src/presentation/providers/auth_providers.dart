import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session_manager.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../data/datasources/auth_remote.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/repositories.dart';
import 'core_providers.dart';

final authRemoteProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepositoryImpl(
    ref.watch(authRemoteProvider),
    ref.watch(secureTokenStorageProvider),
    ref.watch(sessionManagerProvider),
  );
  // Breaks the ApiClient -> SessionManager -> AuthRepository cycle.
  ref.watch(sessionManagerProvider).onRefreshNeeded = repo.refreshTokens;
  return repo;
});

/// Auth state: null = signed out, AsyncValue<UserProfile?> otherwise.
/// `isLoggedInProvider` drives the router's auth guard.
class AuthStateNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthStateNotifier(this._repo) : super(const AsyncValue.loading());

  final AuthRepository _repo;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.restoreSession();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login({required String phone, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(phone: phone, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    String? company,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.register(
          fullName: fullName, phone: phone, password: password, company: company);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> logoutAllDevices() async {
    await _repo.logoutAllDevices();
    state = const AsyncValue.data(null);
  }

  void signedOut() => state = const AsyncValue.data(null);
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserProfile?>>((ref) {
  final notifier = AuthStateNotifier(ref.watch(authRepositoryProvider));
  // Session death (refresh failed) -> sign out everywhere.
  ref.watch(sessionManagerProvider).authStateChanges.listen((alive) {
    if (!alive) notifier.signedOut();
  });
  ref.watch(secureTokenStorageProvider); // keep provider alive
  return notifier;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
});
