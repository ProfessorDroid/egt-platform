import '../../core/auth/session_manager.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/auth_remote.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage, this._session);

  final AuthRemoteDataSource _remote;
  final SecureTokenStorage _storage;
  final SessionManager _session;

  @override
  Future<UserProfile> login({required String phone, required String password}) async {
    final tokens = await _remote.login(phone: phone, password: password);
    await _storage.saveTokens(
        accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    return tokens.user.toEntity();
  }

  @override
  Future<UserProfile> register({
    required String fullName,
    required String phone,
    required String password,
    String? company,
  }) async {
    final tokens = await _remote.register(
        fullName: fullName, phone: phone, password: password, company: company);
    await _storage.saveTokens(
        accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    return tokens.user.toEntity();
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final hasRefresh = await _storage.readRefreshToken();
    if (hasRefresh == null) return null;
    // Ensure the access token is fresh, then fetch the profile.
    await _session.getValidAccessToken();
    try {
      return (await _remote.me()).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await _storage.readRefreshToken();
    try {
      await _remote.logout(refresh);
    } finally {
      await _session.signOutLocal();
    }
  }

  @override
  Future<void> logoutAllDevices() async {
    try {
      await _remote.logoutAll();
    } finally {
      await _session.signOutLocal();
    }
  }

  /// Called by [SessionManager] (single-flight). Rotates and persists tokens.
  @override
  Future<String?> refreshTokens() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh == null) return null;
    final tokens = await _remote.refresh(refresh);
    await _storage.saveTokens(
        accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    return tokens.accessToken;
  }

  @override
  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    await _remote.changePassword(
        currentPassword: currentPassword, newPassword: newPassword);
  }
}
