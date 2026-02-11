import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/song.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/section_flow_card.dart';

class SongStructureTab extends StatelessWidget {
  final List<SongSectionResponse> sections;
  final VoidCallback? onEdit;

  const SongStructureTab({
    super.key,
    required this.sections,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return ContiEmptyState(
        icon: Icons.queue_music_rounded,
        title: '곡 구조가 없습니다',
        subtitle: '섹션을 추가하여 곡의 구조를 정리해보세요',
        actionLabel: '구조 추가',
        onAction: onEdit,
      );
    }

    final sorted = List<SongSectionResponse>.from(sections)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return ListView.builder(
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
          chords: section.chords,
          buildUpLevel: section.buildUpLevel,
          memo: section.memo,
          isLast: index == sorted.length - 1,
        );
      },
    );
  }
}
