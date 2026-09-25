import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/egt_colors.dart';

/// Confirmation dialog for consequential actions
/// (accept quotation, logout all devices, delete account request…).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: destructive
              ? ElevatedButton.styleFrom(backgroundColor: EgtColors.error)
              : null,
          child: Text(confirmLabel ?? l10n.actionConfirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
