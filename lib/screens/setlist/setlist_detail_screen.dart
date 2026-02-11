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
import '../../widgets/conti_skeleton.dart';

class SetlistDetailScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int setlistId;

  const SetlistDetailScreen(
      {super.key, required this.teamId, required this.setlistId});

  @override
  ConsumerState<SetlistDetailScreen> createState() =>
      _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends ConsumerState<SetlistDetailScreen> {
  bool _isReordering = false;
  List<SetlistItemResponse>? _reorderItems;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(setlistDetailProvider(
        (teamId: widget.teamId, setlistId: widget.setlistId)));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');

    return Scaffold(
      appBar: AppBar(
        title: const Text('콘티 상세'),
        actions: [
          if (_isReordering)
            TextButton(
              onPressed: _saveReorder,
              child: const Text('저장'),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.swap_vert_rounded),
              tooltip: '순서 변경',
              onPressed: () {
                final detail = detailAsync.valueOrNull;
                if (detail != null) {
                  setState(() {
                    _isReordering = true;
                    _reorderItems = List.from(detail.items);
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(
                  '/teams/${widget.teamId}/setlists/${widget.setlistId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteSetlist(context, ref),
            ),
          ],
        ],
      ),
      body: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 72),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('콘티를 찾을 수 없습니다'));
          }
          final items = _isReordering ? _reorderItems! : detail.items;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: ContiCard(
                  borderGradient: AppTheme.warmGradient,
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
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(detail.worshipDate),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (detail.worshipType != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
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
                        Text(detail.memo!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),

              // Song list header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      '곡 목록 (${items.length}곡)',
                      style: theme.textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (!_isReordering)
                      TextButton.icon(
                        onPressed: () => _showAddSongDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('곡 추가'),
                      ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: items.isEmpty
                    ? ContiEmptyState(
                        icon: Icons.queue_music_rounded,
                        title: '곡이 없습니다',
                        subtitle: '곡을 추가해주세요',
                        actionLabel: '곡 추가',
                        onAction: () => _showAddSongDialog(context, ref),
                      )
                    : _isReordering
                        ? ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            itemCount: items.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item =
                                    _reorderItems!.removeAt(oldIndex);
                                _reorderItems!.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _SetlistItemTile(
                                key: ValueKey(item.id),
                                item: item,
                                index: index,
                                isReordering: true,
                                onRemove: null,
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _SetlistItemTile(
                                key: ValueKey(item.id),
                                item: item,
                                index: index,
                                isReordering: false,
                                onRemove: () => _removeItem(ref, item.id),
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
    await api.patch(
      '/teams/${widget.teamId}/setlists/${widget.setlistId}/items/reorder',
      data: {'itemIds': itemIds},
    );
    setState(() => _isReordering = false);
    ref.invalidate(setlistDetailProvider(
        (teamId: widget.teamId, setlistId: widget.setlistId)));
  }

  Future<void> _removeItem(WidgetRef ref, int itemId) async {
    final api = ref.read(apiClientProvider);
    await api.delete(
        '/teams/${widget.teamId}/setlists/${widget.setlistId}/items/$itemId');
    ref.invalidate(setlistDetailProvider(
        (teamId: widget.teamId, setlistId: widget.setlistId)));
  }

  void _showAddSongDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddSongSheet(
        teamId: widget.teamId,
        setlistId: widget.setlistId,
        ref: ref,
      ),
    );
  }

  Future<void> _deleteSetlist(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('콘티 삭제'),
        content: const Text('이 콘티를 삭제하시겠습니까?'),
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
      await api.delete(
          '/teams/${widget.teamId}/setlists/${widget.setlistId}');
      if (context.mounted) context.pop();
    }
  }
}

class _SetlistItemTile extends StatelessWidget {
  final SetlistItemResponse item;
  final int index;
  final bool isReordering;
  final VoidCallback? onRemove;

  const _SetlistItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isReordering,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContiCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        borderRadius: 16,
        child: Row(
          children: [
            // Number avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: AppRadius.borderSm,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
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
                  if (item.artist != null || item.songKey != null)
                    Text(
                      [
                        if (item.artist != null) item.artist!,
                        if (item.songKey != null)
                          'Key: ${item.songKey}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (item.songKey != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.songKey!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (isReordering)
              Icon(Icons.drag_handle_rounded,
                  color: theme.colorScheme.onSurfaceVariant)
            else if (onRemove != null)
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded,
                    color: theme.colorScheme.error.withValues(alpha: 0.7)),
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
  final int setlistId;
  final WidgetRef ref;

  const _AddSongSheet(
      {required this.teamId, required this.setlistId, required this.ref});

  @override
  State<_AddSongSheet> createState() => _AddSongSheetState();
}

class _AddSongSheetState extends State<_AddSongSheet> {
  final _searchController = TextEditingController();
  String? _keyword;

  @override
  Widget build(BuildContext context) {
    final params = SongListParams(teamId: widget.teamId, keyword: _keyword);
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
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '곡 검색...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (v) => setState(
                    () => _keyword = v.trim().isEmpty ? null : v.trim()),
              ),
            ),
            Expanded(
              child: songsAsync.when(
                loading: () => const ContiListSkeleton(
                    itemCount: 4, itemHeight: 56),
                error: (e, _) => Center(child: Text('$e')),
                data: (paged) {
                  if (paged.content.isEmpty) {
                    return ContiEmptyState(
                      icon: Icons.music_off_rounded,
                      title: '곡이 없습니다',
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
                        trailing: Icon(Icons.add_circle_outline_rounded,
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
    await api.post(
      '/teams/${widget.teamId}/setlists/${widget.setlistId}/items',
      data: {'songId': songId},
    );
    widget.ref.invalidate(setlistDetailProvider(
        (teamId: widget.teamId, setlistId: widget.setlistId)));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('곡이 추가되었습니다')),
      );
    }
  }
}
