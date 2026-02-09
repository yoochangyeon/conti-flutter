import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/song.dart';

class SongListScreen extends ConsumerStatefulWidget {
  final int teamId;

  const SongListScreen({super.key, required this.teamId});

  @override
  ConsumerState<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends ConsumerState<SongListScreen> {
  final _searchController = TextEditingController();
  String? _keyword;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _keyword = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = SongListParams(teamId: widget.teamId, keyword: _keyword);
    final songsAsync = ref.watch(songsProvider(params));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('찬양 DB')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '제목 또는 아티스트 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keyword != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _keyword = null);
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: songsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (paged) {
                if (paged.content.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          _keyword != null ? '검색 결과가 없습니다' : '등록된 찬양이 없습니다',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(songsProvider(params)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: paged.content.length,
                    itemBuilder: (context, index) {
                      final song = paged.content[index];
                      return _SongTile(
                        song: song,
                        onTap: () => context.push('/teams/${widget.teamId}/songs/${song.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teams/${widget.teamId}/songs/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongResponse song;
  final VoidCallback onTap;

  const _SongTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (song.artist != null) song.artist!,
            if (song.originalKey != null) 'Key: ${song.originalKey}',
          ].join(' | '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: song.tags.isNotEmpty
            ? Wrap(
                spacing: 4,
                children: song.tags
                    .take(2)
                    .map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              )
            : null,
      ),
    );
  }
}
