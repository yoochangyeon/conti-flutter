import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/animated/conti_fade_in.dart';
import '../../widgets/animated/conti_scale_tap.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

/// Dashboard tab shown as the first tab in TeamShellScreen.
class TeamDashboardTab extends ConsumerWidget {
  final int teamId;

  const TeamDashboardTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: teamAsync.when(
          data: (team) => Text(team?.name ?? 'Conti'),
          loading: () => const Text('Conti'),
          error: (e, st) => const Text('Conti'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 4, itemHeight: 80),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
        ),
        data: (team) {
          if (team == null) {
            return const Center(child: Text('팀을 찾을 수 없어요'));
          }
          return ContiFadeIn(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(teamDetailProvider(teamId));
                ref.invalidate(setlistsProvider(SetlistListParams(teamId: teamId, setlistType: 'CUE_SHEET')));
                ref.invalidate(songsProvider(SongListParams(teamId: teamId)));
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Team description
                  if (team.description != null &&
                      team.description!.isNotEmpty) ...[
                    Text(
                      team.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    AppSpacing.gapLg,
                  ],

                  // Quick action grid (2x2 cards)
                  _QuickActionGrid(teamId: teamId),

                  AppSpacing.gapXxl,

                  // Upcoming setlists section
                  _UpcomingSetlists(teamId: teamId),

                  AppSpacing.gapXxl,

                  // Recent songs section
                  _RecentSongs(teamId: teamId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 2x2 grid of quick action cards with distinct visual styles.
class _QuickActionGrid extends StatelessWidget {
  final int teamId;
  const _QuickActionGrid({required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.music_note_rounded,
                label: '찬양 DB',
                color: AppColors.purple,
                bgColor: const Color(0xFFF3EEFF),
                onTap: () => context.push('/teams/$teamId/songs'),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _QuickActionCard(
                icon: Icons.queue_music_rounded,
                label: '새 콘티',
                color: AppColors.pink,
                bgColor: const Color(0xFFFFEBEB),
                onTap: () => context.push('/teams/$teamId/contis/create'),
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.people_rounded,
                label: '팀원 관리',
                color: AppColors.primary,
                bgColor: AppColors.primaryLight,
                onTap: () => context.push('/teams/$teamId/members'),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _QuickActionCard(
                icon: Icons.campaign_rounded,
                label: '공지사항',
                color: AppColors.orange,
                bgColor: AppColors.warningLight,
                onTap: () => context.push('/teams/$teamId/notices'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ContiScaleTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppRadius.borderLg,
          border: isDark
              ? Border.all(color: AppColors.darkDivider, width: 0.5)
              : null,
          boxShadow: AppShadow.card(isDark),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLg,
          child: Padding(
            padding: AppPadding.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? color.withValues(alpha: 0.15) : bgColor,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                AppSpacing.gapMd,
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the upcoming setlists in a horizontal scroll.
class _UpcomingSetlists extends ConsumerWidget {
  final int teamId;
  const _UpcomingSetlists({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setlistsAsync = ref.watch(setlistsProvider(SetlistListParams(teamId: teamId, setlistType: 'CUE_SHEET')));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('다가오는 예배',
                  style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () => context.push('/teams/$teamId/cuesheets'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
        ),
        setlistsAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => ContiCard(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('콘티를 불러오지 못했어요',
                  style: theme.textTheme.bodySmall),
            ),
          ),
          data: (pagedData) {
            final setlists = pagedData.content;
            if (setlists.isEmpty) {
              return ContiCard(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceHigh
                            : AppColors.gray100,
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: const Icon(Icons.queue_music_outlined,
                          color: AppColors.gray400, size: 22),
                    ),
                    AppSpacing.hGapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('아직 예배 큐시트가 없어요',
                              style: theme.textTheme.titleSmall),
                          AppSpacing.gapXxs,
                          Text('예배 순서를 만들어 보세요',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.gray500)),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.push('/teams/$teamId/cuesheets/create'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('만들기'),
                    ),
                  ],
                ),
              );
            }

            // Show up to 3 upcoming setlists
            final upcoming = setlists.take(3).toList();
            return Column(
              children: upcoming.map((setlist) {
                final dateStr = DateFormat('M/d (E)', 'ko')
                    .format(setlist.worshipDate);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ContiCard(
                    onTap: () => context.push(
                        '/teams/$teamId/cuesheets/${setlist.id}'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Date badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Center(
                            child: Text(
                              dateStr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                height: 1.2,
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
                                setlist.displayTitle,
                                style: theme.textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppSpacing.gapXxs,
                              Text(
                                '${setlist.songCount}곡',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.gray500),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.gray400, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Shows recent songs in a horizontal scroll.
class _RecentSongs extends ConsumerWidget {
  final int teamId;
  const _RecentSongs({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync =
        ref.watch(songsProvider(SongListParams(teamId: teamId)));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최근 추가된 찬양',
                  style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () => context.push('/teams/$teamId/songs'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
        ),
        songsAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => const SizedBox.shrink(),
          data: (pagedData) {
            final songs = pagedData.content;
            if (songs.isEmpty) {
              return ContiCard(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceHigh
                            : AppColors.gray100,
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: const Icon(Icons.music_note_outlined,
                          color: AppColors.gray400, size: 22),
                    ),
                    AppSpacing.hGapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('아직 등록된 찬양이 없어요',
                              style: theme.textTheme.titleSmall),
                          AppSpacing.gapXxs,
                          Text('찬양을 추가해 보세요',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.gray500)),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.push('/teams/$teamId/songs/create'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('추가하기'),
                    ),
                  ],
                ),
              );
            }

            // Horizontal scroll of recent songs (last 5)
            final recent = songs.take(5).toList();
            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, _) => AppSpacing.hGapMd,
                itemBuilder: (context, index) {
                  final song = recent[index];
                  final color = AppColors.accentPalette[
                      index % AppColors.accentPalette.length];
                  return ContiScaleTap(
                    onTap: () => context.push(
                        '/teams/$teamId/songs/${song.id}'),
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? color.withValues(alpha: 0.15)
                                  : color.withValues(alpha: 0.1),
                              borderRadius: AppRadius.borderLg,
                            ),
                            child: Center(
                              child: Text(
                                song.title.isNotEmpty
                                    ? song.title[0]
                                    : '?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Text(
                            song.title,
                            style: theme.textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
