import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/models/song.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/animated/conti_fade_in.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_error_state.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: '편곡'),
          ],
        ),
      ),
      body: songAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 4, itemHeight: 72),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(songDetailProvider(
              (teamId: widget.teamId, songId: widget.songId))),
        ),
        data: (song) {
          if (song == null) {
            return const Center(child: Text('곡을 찾을 수 없어요'));
          }
          return ContiFadeIn(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(song: song, teamId: widget.teamId),
                SongStructureTab(
                  sections: song.sections,
                  originalKey: song.originalKey,
                  onEdit: () => context.push(
                    '/teams/${widget.teamId}/songs/${widget.songId}/structure/edit',
                  ),
                ),
                _ArrangementsTab(song: song, teamId: widget.teamId),
              ],
            ),
          );
        },
      ),
      floatingActionButton: songAsync.whenOrNull(
        data: (song) {
          if (song == null) return null;
          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 1) {
                return FloatingActionButton(
                  onPressed: () => context.push(
                    '/teams/${widget.teamId}/songs/${widget.songId}/structure/edit',
                  ),
                  child: Icon(
                    song.sections.isEmpty ? Icons.add : Icons.edit,
                  ),
                );
              }
              if (_tabController.index == 2) {
                return FloatingActionButton(
                  onPressed: () => context.push(
                    '/teams/${widget.teamId}/songs/${widget.songId}/arrangements/create',
                  ),
                  child: const Icon(Icons.add),
                );
              }
              return const SizedBox.shrink();
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
        content: const Text('이 찬양을 삭제할까요? 삭제하면 되돌릴 수 없어요.'),
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
      final response = await api.delete('/teams/${widget.teamId}/songs/${widget.songId}');
      if (context.mounted) {
        if (response.success) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error?.message ?? '삭제하지 못했어요')),
          );
        }
      }
    }
  }
}

class _InfoTab extends ConsumerWidget {
  final SongDetailResponse song;
  final int teamId;

  const _InfoTab({required this.song, required this.teamId});

  Future<void> _deleteFile(
      BuildContext context, WidgetRef ref, int fileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('파일 삭제'),
        content: const Text('이 파일을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      final response = await api.delete(
        '/teams/$teamId/songs/${song.id}/files/$fileId',
      );
      if (response.success) {
        ref.invalidate(
            songDetailProvider((teamId: teamId, songId: song.id)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response.error?.message ?? '삭제하지 못했어요')),
        );
      }
    }
  }

  Future<void> _addFileUrl(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('악보 URL 추가하기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: '파일 이름 *', hintText: '예: 코드 악보'),
            ),
            AppSpacing.gapMd,
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                  labelText: 'URL *', hintText: 'https://...'),
            ),
          ],
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
    if (confirmed == true &&
        nameCtrl.text.trim().isNotEmpty &&
        urlCtrl.text.trim().isNotEmpty) {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        '/teams/$teamId/songs/${song.id}/files/url',
        data: {
          'fileName': nameCtrl.text.trim(),
          'fileUrl': urlCtrl.text.trim(),
        },
      );
      if (response.success) {
        ref.invalidate(
            songDetailProvider((teamId: teamId, songId: song.id)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response.error?.message ?? '추가하지 못했어요')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          AppSpacing.gapXs,
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
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: song.tags
                .map<Widget>((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryLight,
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
              if (song.lastUsedAt != null)
                _InfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: '마지막 사용',
                  value: song.lastUsedAt!,
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
            subtitle: '유튜브에서 들어보기',
            onTap: () => _openUrl(song.youtubeUrl!),
          ),
          AppSpacing.gapSm,
        ],
        if (song.musicUrl != null && song.musicUrl!.isNotEmpty) ...[
          _LinkCard(
            icon: Icons.audiotrack_rounded,
            iconColor: AppColors.teal,
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
        AppSpacing.gapXxl,
        Row(
          children: [
            Expanded(
                child:
                    Text('악보 파일', style: theme.textTheme.titleSmall)),
            TextButton.icon(
              onPressed: () => _addFileUrl(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('URL 추가'),
            ),
          ],
        ),
        AppSpacing.gapSm,
        if (song.files.isEmpty)
          Text(
            '등록된 파일이 없어요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ...song.files.map<Widget>((file) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LinkCard(
                icon: Icons.insert_drive_file_rounded,
                iconColor: AppColors.pink,
                title: file.fileName,
                subtitle: file.fileType ?? '파일',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded, size: 20),
                    AppSpacing.hGapXs,
                    GestureDetector(
                      onTap: () => _deleteFile(context, ref, file.id),
                      child: Icon(Icons.close_rounded,
                          size: 18,
                          color: AppColors.error),
                    ),
                  ],
                ),
                onTap: () => _openUrl(file.fileUrl),
              ),
            )),

        // Usage history section
        AppSpacing.gapXxl,
        Text('사용 이력', style: theme.textTheme.titleSmall),
        AppSpacing.gapSm,
        _UsageHistorySection(teamId: teamId, songId: song.id),

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

