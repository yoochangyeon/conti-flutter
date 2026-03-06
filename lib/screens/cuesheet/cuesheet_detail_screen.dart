import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/setlist.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

/// Detail screen for a cue sheet showing the full worship service order.
/// Displays all item types (songs, prayers, sermons, etc.) with reorder support.
class CueSheetDetailScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int cueSheetId;

  const CueSheetDetailScreen({
    super.key,
    required this.teamId,
    required this.cueSheetId,
  });

  @override
  ConsumerState<CueSheetDetailScreen> createState() =>
      _CueSheetDetailScreenState();
}

class _CueSheetDetailScreenState extends ConsumerState<CueSheetDetailScreen> {
  bool _isReordering = false;
  List<SetlistItemResponse>? _reorderItems;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(setlistDetailProvider(
        (teamId: widget.teamId, setlistId: widget.cueSheetId)));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.when(
          loading: () => const Text('큐시트'),
          error: (_, __) => const Text('큐시트'),
          data: (detail) => Text(detail?.displayTitle ?? '큐시트'),
        ),
        actions: [
          if (_isReordering)
            TextButton(
              onPressed: _saveReorder,
              child: const Text('저장'),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '수정',
              onPressed: () => context.push(
                  '/teams/${widget.teamId}/cuesheets/${widget.cueSheetId}/edit'),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'reorder':
                    final detail = detailAsync.valueOrNull;
                    if (detail != null) {
                      setState(() {
                        _isReordering = true;
                        _reorderItems = List.from(detail.items);
                      });
                    }
                  case 'copy':
                    _showCopyDialog(context, ref);
                  case 'link_conti':
                    _showLinkContiDialog(context, ref);
                  case 'unlink_conti':
                    _unlinkConti(ref);
                  case 'delete':
                    _deleteCueSheet(context, ref);
                }
              },
              itemBuilder: (context) {
                final detail = detailAsync.valueOrNull;
                return [
                  const PopupMenuItem(
                    value: 'reorder',
                    child: Row(children: [
                      Icon(Icons.swap_vert_rounded, size: 20),
                      AppSpacing.hGapSm,
                      Text('순서 변경'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(children: [
                      Icon(Icons.content_copy_rounded, size: 20),
                      AppSpacing.hGapSm,
                      Text('복사'),
                    ]),
                  ),
                  if (detail?.contiId == null)
                    const PopupMenuItem(
                      value: 'link_conti',
                      child: Row(children: [
                        Icon(Icons.link_rounded, size: 20),
                        AppSpacing.hGapSm,
                        Text('콘티 연결'),
                      ]),
                    )
                  else
                    const PopupMenuItem(
                      value: 'unlink_conti',
                      child: Row(children: [
                        Icon(Icons.link_off_rounded, size: 20),
                        AppSpacing.hGapSm,
                        Text('콘티 연결 해제'),
                      ]),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      AppSpacing.hGapSm,
                      Text('삭제',
                          style: TextStyle(color: AppColors.error)),
                    ]),
                  ),
                ];
              },
            ),
          ],
        ],
      ),
      body: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 72),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(setlistDetailProvider(
              (teamId: widget.teamId, setlistId: widget.cueSheetId))),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('큐시트를 찾을 수 없어요'));
          }
          final items = _isReordering ? _reorderItems! : detail.items;
          final hasServicePhases =
              items.any((i) => i.servicePhase != null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: ContiCard(
                  borderGradient: null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.displayTitle,
                          style: theme.textTheme.titleLarge),
                      AppSpacing.gapSm,
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14,
                              color:
                                  theme.colorScheme.onSurfaceVariant),
                          AppSpacing.hGapXs,
                          Text(
                            dateFormat.format(detail.worshipDate),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (detail.worshipType != null) ...[
                        AppSpacing.gapXs,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Text(
                            detail.worshipTypeDisplayName ??
                                detail.worshipType!,
                            style:
                                theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (detail.memo != null &&
                          detail.memo!.isNotEmpty) ...[
                        AppSpacing.gapSm,
                        Text(detail.memo!,
                            style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),

              // Linked conti section
              if (detail.contiId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: ContiCard(
                    onTap: () => context.push(
                        '/teams/${widget.teamId}/contis/${detail.contiId}'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm),
                    borderRadius: 16,
                    child: Row(
                      children: [
                        Icon(Icons.queue_music_rounded,
                            size: 20,
                            color: theme.colorScheme.primary),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('연결된 콘티',
                                  style: theme.textTheme.titleSmall),
                              Text('탭하여 콘티 보기',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Text(
                            '콘티 연결됨',
                            style:
                                theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AppSpacing.hGapXs,
                        Icon(Icons.chevron_right_rounded,
                            color:
                                theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),

              // Schedule section
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: ContiCard(
                  onTap: () => context.push(
                      '/teams/${widget.teamId}/cuesheets/${widget.cueSheetId}/schedule'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      Icon(Icons.group_rounded,
                          size: 20,
                          color: theme.colorScheme.primary),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Text('봉사 배정',
                            style: theme.textTheme.titleSmall),
                      ),
                      _ScheduleBadge(
                          teamId: widget.teamId,
                          setlistId: widget.cueSheetId),
                      Icon(Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              // Item list header
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      '예배 순서 (${items.length}개)',
                      style: theme.textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (!_isReordering)
                      TextButton.icon(
                        onPressed: () =>
                            _showAddItemDialog(context, ref),
                        icon:
                            const Icon(Icons.add_rounded, size: 18),
                        label: const Text('항목 추가'),
                      ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: items.isEmpty
                    ? ContiEmptyState(
                        icon: Icons.list_alt_rounded,
                        title: '아직 항목이 없어요',
                        subtitle: '예배 순서 항목을 추가해 보세요',
                        actionLabel: '항목 추가하기',
                        onAction: () =>
                            _showAddItemDialog(context, ref),
                      )
                    : _isReordering
                        ? ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            itemCount: items.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _reorderItems!
                                    .removeAt(oldIndex);
                                _reorderItems!
                                    .insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _CueSheetItemTile(
                                key: ValueKey(item.id),
                                item: item,
                                index: index,
                                isReordering: true,
                                onRemove: null,
                              );
                            },
                          )
                        : hasServicePhases
                            ? _buildGroupedList(items)
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _CueSheetItemTile(
                                    key: ValueKey(item.id),
                                    item: item,
                                    index: index,
                                    isReordering: false,
                                    onRemove: () => _removeItem(
                                        ref, item.id),
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedList(List<SetlistItemResponse> items) {
    final theme = Theme.of(context);
    final phases = ['BEFORE', 'DURING', 'AFTER'];
    final phaseLabels = {
      'BEFORE': '예배 전',
      'DURING': '예배 중',
      'AFTER': '예배 후',
    };

    final grouped = <String, List<SetlistItemResponse>>{};
    for (final phase in phases) {
      grouped[phase] =
          items.where((i) => i.servicePhase == phase).toList();
    }
    final unphased =
        items.where((i) => i.servicePhase == null).toList();

    Color phaseColor(String phase) {
      switch (phase) {
        case 'BEFORE':
          return AppColors.orange;
        case 'DURING':
          return AppColors.primary;
        case 'AFTER':
          return AppColors.teal;
        default:
          return theme.colorScheme.onSurfaceVariant;
      }
    }

    return ListView(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        for (final phase in phases)
          if (grouped[phase]!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.md, bottom: AppSpacing.xs),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: phaseColor(phase),
                    borderRadius: AppRadius.borderXxs,
                  ),
                ),
                AppSpacing.hGapSm,
                Text(
                  phaseLabels[phase]!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: phaseColor(phase),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
            ...grouped[phase]!.map((item) {
              final globalIndex = items.indexOf(item);
              return _CueSheetItemTile(
                key: ValueKey(item.id),
                item: item,
                index: globalIndex,
                isReordering: false,
                onRemove: () => _removeItem(ref, item.id),
              );
            }),
          ],
        if (unphased.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.md, bottom: AppSpacing.xs),
            child: Text(
              '기타',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...unphased.map((item) {
            final globalIndex = items.indexOf(item);
            return _CueSheetItemTile(
              key: ValueKey(item.id),
              item: item,
              index: globalIndex,
              isReordering: false,
              onRemove: () => _removeItem(ref, item.id),
            );
          }),
        ],
      ],
    );
  }

  // ─── Actions ───

  Future<void> _saveReorder() async {
    if (_reorderItems == null) return;
    final api = ref.read(apiClientProvider);
    final itemIds = _reorderItems!.map((e) => e.id).toList();
    final response = await api.patch(
      '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/items/reorder',
      data: {'itemIds': itemIds},
    );
    setState(() => _isReordering = false);
    if (response.success) {
      ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.cueSheetId)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(response.error?.message ?? '순서를 변경하지 못했어요')),
      );
    }
  }

  Future<void> _removeItem(WidgetRef ref, int itemId) async {
    final api = ref.read(apiClientProvider);
    final response = await api.delete(
        '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/items/$itemId');
    if (response.success) {
      ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.cueSheetId)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(response.error?.message ?? '항목을 제거하지 못했어요')),
      );
    }
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.music_note_rounded),
            title: const Text('찬양 추가'),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx2) => _AddSongSheet(
                  teamId: widget.teamId,
                  setlistId: widget.cueSheetId,
                  ref: ref,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields_rounded),
            title: const Text('헤더/구분선 추가'),
            onTap: () {
              Navigator.pop(ctx);
              _showAddHeaderDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('기타 항목 추가'),
            onTap: () {
              Navigator.pop(ctx);
              _showAddCustomItemDialog(context, ref);
            },
          ),
          AppSpacing.gapLg,
        ],
      ),
    );
  }

  Future<void> _showAddHeaderDialog(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('헤더 추가하기'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
              labelText: '헤더 제목', hintText: '예: 찬양 시간'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('추가')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/items',
        data: {
          'itemType': 'HEADER',
          'title': titleController.text.trim().isEmpty
              ? '---'
              : titleController.text.trim(),
        },
      );
      ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.cueSheetId)));
    }
  }

  Future<void> _showAddCustomItemDialog(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    String selectedType = 'PRAYER';
    final types = {
      'PRAYER': '기도',
      'SERMON': '설교',
      'OFFERING': '헌금',
      'ANNOUNCEMENT': '광고',
      'SCRIPTURE': '성경 봉독',
      'CREED': '사도신경',
      'BENEDICTION': '축도',
      'PRELUDE': '전주',
      'POSTLUDE': '후주',
      'TRANSITION': '전환',
      'CUSTOM': '기타',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('항목 추가'),
          content:
              Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration:
                  const InputDecoration(labelText: '항목 종류'),
              items: types.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setDialogState(
                  () => selectedType = v ?? selectedType),
            ),
            AppSpacing.gapLg,
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                  labelText: '제목', hintText: '예: 대표 기도'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('추가')),
          ],
        ),
      ),
    );
    if (confirmed == true &&
        titleController.text.trim().isNotEmpty) {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/items',
        data: {
          'itemType': selectedType,
          'title': titleController.text.trim(),
        },
      );
      ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.cueSheetId)));
    }
  }

  Future<void> _showCopyDialog(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('큐시트 복사'),
          content:
              Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                  labelText: '새 큐시트 제목 (선택)',
                  hintText: '비워두면 원본 제목 사용'),
            ),
            AppSpacing.gapLg,
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setDialogState(() => selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '예배 날짜 *',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(dateFormat.format(selectedDate)),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('복사')),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      final api = ref.read(apiClientProvider);
      final copyRequest = SetlistCopyRequest(
        title: titleController.text.trim().isEmpty
            ? null
            : titleController.text.trim(),
        worshipDate: selectedDate,
      );
      final response = await api.post(
        '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/copy',
        data: copyRequest.toJson(),
      );
      if (response.success && context.mounted) {
        ref.invalidate(setlistsProvider(SetlistListParams(
            teamId: widget.teamId, setlistType: 'CUE_SHEET')));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('큐시트를 복사했어요')));
      }
    }
  }

  Future<void> _showLinkContiDialog(
      BuildContext context, WidgetRef ref) async {
    final contiParams = SetlistListParams(
        teamId: widget.teamId, setlistType: 'CONTI');
    final contiListAsync =
        ref.read(setlistsProvider(contiParams));
    final contiList =
        contiListAsync.valueOrNull?.content ?? [];

    if (contiList.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('연결할 콘티가 없어요. 먼저 콘티를 만들어 주세요.')));
      }
      return;
    }

    int? selectedContiId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('콘티 연결'),
          content: DropdownButtonFormField<int>(
            value: selectedContiId,
            decoration:
                const InputDecoration(labelText: '연결할 콘티 선택'),
            items: contiList
                .map((c) => DropdownMenuItem(
                    value: c.id, child: Text(c.displayTitle)))
                .toList(),
            onChanged: (v) =>
                setDialogState(() => selectedContiId = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: selectedContiId != null
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('연결')),
          ],
        ),
      ),
    );
    if (confirmed == true && selectedContiId != null) {
      final api = ref.read(apiClientProvider);
      final response = await api.patch(
        '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/link-conti?contiId=$selectedContiId',
      );
      if (response.success) {
        ref.invalidate(setlistDetailProvider(
            (teamId: widget.teamId, setlistId: widget.cueSheetId)));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('콘티를 연결했어요')));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response.error?.message ?? '콘티를 연결하지 못했어요')),
        );
      }
    }
  }

  Future<void> _unlinkConti(WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final response = await api.patch(
      '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/unlink-conti',
    );
    if (response.success) {
      ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.cueSheetId)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('콘티 연결을 해제했어요')));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                response.error?.message ?? '콘티 연결을 해제하지 못했어요')),
      );
    }
  }

  Future<void> _deleteCueSheet(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('큐시트 삭제'),
        content: const Text('이 큐시트를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.error,
              ),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final api = ref.read(apiClientProvider);
      final response = await api.delete(
          '/teams/${widget.teamId}/setlists/${widget.cueSheetId}');
      if (context.mounted) {
        if (response.success) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    response.error?.message ?? '삭제하지 못했어요')),
          );
        }
      }
    }
  }
}

