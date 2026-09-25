import 'package:flutter/material.dart';

import '../../domain/entities/trade.dart';
import '../theme/egt_colors.dart';
import '../theme/egt_dimens.dart';
import '../utils/formatters.dart';

/// Vertical 13-milestone order journey timeline (backend-driven labels/dates).
class MilestoneTimeline extends StatelessWidget {
  const MilestoneTimeline({super.key, required this.milestones});

  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context) {
    // Order by the contract key order; unknown keys go last.
    final order = {
      for (var i = 0; i < MilestoneKeys.ordered.length; i++)
        MilestoneKeys.ordered[i]: i
    };
    final sorted = [...milestones]
      ..sort((a, b) =>
          (order[a.key] ?? 999).compareTo(order[b.key] ?? 999));

    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++)
          _MilestoneRow(
            milestone: sorted[i],
            isLast: i == sorted.length - 1,
          ),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.isLast});

  final Milestone milestone;
  final bool isLast;

  Color get _color {
    switch (milestone.status) {
      case MilestoneStatus.done:
        return EgtColors.success;
      case MilestoneStatus.current:
        return EgtColors.red;
      case MilestoneStatus.upcoming:
        return EgtColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = milestone.status == MilestoneStatus.done;
    final current = milestone.status == MilestoneStatus.current;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || current ? _color : EgtColors.paper,
                  border: Border.all(color: _color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                    child: Container(width: 2, color: _color.withOpacity(0.4))),
            ],
          ),
          const SizedBox(width: EgtDimens.s12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: EgtDimens.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(milestone.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight:
                              current ? FontWeight.w700 : FontWeight.w600)),
                  if (milestone.at != null)
                    Text(formatDateTime(milestone.at),
                        style: Theme.of(context).textTheme.bodySmall),
                  if (milestone.note != null && milestone.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(milestone.note!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
