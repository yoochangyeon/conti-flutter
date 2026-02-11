import 'package:flutter/material.dart';
import '../core/constants/app_spacing.dart';
import 'build_up_indicator.dart';

class SectionFlowCard extends StatelessWidget {
  final String sectionType;
  final String? label;
  final String? chords;
  final int? buildUpLevel;
  final String? memo;
  final bool isLast;
  final Color? accentColor;

  const SectionFlowCard({
    super.key,
    required this.sectionType,
    this.label,
    this.chords,
    this.buildUpLevel,
    this.memo,
    this.isLast = false,
    this.accentColor,
  });

  static const Map<String, String> _sectionNames = {
    'INTRO': 'Intro',
    'VERSE': 'Verse',
    'PRE_CHORUS': 'Pre-Chorus',
    'CHORUS': 'Chorus',
    'BRIDGE': 'Bridge',
    'INTERLUDE': 'Interlude',
    'OUTRO': 'Outro',
    'TAG': 'Tag',
    'ENDING': 'Ending',
    'CUSTOM': 'Custom',
  };

  static const Map<String, IconData> _sectionIcons = {
    'INTRO': Icons.play_arrow_rounded,
    'VERSE': Icons.notes_rounded,
    'PRE_CHORUS': Icons.trending_up_rounded,
    'CHORUS': Icons.music_note_rounded,
    'BRIDGE': Icons.swap_horiz_rounded,
    'INTERLUDE': Icons.piano_rounded,
    'OUTRO': Icons.stop_rounded,
    'TAG': Icons.label_rounded,
    'ENDING': Icons.flag_rounded,
    'CUSTOM': Icons.edit_rounded,
  };

  Color _getTypeColor(BuildContext context) {
    if (accentColor != null) return accentColor!;
    switch (sectionType) {
      case 'INTRO':
      case 'OUTRO':
      case 'ENDING':
        return const Color(0xFF5B8DEF);
      case 'VERSE':
        return const Color(0xFF7C5CFC);
      case 'PRE_CHORUS':
        return const Color(0xFFE87C3E);
      case 'CHORUS':
        return const Color(0xFFFF6B9D);
      case 'BRIDGE':
        return const Color(0xFF4ECDC4);
      case 'INTERLUDE':
        return const Color(0xFFAD8CFF);
      case 'TAG':
        return const Color(0xFFFFC048);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: typeColor,
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: typeColor.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          // Card content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? typeColor.withValues(alpha: 0.08)
                    : typeColor.withValues(alpha: 0.06),
                borderRadius: AppRadius.borderLg,
                border: Border.all(
                  color: typeColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _sectionIcons[sectionType] ?? Icons.music_note_rounded,
                        size: 16,
                        color: typeColor,
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        _sectionNames[sectionType] ?? sectionType,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (label != null && label!.isNotEmpty) ...[
                        AppSpacing.hGapSm,
                        Text(
                          label!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (buildUpLevel != null)
                        BuildUpIndicator(level: buildUpLevel!),
                    ],
                  ),
                  if (chords != null && chords!.isNotEmpty) ...[
                    AppSpacing.gapSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        chords!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                  if (memo != null && memo!.isNotEmpty) ...[
                    AppSpacing.gapSm,
                    Text(
                      memo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
