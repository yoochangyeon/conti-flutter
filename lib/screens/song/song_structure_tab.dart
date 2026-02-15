import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/chord_transpose.dart';
import '../../models/song.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/section_flow_card.dart';

class SongStructureTab extends StatefulWidget {
  final List<SongSectionResponse> sections;
  final String? originalKey;
  final VoidCallback? onEdit;

  const SongStructureTab({
    super.key,
    required this.sections,
    this.originalKey,
    this.onEdit,
  });

  @override
  State<SongStructureTab> createState() => _SongStructureTabState();
}

class _SongStructureTabState extends State<SongStructureTab> {
  String? _selectedKey;
  int _semitones = 0;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.originalKey;
  }

  void _onKeyChanged(String? newKey) {
    if (newKey == null || widget.originalKey == null) return;
    setState(() {
      _selectedKey = newKey;
      _semitones = ChordTransposer.getSemitoneDistance(
        widget.originalKey!,
        newKey,
      );
    });
  }

  String? _transposeChords(String? chords) {
    if (chords == null || _semitones == 0) return chords;
    return ChordTransposer.transposeLine(chords, _semitones);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sections.isEmpty) {
      return ContiEmptyState(
        icon: Icons.queue_music_rounded,
        title: '곡 구조가 없습니다',
        subtitle: '섹션을 추가하여 곡의 구조를 정리해보세요',
        actionLabel: '구조 추가',
        onAction: widget.onEdit,
      );
    }

    final sorted = List<SongSectionResponse>.from(widget.sections)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final hasChords = sorted.any((s) => s.chords != null && s.chords!.isNotEmpty);

    return Column(
      children: [
        // Key selector + capo indicator
        if (hasChords && widget.originalKey != null)
          _TransposeBar(
            originalKey: widget.originalKey!,
            selectedKey: _selectedKey ?? widget.originalKey!,
            onKeyChanged: _onKeyChanged,
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final section = sorted[index];
              return SectionFlowCard(
                sectionType: section.sectionType,
                label: section.label,
                chords: _transposeChords(section.chords),
                buildUpLevel: section.buildUpLevel,
                memo: section.memo,
                isLast: index == sorted.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransposeBar extends StatelessWidget {
  final String originalKey;
  final String selectedKey;
  final ValueChanged<String?> onKeyChanged;

  const _TransposeBar({
    required this.originalKey,
    required this.selectedKey,
    required this.onKeyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capoInfo = ChordTransposer.suggestCapo(selectedKey);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded,
              size: 18, color: theme.colorScheme.primary),
          AppSpacing.hGapSm,
          Text('Key:', style: theme.textTheme.labelMedium),
          AppSpacing.hGapSm,
          DropdownButton<String>(
            value: selectedKey,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: ChordTransposer.commonKeys
                .map((key) => DropdownMenuItem(
                      value: key,
                      child: Text(
                        key == originalKey ? '$key (원키)' : key,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: key == selectedKey
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onKeyChanged,
          ),
          const Spacer(),
          if (capoInfo.capo > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                'Capo ${capoInfo.capo} (${capoInfo.openKey})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
