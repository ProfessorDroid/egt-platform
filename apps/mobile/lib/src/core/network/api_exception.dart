/// Friendly, localizable app failure. UI must NEVER show raw server text —
/// map everything through [messageKey] (l10n) and optional [fieldErrors].
enum AppFailureKind {
  offline,
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  server,
  unknown,
}

class AppException implements Exception {
  const AppException(
    this.kind,
    this.messageKey, {
    this.fieldErrors,
    this.statusCode,
    this.debugDetail,
  });

  final AppFailureKind kind;
  final String messageKey;
  final Map<String, String>? fieldErrors;
  final int? statusCode;

  /// Raw detail for logs only — never render in UI.
  final String? debugDetail;

  @override
  String toString() => 'AppException($kind, $messageKey, status=$statusCode)';
}
