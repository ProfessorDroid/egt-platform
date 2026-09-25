import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../dto/account_dto.dart';

/// Auth HTTP calls. Tokens are persisted by the repository, never here.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AuthTokensDto> login({required String phone, required String password}) async {
    final res = await _api.post(ApiEndpoints.authLogin, data: {
      'phone': phone,
      'password': password,
    });
    return AuthTokensDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthTokensDto> register({
    required String fullName,
    required String phone,
    required String password,
    String? company,
  }) async {
    final res = await _api.post(ApiEndpoints.authRegister, data: {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      if (company != null && company.isNotEmpty) 'company': company,
    });
    return AuthTokensDto.fromJson(res.data as Map<String, dynamic>);
  }

  /// Rotates the refresh token. Returns the new token pair.
  Future<AuthTokensDto> refresh(String refreshToken) async {
    final res = await _api.post(ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken});
    return AuthTokensDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout(String? refreshToken) async {
    await _api.post(ApiEndpoints.authLogout, data: {'refreshToken': refreshToken});
  }

  Future<void> logoutAll() async {
    await _api.post(ApiEndpoints.authLogoutAll);
  }

  Future<UserProfileDto> me() async {
    final res = await _api.get(ApiEndpoints.authMe);
    return UserProfileDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    await _api.post(ApiEndpoints.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
