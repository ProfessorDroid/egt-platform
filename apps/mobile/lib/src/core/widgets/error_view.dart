import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../network/api_exception.dart';
import '../theme/egt_colors.dart';
import '../theme/egt_dimens.dart';
import 'egt_button.dart';
import 'skeleton.dart';

/// Maps [AppException] to a friendly localized message + retry.
/// Never renders raw server text.
class EgtErrorView extends StatelessWidget {
  const EgtErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  String _message(BuildContext context) {
    final l10n = context.l10n;
    if (error is AppException) {
      final e = error as AppException;
      switch (e.kind) {
        case AppFailureKind.offline:
          return l10n.errorOffline;
        case AppFailureKind.network:
          return l10n.errorNetwork;
        case AppFailureKind.timeout:
          return l10n.errorTimeout;
        case AppFailureKind.unauthorized:
          return l10n.errorUnauthorized;
        case AppFailureKind.forbidden:
          return l10n.errorForbidden;
        case AppFailureKind.notFound:
          return l10n.errorNotFound;
        case AppFailureKind.validation:
          return l10n.errorValidation;
        case AppFailureKind.conflict:
          return l10n.errorConflict;
        case AppFailureKind.server:
          return l10n.errorServer;
        case AppFailureKind.unknown:
          return l10n.errorGeneric;
      }
    }
    return l10n.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: EgtColors.steel),
            const SizedBox(height: EgtDimens.s12),
            Text(_message(context),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: EgtDimens.s16),
              EgtOutlineButton(
                  label: context.l10n.actionRetry, onPressed: onRetry, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps an AsyncValue with skeleton / error / empty handling.
class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.builder,
    this.empty,
    this.onRetry,
    this.skeleton,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? empty;
  final VoidCallback? onRetry;
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) {
        if (data is List && data.isEmpty && empty != null) return empty!;
        return builder(data);
      },
      loading: () => skeleton ?? const EgtSkeletonList(),
      error: (e, _) => EgtErrorView(error: e, onRetry: onRetry),
    );
  }
}
