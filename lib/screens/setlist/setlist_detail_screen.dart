import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/setlist.dart';

class SetlistDetailScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int setlistId;

  const SetlistDetailScreen({super.key, required this.teamId, required this.setlistId});

  @override
  ConsumerState<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends ConsumerState<SetlistDetailScreen> {
  bool _isReordering = false;
  List<SetlistItemResponse>? _reorderItems;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(setlistDetailProvider((teamId: widget.teamId, setlistId: widget.setlistId)));
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
              icon: const Icon(Icons.swap_vert),
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
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/teams/${widget.teamId}/setlists/${widget.setlistId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteSetlist(context, ref),
            ),
          ],
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (detail) {
          if (detail == null) return const Center(child: Text('콘티를 찾을 수 없습니다'));
          final items = _isReordering ? _reorderItems! : detail.items;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.displayTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(dateFormat.format(detail.worshipDate)),
                      ],
                    ),
                    if (detail.worshipType != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.church, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(detail.worshipType!),
                        ],
                      ),
                    ],
                    if (detail.memo != null && detail.memo!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(detail.memo!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              // Song list
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('곡 목록 (${items.length}곡)', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (!_isReordering)
                      TextButton.icon(
                        onPressed: () => _showAddSongDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('곡 추가'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('곡이 없습니다. 곡을 추가해주세요.',
                            style: theme.textTheme.bodyMedium),
                      )
                    : _isReordering
                        ? ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: items.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _reorderItems!.removeAt(oldIndex);
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
    ref.invalidate(setlistDetailProvider((teamId: widget.teamId, setlistId: widget.setlistId)));
  }

  Future<void> _removeItem(WidgetRef ref, int itemId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/teams/${widget.teamId}/setlists/${widget.setlistId}/items/$itemId');
    ref.invalidate(setlistDetailProvider((teamId: widget.teamId, setlistId: widget.setlistId)));
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final api = ref.read(apiClientProvider);
      await api.delete('/teams/${widget.teamId}/setlists/${widget.setlistId}');
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text('${index + 1}', style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
        ),
        title: Text(item.songTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (item.artist != null) item.artist!,
            if (item.songKey != null) 'Key: ${item.songKey}',
          ].join(' | '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: isReordering
            ? const Icon(Icons.drag_handle)
            : onRemove != null
                ? IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onRemove)
                : null,
      ),
    );
  }
}

class _AddSongSheet extends StatefulWidget {
  final int teamId;
  final int setlistId;
  final WidgetRef ref;

  const _AddSongSheet({required this.teamId, required this.setlistId, required this.ref});

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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '곡 검색...',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (v) => setState(() => _keyword = v.trim().isEmpty ? null : v.trim()),
              ),
            ),
            Expanded(
              child: songsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (paged) {
                  if (paged.content.isEmpty) {
                    return const Center(child: Text('곡이 없습니다'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: paged.content.length,
                    itemBuilder: (context, index) {
                      final song = paged.content[index];
                      return ListTile(
                        title: Text(song.title),
                        subtitle: Text(song.artist ?? ''),
                        trailing: const Icon(Icons.add),
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
    widget.ref.invalidate(setlistDetailProvider((teamId: widget.teamId, setlistId: widget.setlistId)));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('곡이 추가되었습니다')),
      );
    }
  }
}
