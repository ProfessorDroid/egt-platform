import 'dart:io';

import 'package:dio/dio.dart';
import 'package:egt_mobile/src/core/network/api_client.dart';
import 'package:egt_mobile/src/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  dynamic data,
}) =>
    DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: type,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: status,
              data: data,
            ),
    );

void main() {
  group('AppException.map', () {
    test('passes AppException through unchanged', () {
      const e = AppException(AppFailureKind.offline, 'error_offline');
      expect(ErrorMapper.map(e), same(e));
    });

    test('socket errors map to offline', () {
      final e = ErrorMapper.map(const SocketException('no route'));
      expect(e.kind, AppFailureKind.offline);
      expect(e.messageKey, 'error_offline');
    });

    test('timeouts map to timeout', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = ErrorMapper.map(_dio(type: t));
        expect(e.kind, AppFailureKind.timeout);
        expect(e.messageKey, 'error_timeout');
      }
    });

    test('401/403/404 map to friendly auth kinds', () {
      expect(ErrorMapper.map(_dio(status: 401)).kind,
          AppFailureKind.unauthorized);
      expect(ErrorMapper.map(_dio(status: 403)).kind,
          AppFailureKind.forbidden);
      expect(ErrorMapper.map(_dio(status: 404)).kind,
          AppFailureKind.notFound);
    });

    test('400/422 map to validation with field errors', () {
      final e = ErrorMapper.map(_dio(
          status: 422,
          data: {
            'errors': {'quantity': 'Must be positive'}
          }));
      expect(e.kind, AppFailureKind.validation);
      expect(e.messageKey, 'error_validation');
      expect(e.statusCode, 422);
    });

    test('5xx maps to server', () {
      final e = ErrorMapper.map(_dio(status: 503));
      expect(e.kind, AppFailureKind.server);
      expect(e.messageKey, 'error_server');
    });

    test('unknown errors map to generic without raw server text', () {
      final e = ErrorMapper.map(StateError('weird'));
      expect(e.kind, AppFailureKind.unknown);
      expect(e.messageKey, 'error_generic');
      expect(e.toString(), isNot(contains('weird')));
    });
  });
}