// ─── Item Tile Widget ───

class _CueSheetItemTile extends StatelessWidget {
  final SetlistItemResponse item;
  final int index;
  final bool isReordering;
  final VoidCallback? onRemove;

  const _CueSheetItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isReordering,
    this.onRemove,
  });

  static Color? _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;
    final hex = colorStr.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return null;
  }

  static IconData _itemTypeIcon(String? itemType) {
    switch (itemType) {
      case 'PRAYER':
        return Icons.volunteer_activism_rounded;
      case 'SERMON':
        return Icons.menu_book_rounded;
      case 'OFFERING':
        return Icons.card_giftcard_rounded;
      case 'ANNOUNCEMENT':
        return Icons.campaign_rounded;
      case 'SCRIPTURE':
        return Icons.auto_stories_rounded;
      case 'CREED':
        return Icons.groups_rounded;
      case 'BENEDICTION':
        return Icons.back_hand_rounded;
      case 'PRELUDE':
        return Icons.piano_rounded;
      case 'POSTLUDE':
        return Icons.piano_rounded;
      case 'TRANSITION':
        return Icons.swap_horiz_rounded;
      case 'CUSTOM':
        return Icons.widgets_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // HEADER items render as a divider with centered text
    if (item.isHeader) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
                child: Divider(
                    color: theme.colorScheme.outlineVariant)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                item.songTitle.isEmpty
                    ? '---'
                    : item.songTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
                child: Divider(
                    color: theme.colorScheme.outlineVariant)),
            if (isReordering)
              Icon(Icons.drag_handle_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant)
            else if (onRemove != null)
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
                onPressed: onRemove,
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 28, minHeight: 28),
              ),
          ],
        ),
      );
    }

    final itemColor = _parseColor(item.color);
    final isSong = item.isSongItem;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContiCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm),
        borderRadius: 16,
        child: Row(
          children: [
            // Number avatar / Item type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: itemColor ??
                    (isSong
                        ? AppColors.primary
                        : AppColors.teal),
                borderRadius: AppRadius.borderSm,
              ),
              child: Center(
                child: isSong
                    ? Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      )
                    : Icon(
                        _itemTypeIcon(item.itemType),
                        color: AppColors.white,
                        size: 18,
                      ),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.songTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (isSong &&
                      (item.artist != null ||
                          item.songKey != null))
                    Text(
                      [
                        if (item.artist != null) item.artist!,
                        if (item.songKey != null)
                          'Key: ${item.songKey}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (!isSong &&
                      item.itemTypeDisplayName != null)
                    Text(
                      item.itemTypeDisplayName!,
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: theme
                            .colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (item.songKey != null && isSong) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  item.songKey!,
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSpacing.hGapXs,
            ],
            if (item.durationMinutes != null && !isSong) ...[
              Text(
                '${item.durationMinutes}분',
                style:
                    theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.hGapXs,
            ],
            if (isReordering)
              Icon(Icons.drag_handle_rounded,
                  color: theme.colorScheme.onSurfaceVariant)
            else if (onRemove != null)
              IconButton(
                icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.error),
                onPressed: onRemove,
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Badge ───

class _ScheduleBadge extends ConsumerWidget {
  final int teamId;
  final int setlistId;

  const _ScheduleBadge(
      {required this.teamId, required this.setlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(setlistSchedulesProvider(
        (teamId: teamId, setlistId: setlistId)));
    final theme = Theme.of(context);

    return schedulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedules) {
        if (schedules.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 2),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: AppRadius.borderSm,
          ),
          child: Text(
            '${schedules.length}명',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

// ─── Add Song Sheet ───

class _AddSongSheet extends StatefulWidget {
  final int teamId;
  final int setlistId;
  final WidgetRef ref;

  const _AddSongSheet({
    required this.teamId,
    required this.setlistId,
    required this.ref,
  });

  @override
  State<_AddSongSheet> createState() => _AddSongSheetState();
}

class _AddSongSheetState extends State<_AddSongSheet> {
  final _searchController = TextEditingController();
  String? _keyword;

  @override
  Widget build(BuildContext context) {
    final params =
        SongListParams(teamId: widget.teamId, keyword: _keyword);
    final songsAsync = widget.ref.watch(songsProvider(params));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding:
                  const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: AppRadius.borderXxs,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '곡 이름으로 검색해 보세요',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (v) => setState(() =>
                    _keyword =
                        v.trim().isEmpty ? null : v.trim()),
              ),
            ),
            Expanded(
              child: songsAsync.when(
                loading: () => const ContiListSkeleton(
                    itemCount: 4, itemHeight: 56),
                error: (e, _) =>
                    Center(child: Text('$e')),
                data: (paged) {
                  if (paged.content.isEmpty) {
                    return const ContiEmptyState(
                      icon: Icons.music_off_rounded,
                      title: '곡이 없어요',
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: paged.content.length,
                    itemBuilder: (context, index) {
                      final song = paged.content[index];
                      return ListTile(
                        title: Text(song.title),
                        subtitle: Text(song.artist ?? ''),
                        trailing: Icon(
                            Icons
                                .add_circle_outline_rounded,
                            color:
                                theme.colorScheme.primary),
                        onTap: () => _addSong(song.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSong(int songId) async {
    final api = widget.ref.read(apiClientProvider);
    final response = await api.post(
      '/teams/${widget.teamId}/setlists/${widget.setlistId}/items',
      data: {'songId': songId},
    );
    if (response.success) {
      widget.ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.setlistId)));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('곡을 추가했어요')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                response.error?.message ?? '곡을 추가하지 못했어요')),
      );
    }
  }
}
