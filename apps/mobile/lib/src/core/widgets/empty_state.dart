import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/egt_colors.dart';
import '../theme/egt_dimens.dart';
import 'egt_button.dart';

/// Friendly empty state — never a blank screen.
class EgtEmptyState extends StatelessWidget {
  const EgtEmptyState({
    super.key,
    this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String? body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  color: EgtColors.manifest, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: EgtColors.steel),
            ),
            const SizedBox(height: EgtDimens.s16),
            Text(title ?? l10n.emptyTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: EgtDimens.s8),
            Text(body ?? l10n.emptyBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: EgtDimens.s16),
              EgtOutlineButton(label: actionLabel!, onPressed: onAction, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}
