import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../auth/session_manager.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

/// Maps [DioException]/socket errors to friendly [AppException]s.
/// Never surfaces raw server text to the UI.
class ErrorMapper {
  static AppException map(Object error) {
    if (error is AppException) return error;
    if (error is SocketException) {
      return const AppException(AppFailureKind.offline, 'error_offline');
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const AppException(AppFailureKind.timeout, 'error_timeout');
        case DioExceptionType.connectionError:
          return const AppException(AppFailureKind.offline, 'error_offline');
        case DioExceptionType.badResponse:
          return _mapStatus(status, error);
        case DioExceptionType.cancel:
          return const AppException(AppFailureKind.unknown, 'error_cancelled');
        case DioExceptionType.badCertificate:
          return const AppException(AppFailureKind.network, 'error_network');
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return const AppException(AppFailureKind.offline, 'error_offline');
          }
          return AppException(AppFailureKind.network, 'error_network',
              debugDetail: error.message);
      }
    }
    return AppException(AppFailureKind.unknown, 'error_generic',
        debugDetail: error.toString());
  }

  static AppException _mapStatus(int? status, DioException error) {
    final data = error.response?.data;
    final fieldErrors = _extractFieldErrors(data);
    switch (status) {
      case 400:
        return AppException(AppFailureKind.validation, 'error_validation',
            fieldErrors: fieldErrors, statusCode: status);
      case 401:
        return AppException(AppFailureKind.unauthorized, 'error_unauthorized',
            statusCode: status);
      case 403:
        return AppException(AppFailureKind.forbidden, 'error_forbidden',
            statusCode: status);
      case 404:
        return AppException(AppFailureKind.notFound, 'error_not_found',
            statusCode: status);
      case 409:
        return AppException(AppFailureKind.conflict, 'error_conflict',
            statusCode: status);
      case 422:
        return AppException(AppFailureKind.validation, 'error_validation',
            fieldErrors: fieldErrors, statusCode: status);
      default:
        if (status != null && status >= 500) {
          return AppException(AppFailureKind.server, 'error_server',
              statusCode: status);
        }
        return AppException(AppFailureKind.unknown, 'error_generic',
            statusCode: status, debugDetail: error.message);
    }
  }

  static Map<String, String>? _extractFieldErrors(dynamic data) {
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        return errors.map((k, v) => MapEntry(k, v.toString()));
      }
    }
    return null;
  }
}

/// Attaches the access token to every request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session);
  final SessionManager _session;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_session.shouldSkipAuth(options.path)) {
      return handler.next(options);
    }
    try {
      final token = await _session.getValidAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Token unavailable — proceed unauthenticated; backend returns 401
      // and the UI maps it to a friendly sign-in prompt.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final req = err.requestOptions;
    if (status == 401 && !req.extra['retriedAfter401'] && !_session.shouldSkipAuth(req.path)) {
      req.extra['retriedAfter401'] = true;
      try {
        final token = await _session.refresh();
        if (token != null) {
          req.headers['Authorization'] = 'Bearer $token';
          final dio = Dio(BaseOptions(baseUrl: req.baseUrl));
          final retry = await dio.fetch(req);
          return handler.resolve(retry);
        }
      } catch (_) {
        // Refresh failed — sign out handled by SessionManager listeners.
      }
    }
    handler.next(err);
  }
}

/// Retries idempotent requests with exponential backoff + jitter.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxRetries = 3});
  final int maxRetries;
  final _random = Random();

  static const _idempotent = {'GET', 'HEAD', 'OPTIONS'};

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final attempt = (req.extra['retryAttempt'] as int?) ?? 0;
    final retryable = _isRetryable(err) && attempt < maxRetries;
    if (!retryable) return handler.next(err);

    final delay = Duration(milliseconds: 400 * (1 << attempt) + _random.nextInt(250));
    await Future.delayed(delay);
    req.extra['retryAttempt'] = attempt + 1;
    try {
      final dio = Dio(BaseOptions(baseUrl: req.baseUrl));
      final retry = await dio.fetch(req);
      return handler.resolve(retry);
    } catch (e) {
      return handler.next(e is DioException ? e : err);
    }
  }

  bool _isRetryable(DioException err) {
    if (!_idempotent.contains(err.requestOptions.method.toUpperCase())) return false;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      return true;
    }
    final status = err.response?.statusCode;
    return status != null && status >= 500;
  }
}

/// Central HTTP client: auth, single-flight 401 refresh, retry w/ backoff,
/// friendly error mapping. Repositories talk to the backend through this only.
class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;

  factory ApiClient.create({
    required AppConfig config,
    required SessionManager session,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      AuthInterceptor(session),
      RetryInterceptor(),
      if (config.isDev)
        LogInterceptor(requestBody: true, responseBody: false, logPrint: print),
    ]);
    return ApiClient._(dio);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _guard(_dio.get<T>(path, queryParameters: query));

  Future<Response<T>> post<T>(String path, {Object? data, Map<String, dynamic>? query}) =>
      _guard(_dio.post<T>(path, data: data, queryParameters: query));

  Future<Response<T>> put<T>(String path, {Object? data}) => _guard(_dio.put<T>(path, data: data));

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _guard(_dio.patch<T>(path, data: data));

  Future<Response<T>> delete<T>(String path) => _guard(_dio.delete<T>(path));

  Future<Response<T>> _guard<T>(Future<Response<T>> call) async {
    try {
      return await call;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
