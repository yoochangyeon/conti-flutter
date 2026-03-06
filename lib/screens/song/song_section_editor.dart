import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';

import '../../models/song.dart';
import '../../providers/providers.dart';
import '../../widgets/build_up_indicator.dart';
import '../../widgets/conti_gradient_button.dart';

class SongSectionEditorScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int songId;

  const SongSectionEditorScreen({
    super.key,
    required this.teamId,
    required this.songId,
  });

  @override
  ConsumerState<SongSectionEditorScreen> createState() =>
      _SongSectionEditorScreenState();
}

class _SongSectionEditorScreenState
    extends ConsumerState<SongSectionEditorScreen> {
  List<_EditableSection> _sections = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSections();
  }

  void _loadExistingSections() {
    final songAsync = ref
        .read(songDetailProvider((teamId: widget.teamId, songId: widget.songId)));
    songAsync.whenData((song) {
      if (song == null) return;
      setState(() {
        _sections = song.sections
            .map((s) => _EditableSection(
                  sectionType: s.sectionType,
                  label: s.label ?? '',
                  chords: s.chords ?? '',
                  buildUpLevel: s.buildUpLevel ?? 3,
                  memo: s.memo ?? '',
                ))
            .toList();
      });
    });
  }

  void _addSection() {
    setState(() {
      _sections.add(_EditableSection(
        sectionType: 'VERSE',
        label: '',
        chords: '',
        buildUpLevel: 3,
        memo: '',
      ));
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final requests = _sections.asMap().entries.map((entry) {
        final s = entry.value;
        return SongSectionRequest(
          sectionType: s.sectionType,
          orderIndex: entry.key,
          label: s.label.isEmpty ? null : s.label,
          chords: s.chords.isEmpty ? null : s.chords,
          buildUpLevel: s.buildUpLevel,
          memo: s.memo.isEmpty ? null : s.memo,
        );
      }).toList();

      final response = await apiClient.put(
        '/teams/${widget.teamId}/songs/${widget.songId}/sections',
        data: requests.map((r) => r.toJson()).toList(),
      );

      if (!response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장하지 못했어요: ${response.error?.message ?? '알 수 없는 오류'}')),
          );
        }
        return;
      }

      final providerKey = (teamId: widget.teamId, songId: widget.songId);
      ref.invalidate(songDetailProvider(providerKey));
      await ref.read(songDetailProvider(providerKey).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('곡 구조를 저장했어요')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장하지 못했어요: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('곡 구조 편집'),
        actions: [
          IconButton(
            onPressed: _addSection,
            icon: const Icon(Icons.add_rounded),
            tooltip: '섹션 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _sections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.queue_music_rounded,
                          size: 48,
                          color: AppColors.gray300,
                        ),
                        AppSpacing.gapLg,
                        Text(
                          '섹션을 추가해 보세요',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        AppSpacing.gapLg,
                        FilledButton.icon(
                          onPressed: _addSection,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('섹션 추가'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _sections.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _sections.removeAt(oldIndex);
                        _sections.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return _SectionEditCard(
                        key: ValueKey(
                            '${_sections[index].sectionType}_$index'),
                        section: _sections[index],
                        index: index,
                        onChanged: (updated) {
                          setState(() => _sections[index] = updated);
                        },
                        onRemove: () => _removeSection(index),
                      );
                    },
                  ),
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ContiGradientButton(
                label: '저장',
                icon: Icons.save_rounded,
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableSection {
  String sectionType;
  String label;
  String chords;
  int buildUpLevel;
  String memo;

  _EditableSection({
    required this.sectionType,
    required this.label,
    required this.chords,
    required this.buildUpLevel,
    required this.memo,
  });
}

class _SectionEditCard extends StatelessWidget {
  final _EditableSection section;
  final int index;
  final ValueChanged<_EditableSection> onChanged;
  final VoidCallback onRemove;

  const _SectionEditCard({
    super.key,
    required this.section,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          // Header with drag handle and delete
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, 0),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: section.sectionType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.primaryLight,
                    ),
                    items: AppConstants.sectionTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          AppConstants.sectionTypeNames[type] ?? type,
                          style: theme.textTheme.titleSmall,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        section.sectionType = value;
                        onChanged(section);
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Column(
              children: [
                TextFormField(
                  initialValue: section.label,
                  decoration: const InputDecoration(
                    hintText: '라벨 (예: 1절, 2절)',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    section.label = v;
                    onChanged(section);
                  },
                ),
                AppSpacing.gapSm,
                TextFormField(
                  initialValue: section.chords,
                  decoration: const InputDecoration(
                    hintText: '코드 진행 (예: G - D - Em - C)',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    section.chords = v;
                    onChanged(section);
                  },
                ),
                AppSpacing.gapSm,
                // Build up level slider
                Row(
                  children: [
                    Text(
                      '빌드업',
                      style: theme.textTheme.bodySmall,
                    ),
                    AppSpacing.hGapSm,
                    BuildUpIndicator(level: section.buildUpLevel),
                    Expanded(
                      child: Slider(
                        value: section.buildUpLevel.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: section.buildUpLevel.toString(),
                        onChanged: (v) {
                          section.buildUpLevel = v.round();
                          onChanged(section);
                        },
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  initialValue: section.memo,
                  decoration: const InputDecoration(
                    hintText: '메모 (선택)',
                    isDense: true,
                  ),
                  maxLines: 2,
                  onChanged: (v) {
                    section.memo = v;
                    onChanged(section);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
