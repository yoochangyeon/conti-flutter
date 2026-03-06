import 'package:flutter/material.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_theme.dart';

class ContiSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const ContiSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
              letterSpacing: -0.1,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
