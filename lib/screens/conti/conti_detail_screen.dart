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

class ContiDetailScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int contiId;

  const ContiDetailScreen(
      {super.key, required this.teamId, required this.contiId});

  @override
  ConsumerState<ContiDetailScreen> createState() =>
      _ContiDetailScreenState();
}

class _ContiDetailScreenState extends ConsumerState<ContiDetailScreen> {
  bool _isReordering = false;
  List<SetlistItemResponse>? _reorderItems;

  List<SetlistItemResponse> _songItemsOnly(List<SetlistItemResponse> items) {
    return items.where((i) => i.isSongItem).toList();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(setlistDetailProvider(
        (teamId: widget.teamId, setlistId: widget.contiId)));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.whenOrNull(
              data: (detail) => Text(detail?.displayTitle ?? '콘티 상세'),
            ) ??
            const Text('콘티 상세'),
        actions: [
          if (_isReordering)
            TextButton(
              onPressed: _saveReorder,
              child: const Text('저장'),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(
                  '/teams/${widget.teamId}/contis/${widget.contiId}/edit'),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'copy':
                    _showCopyDialog(context, ref);
                    break;
                  case 'delete':
                    _deleteConti(context, ref);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy_rounded, size: 20),
                      AppSpacing.hGapSm,
                      Text('복사'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      AppSpacing.hGapSm,
                      Text('삭제',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
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
              (teamId: widget.teamId, setlistId: widget.contiId))),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('콘티를 찾을 수 없어요'));
          }
          final songItems = _isReordering
              ? _reorderItems!
              : _songItemsOnly(detail.items);

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
                              color: theme.colorScheme.onSurfaceVariant),
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
                            style: theme.textTheme.labelSmall?.copyWith(
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

              // Notes link card
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: ContiCard(
                  onTap: () => context.push(
                      '/teams/${widget.teamId}/setlists/${widget.contiId}/notes'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      Icon(Icons.note_rounded,
                          size: 20, color: theme.colorScheme.tertiary),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Text('노트',
                            style: theme.textTheme.titleSmall),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              // Song list header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      '곡 목록 (${songItems.length}곡)',
                      style: theme.textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (!_isReordering) ...[
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isReordering = true;
                            _reorderItems =
                                List.from(_songItemsOnly(detail.items));
                          });
                        },
                        icon: const Icon(Icons.swap_vert_rounded, size: 18),
                        label: const Text('순서 변경'),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddSongSheet(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('곡 추가'),
                      ),
                    ],
                  ],
                ),
              ),

              // Song items list
              Expanded(
                child: songItems.isEmpty
                    ? ContiEmptyState(
                        icon: Icons.queue_music_rounded,
                        title: '아직 곡이 없어요',
                        subtitle: '찬양을 추가해 보세요',
                        actionLabel: '곡 추가하기',
                        onAction: () => _showAddSongSheet(context, ref),
                      )
                    : _isReordering
                        ? ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            itemCount: songItems.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item =
                                    _reorderItems!.removeAt(oldIndex);
                                _reorderItems!.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final item = songItems[index];
                              return _ContiSongTile(
                                key: ValueKey(item.id),
                                item: item,
                                index: index,
                                isReordering: true,
                                onTap: null,
                                onRemove: null,
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            itemCount: songItems.length,
                            itemBuilder: (context, index) {
                              final item = songItems[index];
                              return _ContiSongTile(
                                key: ValueKey(item.id),
                                item: item,
                                index: index,
                                isReordering: false,
                                onTap: item.songId != null
                                    ? () => context.push(
                                        '/teams/${widget.teamId}/songs/${item.songId}')
                                    : null,
                                onRemove: () =>
                                    _removeItem(ref, item.id),
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

  Future<void> _saveReorder() async {
    if (_reorderItems == null) return;
    final api = ref.read(apiClientProvider);
    final itemIds = _reorderItems!.map((e) => e.id).toList();
    final response = await api.patch(
      '/teams/${widget.teamId}/setlists/${widget.contiId}/items/reorder',
      data: {'itemIds': itemIds},
    );
    setState(() => _isReordering = false);
    if (response.success) {
      ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.contiId)));
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
        '/teams/${widget.teamId}/setlists/${widget.contiId}/items/$itemId');
    if (response.success) {
      ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.contiId)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(response.error?.message ?? '곡을 제거하지 못했어요')),
      );
    }
  }

  void _showAddSongSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddSongSheet(
        teamId: widget.teamId,
        contiId: widget.contiId,
        ref: ref,
      ),
    );
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
          title: const Text('콘티 복사'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '새 콘티 제목 (선택)',
                  hintText: '비워두면 원본 제목 사용',
                )),
            AppSpacing.gapLg,
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030));
                if (picked != null) {
                  setDialogState(() => selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: '예배 날짜 *',
                    suffixIcon: Icon(Icons.calendar_today)),
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
        '/teams/${widget.teamId}/setlists/${widget.contiId}/copy',
        data: copyRequest.toJson(),
      );
      if (response.success && context.mounted) {
        ref.invalidate(setlistsProvider(SetlistListParams(
            teamId: widget.teamId, setlistType: 'CONTI')));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('콘티를 복사했어요')));
      }
    }
  }

  Future<void> _deleteConti(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('콘티 삭제'),
        content: const Text('이 콘티를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final api = ref.read(apiClientProvider);
      final response = await api
          .delete('/teams/${widget.teamId}/setlists/${widget.contiId}');
      if (context.mounted) {
        if (response.success) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response.error?.message ?? '삭제하지 못했어요')),
          );
        }
      }
    }
  }
}

class _ContiSongTile extends StatelessWidget {
  final SetlistItemResponse item;
  final int index;
  final bool isReordering;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _ContiSongTile({
    super.key,
    required this.item,
    required this.index,
    required this.isReordering,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContiCard(
        onTap: isReordering ? null : onTap,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        borderRadius: 16,
        child: Row(
          children: [
            // Number circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.borderSm,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
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
                  if (item.artist != null)
                    Text(
                      item.artist!,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (item.songKey != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  item.songKey!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSpacing.hGapXs,
            ],
            if (isReordering)
              Icon(Icons.drag_handle_rounded,
                  color: theme.colorScheme.onSurfaceVariant)
            else if (onRemove != null)
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded,
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

class _AddSongSheet extends StatefulWidget {
  final int teamId;
  final int contiId;
  final WidgetRef ref;

  const _AddSongSheet(
      {required this.teamId, required this.contiId, required this.ref});

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
              padding: const EdgeInsets.only(top: AppSpacing.sm),
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
                    _keyword = v.trim().isEmpty ? null : v.trim()),
              ),
            ),
            Expanded(
              child: songsAsync.when(
                loading: () => const ContiListSkeleton(
                    itemCount: 4, itemHeight: 56),
                error: (e, _) => Center(child: Text('$e')),
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
                            Icons.add_circle_outline_rounded,
                            color: theme.colorScheme.primary),
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
      '/teams/${widget.teamId}/setlists/${widget.contiId}/items',
      data: {'songId': songId},
    );
    if (response.success) {
      widget.ref.invalidate(setlistDetailProvider(
          (teamId: widget.teamId, setlistId: widget.contiId)));
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
