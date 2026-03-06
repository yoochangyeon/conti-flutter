import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

class SetlistListScreen extends ConsumerStatefulWidget {
  final int teamId;

  const SetlistListScreen({super.key, required this.teamId});

  @override
  ConsumerState<SetlistListScreen> createState() => _SetlistListScreenState();
}

class _SetlistListScreenState extends ConsumerState<SetlistListScreen> {
  String? _worshipType;

  @override
  Widget build(BuildContext context) {
    final params = SetlistListParams(
        teamId: widget.teamId, worshipType: _worshipType);
    final setlistsAsync = ref.watch(setlistsProvider(params));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd (E)', 'ko');

    return Scaffold(
      appBar: AppBar(
        title: const Text('콘티'),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _worshipType != null
                  ? theme.colorScheme.primary
                  : null,
            ),
            onSelected: (v) => setState(() => _worshipType = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('전체')),
              const PopupMenuItem(
                  value: '주일 1부 예배', child: Text('주일 1부 예배')),
              const PopupMenuItem(
                  value: '주일 2부 예배', child: Text('주일 2부 예배')),
              const PopupMenuItem(value: '수요 예배', child: Text('수요 예배')),
              const PopupMenuItem(
                  value: '금요 기도회', child: Text('금요 기도회')),
              const PopupMenuItem(value: '청년 예배', child: Text('청년 예배')),
            ],
          ),
        ],
      ),
      body: setlistsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 80),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(setlistsProvider(params)),
        ),
        data: (paged) {
          if (paged.content.isEmpty) {
            return ContiEmptyState(
              icon: Icons.queue_music_rounded,
              title: '아직 콘티가 없어요',
              subtitle: '새 콘티를 만들어 예배를 준비해 보세요',
              actionLabel: '콘티 만들기',
              onAction: () =>
                  context.push('/teams/${widget.teamId}/setlists/create'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(setlistsProvider(params)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: paged.content.length,
              itemBuilder: (context, index) {
                final setlist = paged.content[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ContiCard(
                    onTap: () => context.push(
                        '/teams/${widget.teamId}/setlists/${setlist.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                setlist.displayTitle,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Text(
                                '${setlist.songCount}곡',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapSm,
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14,
                                color:
                                    theme.colorScheme.onSurfaceVariant),
                            AppSpacing.hGapXs,
                            Text(
                              dateFormat.format(setlist.worshipDate),
                              style: theme.textTheme.bodySmall,
                            ),
                            if (setlist.worshipType != null) ...[
                              AppSpacing.hGapMd,
                              Container(
                                padding: AppPadding.paddingBadge,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: Text(
                                  setlist.worshipTypeDisplayName ??
                                      setlist.worshipType!,
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/teams/${widget.teamId}/setlists/create'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
