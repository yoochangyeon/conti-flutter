import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_skeleton.dart';

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
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(
              child: Text('사용 통계가 없습니다.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ContiCard(
                  onTap: () => context.push(
                    '/teams/$teamId/songs/${song.songId}',
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
