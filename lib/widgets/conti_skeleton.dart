import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ContiSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ContiSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade300,
      highlightColor: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ContiCardSkeleton extends StatelessWidget {
  final double height;

  const ContiCardSkeleton({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ContiSkeleton(height: height, borderRadius: 20),
    );
  }
}

class ContiListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ContiListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => ContiCardSkeleton(height: itemHeight),
      ),
    );
  }
}
