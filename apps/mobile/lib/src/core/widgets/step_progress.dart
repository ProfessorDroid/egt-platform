import 'package:flutter/material.dart';

import '../theme/egt_colors.dart';
import '../theme/egt_dimens.dart';

/// Wizard progress indicator: "Step X of Y" + linear bar + step label.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.current,
    required this.total,
    required this.label,
    required this.stepText,
  });

  final int current; // 0-based
  final int total;
  final String label;
  final String stepText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(stepText,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: EgtColors.red, fontWeight: FontWeight.w600)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: EgtDimens.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (current + 1) / total,
            minHeight: 6,
            backgroundColor: EgtColors.border,
            valueColor: const AlwaysStoppedAnimation(EgtColors.red),
          ),
        ),
      ],
    );
  }
}
