import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_theme.dart';

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
      baseColor: isDark ? AppColors.darkSurfaceHigh : AppColors.gray100,
      highlightColor: isDark ? AppColors.darkSurface : AppColors.gray50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ContiCardSkeleton extends StatelessWidget {
  final double height;

  const ContiCardSkeleton({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: ContiSkeleton(height: height, borderRadius: AppRadius.lg),
    );
  }
}

class ContiListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ContiListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
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
