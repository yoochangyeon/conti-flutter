import 'package:flutter/material.dart';

/// Semantic text style shortcuts wrapping TextTheme levels.
extension AppTextStyle on TextTheme {
  /// Section headers (e.g., "악보 파일", "사용 이력")
  TextStyle get sectionTitle => titleMedium!;

  /// Card primary text (e.g., song title in list)
  TextStyle get cardTitle => titleSmall!;

  /// Card secondary text (e.g., artist, subtitle)
  TextStyle get cardSubtitle => bodySmall!;

  /// Badge/chip text
  TextStyle get badge => labelSmall!.copyWith(fontWeight: FontWeight.w600);

  /// Small caption text
  TextStyle get caption => labelSmall!;
}
