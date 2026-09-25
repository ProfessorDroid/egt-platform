import 'package:flutter/material.dart';

import '../theme/egt_colors.dart';
import '../theme/egt_dimens.dart';

/// Hand-rolled skeleton loaders (no extra dependency).
/// Respects reduced motion via [MediaQuery.disableAnimations].
class EgtSkeleton extends StatefulWidget {
  const EgtSkeleton({super.key, this.width, this.height = 16, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  State<EgtSkeleton> createState() => _EgtSkeletonState();
}

class _EgtSkeletonState extends State<EgtSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _box(0.5);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => _box(0.35 + 0.25 * _controller.value),
    );
  }

  Widget _box(double opacity) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: EgtColors.manifest.withOpacity(opacity + 0.4),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
}

/// Skeleton for a vertical list of cards.
class EgtSkeletonList extends StatelessWidget {
  const EgtSkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(EgtDimens.s16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: EgtDimens.s12),
      itemBuilder: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              EgtSkeleton(width: 180, height: 18),
              SizedBox(height: 8),
              EgtSkeleton(width: double.infinity, height: 12),
              SizedBox(height: 6),
              EgtSkeleton(width: 220, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a product grid.
class EgtSkeletonGrid extends StatelessWidget {
  const EgtSkeletonGrid({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(EgtDimens.s16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EgtSkeleton(height: 110, radius: 0),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EgtSkeleton(width: 120, height: 14),
                  SizedBox(height: 8),
                  EgtSkeleton(width: 90, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
