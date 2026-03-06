import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/team.dart';
import '../../core/constants/app_spacing.dart';

class SetlistNotesScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int setlistId;

  const SetlistNotesScreen({
    super.key,
    required this.teamId,
    required this.setlistId,
  });

  @override
  ConsumerState<SetlistNotesScreen> createState() => _SetlistNotesScreenState();
}

class _SetlistNotesScreenState extends ConsumerState<SetlistNotesScreen> {
  String? _selectedPosition;

  static const _positionFilters = [
    (value: null, label: '전체'),
    (value: 'WORSHIP_LEADER', label: '워십리더'),
    (value: 'VOCAL', label: '보컬'),
    (value: 'ACOUSTIC_GUITAR', label: '어쿠스틱 기타'),
    (value: 'ELECTRIC_GUITAR', label: '일렉 기타'),
    (value: 'BASS', label: '베이스'),
    (value: 'KEYBOARD', label: '건반'),
    (value: 'DRUM', label: '드럼'),
    (value: 'SOUND', label: '음향'),
  ];

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(setlistNotesProvider((
      teamId: widget.teamId,
      setlistId: widget.setlistId,
      position: _selectedPosition,
    )));
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    final canEdit = membersAsync.whenOrNull(
          data: (members) => members
              .any((m) => m.userId == authState.user?.id && m.canEdit),
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('노트')),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => _showNoteForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Position filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _positionFilters.length,
              separatorBuilder: (_, _) => AppSpacing.hGapSm,
              itemBuilder: (context, index) {
                final filter = _positionFilters[index];
                final isSelected = _selectedPosition == filter.value;
                return FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPosition = selected ? filter.value : null;
                    });
                  },
                );
              },
            ),
          ),
          AppSpacing.gapSm,
          // Notes list
          Expanded(
            child: notesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (notes) {
                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_outlined,
                            size: 64, color: theme.colorScheme.outline),
                        AppSpacing.gapLg,
                        Text('아직 노트가 없어요',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    setlistNotesProvider((
                      teamId: widget.teamId,
                      setlistId: widget.setlistId,
                      position: _selectedPosition,
                    )),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(
                        note: note,
                        canEdit: canEdit,
                        onEdit: () =>
                            _showNoteForm(context, note: note),
                        onDelete: () =>
                            _deleteNote(context, note.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNoteForm(BuildContext context,
      {SetlistNoteResponse? note}) async {
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    String? selectedPosition = note?.position;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(note == null ? '노트 작성하기' : '노트 수정하기'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: selectedPosition,
                  decoration: const InputDecoration(
                    labelText: '포지션 (선택)',
                  ),
                  items: _positionFilters.map((f) {
                    return DropdownMenuItem(
                      value: f.value,
                      child: Text(f.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedPosition = value);
                  },
                ),
                AppSpacing.gapMd,
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    hintText: '노트 내용을 입력해 주세요',
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(note == null ? '작성하기' : '수정하기'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final api = ref.read(apiClientProvider);
      final data = {
        'content': contentCtrl.text,
        'position': ?selectedPosition,
      };
      if (note == null) {
        await api.post(
            '/teams/${widget.teamId}/setlists/${widget.setlistId}/notes',
            data: data);
      } else {
        await api.patch(
            '/teams/${widget.teamId}/setlists/${widget.setlistId}/notes/${note.id}',
            data: data);
      }
      ref.invalidate(setlistNotesProvider((
        teamId: widget.teamId,
        setlistId: widget.setlistId,
        position: _selectedPosition,
      )));
    }
  }

  Future<void> _deleteNote(BuildContext context, int noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('이 노트를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      await api.delete(
          '/teams/${widget.teamId}/setlists/${widget.setlistId}/notes/$noteId');
      ref.invalidate(setlistNotesProvider((
        teamId: widget.teamId,
        setlistId: widget.setlistId,
        position: _selectedPosition,
      )));
    }
  }
}

class _NoteCard extends StatelessWidget {
  final SetlistNoteResponse note;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.position != null)
                  Container(
                    padding: AppPadding.paddingBadge,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: AppRadius.borderXs,
                    ),
                    child: Text(
                      _positionLabel(note.position!),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                if (canEdit)
                  PopupMenuButton<String>(
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('수정')),
                      const PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                  ),
              ],
            ),
            AppSpacing.gapSm,
            Text(note.content, style: theme.textTheme.bodyMedium),
            AppSpacing.gapSm,
            Row(
              children: [
                Text(
                  note.authorName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(note.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _positionLabel(String position) {
    return switch (position) {
      'WORSHIP_LEADER' => '워십리더',
      'VOCAL' => '보컬',
      'ACOUSTIC_GUITAR' => '어쿠스틱 기타',
      'ELECTRIC_GUITAR' => '일렉 기타',
      'BASS' => '베이스',
      'KEYBOARD' => '건반',
      'DRUM' => '드럼',
      'SOUND' => '음향',
      _ => position,
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}
