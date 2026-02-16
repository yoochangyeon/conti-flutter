import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/song_stats.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_skeleton.dart';
import '../../widgets/conti_error_state.dart';

class SongStatsScreen extends ConsumerWidget {
  final int teamId;

  const SongStatsScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topSongsAsync = ref.watch(topSongsProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('곡 사용 통계')),
      body: topSongsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 72),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(topSongsProvider(teamId)),
        ),
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('사용 통계가 없습니다.'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Summary card
              _SummaryCard(songs: songs),
              AppSpacing.gapXxl,

              // Bar chart
              Text('Top 10 사용 빈도', style: theme.textTheme.titleMedium),
              AppSpacing.gapMd,
              _UsageBarChart(songs: songs.take(10).toList()),
              AppSpacing.gapXxl,

              // Key distribution
              if (songs.any((s) => s.originalKey != null)) ...[
                Text('키 분포', style: theme.textTheme.titleMedium),
                AppSpacing.gapMd,
                _KeyDistributionChart(songs: songs),
                AppSpacing.gapXxl,
              ],

              // Full ranked list
              Text('전체 순위', style: theme.textTheme.titleMedium),
              AppSpacing.gapMd,
              ...songs.asMap().entries.map(
                    (entry) => _RankedSongTile(
                      rank: entry.key + 1,
                      song: entry.value,
                      maxCount: songs.first.usageCount,
                      teamId: teamId,
                    ),
                  ),
              AppSpacing.gapHuge,
            ],
          );
        },
      ),
    );
  }
}

// --- Summary Card ---

class _SummaryCard extends StatelessWidget {
  final List<TopSongResponse> songs;

  const _SummaryCard({required this.songs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalUsage = songs.fold<int>(0, (sum, s) => sum + s.usageCount);
    final uniqueSongs = songs.length;

    return ContiCard(
      borderGradient: AppTheme.primaryGradient,
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.library_music_rounded,
              label: '사용된 곡',
              value: '$uniqueSongs곡',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons.repeat_rounded,
              label: '총 사용 횟수',
              value: '$totalUsage회',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

// --- Horizontal Bar Chart ---

class _UsageBarChart extends StatelessWidget {
  final List<TopSongResponse> songs;

  const _UsageBarChart({required this.songs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount =
        songs.isEmpty ? 1 : songs.map((s) => s.usageCount).reduce((a, b) => a > b ? a : b);

    return ContiCard(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      child: SizedBox(
        height: songs.length * 44.0 + 16,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCount.toDouble() * 1.15,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final song = songs[group.x.toInt()];
                  return BarTooltipItem(
                    '${song.title}\n${song.usageCount}회',
                    theme.textTheme.labelSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 16,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= songs.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${songs[idx].usageCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 100,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= songs.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _truncate(songs[idx].title, 10),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              drawHorizontalLine: false,
              getDrawingVerticalLine: (_) => FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
                strokeWidth: 1,
              ),
            ),
            barGroups: songs.asMap().entries.map((entry) {
              final i = entry.key;
              final song = entry.value;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: song.usageCount.toDouble(),
                    width: 20,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.7 + 0.3 * (1 - i / songs.length)),
                        AppTheme.secondaryColor.withValues(alpha: 0.7 + 0.3 * (1 - i / songs.length)),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
            rotationQuarterTurns: 1,
          ),
        ),
      ),
    );
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen - 1)}…';
  }
}

// --- Key Distribution Pie Chart ---

class _KeyDistributionChart extends StatelessWidget {
  final List<TopSongResponse> songs;

  const _KeyDistributionChart({required this.songs});

  static const _keyColors = [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    AppTheme.tertiaryColor,
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFFCDDC39),
    Color(0xFF3F51B5),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyMap = <String, int>{};
    for (final song in songs) {
      final key = song.originalKey ?? '미지정';
      keyMap[key] = (keyMap[key] ?? 0) + song.usageCount;
    }
    final entries = keyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return ContiCard(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: entries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final pct = total > 0 ? (e.value / total * 100) : 0.0;
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: pct >= 8 ? '${pct.round()}%' : '',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    color: _keyColors[i % _keyColors.length],
                    radius: 50,
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
            children: entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _keyColors[i % _keyColors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.key} (${e.value})',
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

// --- Ranked Song List Tile ---

class _RankedSongTile extends StatelessWidget {
  final int rank;
  final TopSongResponse song;
  final int maxCount;
  final int teamId;

  const _RankedSongTile({
    required this.rank,
    required this.song,
    required this.maxCount,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = maxCount > 0 ? song.usageCount / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContiCard(
        onTap: () => context.push('/teams/$teamId/songs/${song.songId}'),
        child: Column(
          children: [
            Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: rank <= 3 ? AppTheme.primaryGradient : null,
                    color: rank > 3
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: rank <= 3
                            ? Colors.white
                            : theme.colorScheme.primary,
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
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.artist != null)
                        Text(
                          song.artist!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Key badge
                if (song.originalKey != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary
                          .withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      song.originalKey!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppSpacing.hGapSm,
                ],
                // Usage count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${song.usageCount}회',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (song.lastUsedAt != null)
                      Text(
                        song.lastUsedAt!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            AppSpacing.gapSm,
            // Usage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(
                    AppTheme.secondaryColor,
                    AppTheme.primaryColor,
                    ratio,
                  )!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