class _UsageHistorySection extends ConsumerWidget {
  final int teamId;
  final int songId;

  const _UsageHistorySection({required this.teamId, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usagesAsync =
        ref.watch(songUsagesProvider((teamId: teamId, songId: songId)));

    return usagesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => Text(
        '사용 이력을 불러올 수 없어요',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (usages) {
        if (usages.isEmpty) {
          return Text(
            '아직 사용된 콘티가 없어요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Column(
          children: usages.map((usage) {
            final dateStr = DateFormat('yyyy.MM.dd').format(usage.usedAt);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ContiCard(
                onTap: () => context.push(
                    '/teams/$teamId/setlists/${usage.setlistId}'),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.queue_music_rounded,
                        size: 20, color: theme.colorScheme.primary),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Text(
                        usage.setlistTitle,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (usage.usedKey != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          usage.usedKey!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppSpacing.hGapSm,
                    ],
                    Text(
                      dateStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
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
        AppSpacing.gapXs,
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
      borderRadius: AppRadius.lg,
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

class _ArrangementsTab extends ConsumerWidget {
  final SongDetailResponse song;
  final int teamId;

  const _ArrangementsTab({required this.song, required this.teamId});

  Future<void> _deleteArrangement(
      BuildContext context, WidgetRef ref, int songId, int arrangementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('편곡 삭제'),
        content: const Text('이 편곡을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      final response = await api.delete(
        '/teams/$teamId/songs/$songId/arrangements/$arrangementId',
      );
      if (response.success) {
        ref.invalidate(
            songDetailProvider((teamId: teamId, songId: songId)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response.error?.message ?? '삭제하지 못했어요')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final arrangements = song.arrangements;

    if (arrangements.isEmpty) {
      return const Center(child: Text('아직 편곡 정보가 없어요'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: arrangements.length,
      itemBuilder: (context, index) {
        final arr = arrangements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ContiCard(
            onTap: () => context.push(
              '/teams/$teamId/songs/${song.id}/arrangements/${arr.id}/edit',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        arr.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (arr.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          '기본',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!arr.isDefault)
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.error),
                        onPressed: () => _deleteArrangement(
                            context, ref, song.id, arr.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                AppSpacing.gapSm,
                Wrap(
                  spacing: AppSpacing.lg,
                  children: [
                    if (arr.songKey != null)
                      _ArrangementChip(label: 'Key', value: arr.songKey!),
                    if (arr.bpm != null)
                      _ArrangementChip(label: 'BPM', value: '${arr.bpm}'),
                    if (arr.meter != null)
                      _ArrangementChip(label: '박자', value: arr.meter!),
                    if (arr.durationMinutes != null)
                      _ArrangementChip(
                          label: '시간', value: '${arr.durationMinutes}분'),
                  ],
                ),
                if (arr.description != null &&
                    arr.description!.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Text(
                    arr.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (arr.sections.isNotEmpty) ...[
                  AppSpacing.gapMd,
                  Text(
                    '섹션 ${arr.sections.length}개',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArrangementChip extends StatelessWidget {
  final String label;
  final String value;

  const _ArrangementChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

