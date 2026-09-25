import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/egt_colors.dart';

/// Section header: title left, optional "View all" action right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(context.l10n.actionViewAll,
                  style: const TextStyle(
                      color: EgtColors.red, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
