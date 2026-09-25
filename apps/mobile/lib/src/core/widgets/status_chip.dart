import 'package:flutter/material.dart';

import '../theme/egt_colors.dart';

/// Small status pill (RFQ/quotation/order/shipment/supplier states).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? EgtColors.harbor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  factory StatusChip.positive(String label) =>
      StatusChip(label: label, color: EgtColors.success);
  factory StatusChip.neutral(String label) =>
      StatusChip(label: label, color: EgtColors.steel);
  factory StatusChip.warning(String label) =>
      StatusChip(label: label, color: EgtColors.warning);
  factory StatusChip.negative(String label) =>
      StatusChip(label: label, color: EgtColors.error);
  factory StatusChip.brand(String label) =>
      StatusChip(label: label, color: EgtColors.red);
}
