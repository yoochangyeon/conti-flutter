import 'package:flutter/material.dart';
import '../core/constants/app_shadows.dart';
import '../core/constants/app_theme.dart';
import 'animated/conti_scale_tap.dart';

class ContiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final LinearGradient? borderGradient;
  final double borderRadius;
  final double blur; // kept for API compat, no longer used

  const ContiCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderGradient,
    this.borderRadius = 16,
    this.blur = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isDark
            ? Border.all(color: AppColors.darkDivider, width: 0.5)
            : null,
        boxShadow: AppShadow.card(isDark),
      ),
      child: child,
    );

    if (borderGradient != null) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: borderGradient,
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(borderRadius - 1.5),
          ),
          child: child,
        ),
      );
    }

    if (onTap != null) {
      card = ContiScaleTap(onTap: onTap, child: card);
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
