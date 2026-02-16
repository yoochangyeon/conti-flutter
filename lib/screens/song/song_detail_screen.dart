import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/models/song.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: '통계'),
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
            return const Center(child: Text('곡을 찾을 수 없습니다'));
          }
          return TabBarView(
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
              _StatsTab(teamId: widget.teamId, songId: widget.songId),
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
      final response = await api.delete('/teams/${widget.teamId}/songs/${widget.songId}');
      if (context.mounted) {
        if (response.success) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error?.message ?? '삭제에 실패했습니다')),
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
        content: const Text('이 파일을 삭제하시겠습니까?'),
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
                  Text(response.error?.message ?? '삭제에 실패했습니다')),
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
        title: const Text('악보 파일 URL 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: '파일 이름 *', hintText: '예: 코드 악보'),
            ),
            const SizedBox(height: 12),
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
                  Text(response.error?.message ?? '추가에 실패했습니다')),
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
            '등록된 파일이 없습니다',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ...song.files.map<Widget>((file) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LinkCard(
                icon: Icons.insert_drive_file_rounded,
                iconColor: AppTheme.tertiaryColor,
                title: file.fileName,
                subtitle: file.fileType ?? '파일',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded, size: 20),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _deleteFile(context, ref, file.id),
                      child: Icon(Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.error
                              .withValues(alpha: 0.7)),
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
        '사용 이력을 불러올 수 없습니다',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (usages) {
        if (usages.isEmpty) {
          return Text(
            '아직 사용된 콘티가 없습니다',
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
                          color: theme.colorScheme.tertiary
                              .withValues(alpha: 0.12),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          usage.usedKey!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
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
        content: const Text('이 편곡을 삭제하시겠습니까?'),
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
                  Text(response.error?.message ?? '삭제에 실패했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final arrangements = song.arrangements;

    if (arrangements.isEmpty) {
      return const Center(child: Text('편곡 정보가 없습니다.'));
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
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          '기본',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!arr.isDefault)
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.error.withValues(alpha: 0.7)),
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

// --- Stats Tab ---

class _StatsTab extends ConsumerWidget {
  final int teamId;
  final int songId;

  const _StatsTab({required this.teamId, required this.songId});

  static const _keyColors = [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    AppTheme.tertiaryColor,
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync =
        ref.watch(songStatsProvider((teamId: teamId, songId: songId)));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ContiErrorState(
        onRetry: () => ref
            .invalidate(songStatsProvider((teamId: teamId, songId: songId))),
      ),
      data: (stats) {
        if (stats == null || stats.totalUsageCount == 0) {
          return Center(
            child: Text(
              '통계 데이터가 없습니다',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Summary
            ContiCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(
                    icon: Icons.repeat_rounded,
                    label: '총 사용',
                    value: '${stats.totalUsageCount}회',
                  ),
                  if (stats.lastUsedAt != null)
                    _InfoItem(
                      icon: Icons.calendar_today_rounded,
                      label: '마지막 사용',
                      value: stats.lastUsedAt!,
                    ),
                ],
              ),
            ),

            // Monthly usage chart
            if (stats.monthlyUsages.isNotEmpty) ...[
              AppSpacing.gapXxl,
              Text('월별 사용 추이', style: theme.textTheme.titleMedium),
              AppSpacing.gapMd,
              _MonthlyChart(usages: stats.monthlyUsages),
            ],

            // Key distribution
            if (stats.keyDistribution.isNotEmpty) ...[
              AppSpacing.gapXxl,
              Text('키 분포', style: theme.textTheme.titleMedium),
              AppSpacing.gapMd,
              _KeyPieChart(
                  keys: stats.keyDistribution, colors: _keyColors),
            ],

            // Leader breakdown
            if (stats.leaderBreakdown.isNotEmpty) ...[
              AppSpacing.gapXxl,
              Text('리더별 사용', style: theme.textTheme.titleMedium),
              AppSpacing.gapMd,
              ...stats.leaderBreakdown.map((leader) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ContiCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded,
                              size: 20,
                              color: theme.colorScheme.primary),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Text(leader.leaderName,
                                style: theme.textTheme.bodyMedium),
                          ),
                          Text(
                            '${leader.count}회',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],

            AppSpacing.gapHuge,
          ],
        );
      },
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<MonthlyUsage> usages;

  const _MonthlyChart({required this.usages});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<MonthlyUsage>.from(usages)
      ..sort((a, b) {
        final cmp = a.year.compareTo(b.year);
        return cmp != 0 ? cmp : a.month.compareTo(b.month);
      });
    final maxCount = sorted.map((u) => u.count).reduce((a, b) => a > b ? a : b);

    return ContiCard(
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCount.toDouble() * 1.2,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    if (value != value.roundToDouble()) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '${value.toInt()}',
                      style: theme.textTheme.labelSmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sorted.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${sorted[idx].month}월',
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
                strokeWidth: 1,
              ),
            ),
            barGroups: sorted.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.count.toDouble(),
                    width: 16,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                    gradient: AppTheme.primaryGradient,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _KeyPieChart extends StatelessWidget {
  final List<KeyUsage> keys;
  final List<Color> colors;

  const _KeyPieChart({required this.keys, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = keys.fold<int>(0, (sum, k) => sum + k.count);

    return ContiCard(
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: keys.asMap().entries.map((entry) {
                  final i = entry.key;
                  final k = entry.value;
                  final pct = total > 0 ? (k.count / total * 100) : 0.0;
                  return PieChartSectionData(
                    value: k.count.toDouble(),
                    title: pct >= 10 ? '${pct.round()}%' : '',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    color: colors[i % colors.length],
                    radius: 44,
                  );
                }).toList(),
              ),
            ),
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: keys.asMap().entries.map((entry) {
              final i = entry.key;
              final k = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${k.key} (${k.count})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
