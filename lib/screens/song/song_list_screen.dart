import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/song.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_skeleton.dart';

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
      _keyword = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = SongListParams(teamId: widget.teamId, keyword: _keyword);
    final songsAsync = ref.watch(songsProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('찬양 DB')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '제목 또는 아티스트 검색',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _keyword != null
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
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
              loading: () => const ContiListSkeleton(
                  itemCount: 6, itemHeight: 72),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (paged) {
                if (paged.content.isEmpty) {
                  return ContiEmptyState(
                    icon: Icons.music_off_rounded,
                    title: _keyword != null ? '검색 결과가 없습니다' : '등록된 찬양이 없습니다',
                    subtitle:
                        _keyword != null ? '다른 키워드로 검색해보세요' : '새로운 찬양을 추가해보세요',
                    actionLabel: _keyword == null ? '찬양 추가' : null,
                    onAction: _keyword == null
                        ? () => context
                            .push('/teams/${widget.teamId}/songs/create')
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(songsProvider(params)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    itemCount: paged.content.length,
                    itemBuilder: (context, index) {
                      final song = paged.content[index];
                      return _SongTile(
                        song: song,
                        onTap: () => context.push(
                            '/teams/${widget.teamId}/songs/${song.id}'),
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
        onPressed: () =>
            context.push('/teams/${widget.teamId}/songs/create'),
        child: const Icon(Icons.add_rounded),
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
    // Generate a gradient color based on the song title
    final colorIndex = song.title.hashCode.abs() % 5;
    final avatarColors = [
      [AppTheme.primaryColor, AppTheme.secondaryColor],
      [AppTheme.tertiaryColor, const Color(0xFFFF9A76)],
      [AppTheme.secondaryColor, const Color(0xFF56CCF2)],
      [const Color(0xFFFF9A76), const Color(0xFFFFC857)],
      [const Color(0xFF56CCF2), AppTheme.primaryColor],
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContiCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: 16,
        child: Row(
          children: [
            // Title initial avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: avatarColors[colorIndex],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.borderMd,
              ),
              child: Center(
                child: Text(
                  song.title.isNotEmpty ? song.title[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            AppSpacing.hGapMd,
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (song.artist != null || song.originalKey != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (song.artist != null) song.artist!,
                        if (song.originalKey != null)
                          'Key: ${song.originalKey}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Tags
            if (song.tags.isNotEmpty) ...[
              AppSpacing.hGapSm,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  song.tags.first,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
