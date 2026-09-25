import 'dart:async';

import 'package:jwt_decode/jwt_decode.dart';

import '../storage/secure_token_storage.dart';

/// Owns the auth session: access-token supply + single-flight refresh rotation.
///
/// Wiring (see `auth_providers.dart`): the [AuthRepository] sets
/// [onRefreshNeeded] after construction, which breaks the
/// ApiClient -> SessionManager -> AuthRepository dependency cycle.
class SessionManager {
  SessionManager(this._storage);

  final SecureTokenStorage _storage;

  /// Assigned by the auth provider wiring. Must call the backend
  /// `/auth/refresh` endpoint and persist the rotated tokens.
  Future<String?> Function()? onRefreshNeeded;

  Future<String?>? _inflightRefresh;
  final _authStateController = StreamController<bool>.broadcast();

  /// Emits false when the session died (refresh failed) so UI can sign out.
  Stream<bool> get authStateChanges => _authStateController.stream;

  /// Paths that never need (or want) an Authorization header.
  bool shouldSkipAuth(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh');

  /// Returns a non-expired access token, refreshing first if needed.
  Future<String?> getValidAccessToken() async {
    final token = await _storage.readAccessToken();
    if (token == null) return null;
    if (!_isExpired(token)) return token;
    return refresh();
  }

  /// Single-flight refresh: concurrent 401s share one refresh call.
  Future<String?> refresh() {
    final inflight = _inflightRefresh;
    if (inflight != null) return inflight;
    final future = _doRefresh();
    _inflightRefresh = future;
    return future.whenComplete(() => _inflightRefresh = null);
  }

  Future<String?> _doRefresh() async {
    final refresher = onRefreshNeeded;
    if (refresher == null) return null;
    try {
      final token = await refresher();
      if (token == null) _authStateController.add(false);
      return token;
    } catch (_) {
      _authStateController.add(false);
      return null;
    }
  }

  Future<void> signOutLocal() async {
    await _storage.clearTokens();
    _authStateController.add(false);
  }

  bool _isExpired(String token) {
    try {
      return Jwt.isExpired(token);
    } catch (_) {
      return true; // Unparseable token -> treat as expired, force refresh.
    }
  }

  void dispose() => _authStateController.close();
}
