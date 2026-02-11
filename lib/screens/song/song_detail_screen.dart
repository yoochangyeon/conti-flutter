import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_skeleton.dart';
import 'song_structure_tab.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int songId;

  const SongDetailScreen(
      {super.key, required this.teamId, required this.songId});

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(
        songDetailProvider((teamId: widget.teamId, songId: widget.songId)));

    return Scaffold(
      appBar: AppBar(
        title: songAsync.whenOrNull(
              data: (song) => Text(song?.title ?? '찬양 상세'),
            ) ??
            const Text('찬양 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context
                .push('/teams/${widget.teamId}/songs/${widget.songId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteSong(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '정보'),
            Tab(text: '곡 구조'),
          ],
        ),
      ),
      body: songAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 4, itemHeight: 72),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (song) {
          if (song == null) {
            return const Center(child: Text('곡을 찾을 수 없습니다'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _InfoTab(song: song, teamId: widget.teamId),
              SongStructureTab(
                sections: song.sections,
                onEdit: () => context.push(
                  '/teams/${widget.teamId}/songs/${widget.songId}/structure/edit',
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: songAsync.whenOrNull(
        data: (song) {
          if (song == null) return null;
          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index != 1) return const SizedBox.shrink();
              return FloatingActionButton(
                onPressed: () => context.push(
                  '/teams/${widget.teamId}/songs/${widget.songId}/structure/edit',
                ),
                child: Icon(
                  song.sections.isEmpty ? Icons.add : Icons.edit,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteSong(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('찬양 삭제'),
        content: const Text('이 찬양을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
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
      await api.delete('/teams/${widget.teamId}/songs/${widget.songId}');
      if (context.mounted) context.pop();
    }
  }
}

class _InfoTab extends StatelessWidget {
  final dynamic song;
  final int teamId;

  const _InfoTab({required this.song, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Title + Artist header
        Text(
          song.title,
          style: theme.textTheme.headlineMedium,
        ),
        if (song.artist != null) ...[
          const SizedBox(height: 4),
          Text(
            song.artist!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        AppSpacing.gapLg,

        // Tags
        if (song.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: song.tags
                .map<Widget>((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
          AppSpacing.gapLg,
        ],

        // Info chips row
        ContiCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (song.originalKey != null)
                _InfoItem(
                  icon: Icons.music_note_rounded,
                  label: 'Key',
                  value: song.originalKey!,
                ),
              if (song.bpm != null)
                _InfoItem(
                  icon: Icons.speed_rounded,
                  label: 'BPM',
                  value: '${song.bpm}',
                ),
              _InfoItem(
                icon: Icons.history_rounded,
                label: '사용',
                value: '${song.usageCount}회',
              ),
            ],
          ),
        ),

        AppSpacing.gapXxl,

        // Links section
        if (song.youtubeUrl != null && song.youtubeUrl!.isNotEmpty) ...[
          _LinkCard(
            icon: Icons.play_circle_filled_rounded,
            iconColor: Colors.red,
            title: 'YouTube',
            subtitle: '유튜브에서 보기',
            onTap: () => _openUrl(song.youtubeUrl!),
          ),
          AppSpacing.gapSm,
        ],
        if (song.musicUrl != null && song.musicUrl!.isNotEmpty) ...[
          _LinkCard(
            icon: Icons.audiotrack_rounded,
            iconColor: AppTheme.secondaryColor,
            title: '음원 링크',
            subtitle: '음원 재생하기',
            onTap: () => _openUrl(song.musicUrl!),
          ),
          AppSpacing.gapSm,
        ],

        // Memo section
        if (song.memo != null && song.memo!.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text('메모', style: theme.textTheme.titleSmall),
          AppSpacing.gapSm,
          ContiCard(
            child: Text(
              song.memo!,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],

        // Files section
        if (song.files.isNotEmpty) ...[
          AppSpacing.gapXxl,
          Text('악보 파일', style: theme.textTheme.titleSmall),
          AppSpacing.gapSm,
          ...song.files.map<Widget>((file) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _LinkCard(
                  icon: Icons.insert_drive_file_rounded,
                  iconColor: AppTheme.tertiaryColor,
                  title: file.fileName,
                  subtitle: file.fileType ?? '파일',
                  trailing: const Icon(Icons.download_rounded, size: 20),
                  onTap: () => _openUrl(file.fileUrl),
                ),
              )),
        ],

        // Bottom padding for FAB
        AppSpacing.gapHuge,
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _LinkCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ],
      ),
    );
  }
}
