import 'package:flutter/material.dart';
import '../core/constants/app_spacing.dart';

class BuildUpIndicator extends StatelessWidget {
  final int level;
  final int maxLevel;
  final double size;

  const BuildUpIndicator({
    super.key,
    required this.level,
    this.maxLevel = 5,
    this.size = 12,
  });

  Color _colorForLevel(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF5B8DEF); // Cool blue
      case 2:
        return const Color(0xFF7C5CFC); // Violet
      case 3:
        return const Color(0xFFE87C3E); // Orange
      case 4:
        return const Color(0xFFFF6B9D); // Warm pink
      case 5:
        return const Color(0xFFFF4757); // Hot red
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _colorForLevel(level);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLevel, (index) {
        final isActive = index < level;
        return Container(
          width: size,
          height: size * 0.4,
          margin: EdgeInsets.only(right: index < maxLevel - 1 ? 3 : 0),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderFull,
            color: isActive
                ? activeColor
                : activeColor.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }
}
