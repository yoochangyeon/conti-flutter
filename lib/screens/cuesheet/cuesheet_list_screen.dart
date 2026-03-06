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

/// List screen for cue sheets (worship service order).
/// Shows CUE_SHEET type setlists filtered from the same setlist API.
class CueSheetListScreen extends ConsumerStatefulWidget {
  final int teamId;

  const CueSheetListScreen({super.key, required this.teamId});

  @override
  ConsumerState<CueSheetListScreen> createState() =>
      _CueSheetListScreenState();
}

class _CueSheetListScreenState extends ConsumerState<CueSheetListScreen> {
  String? _worshipType;

  @override
  Widget build(BuildContext context) {
    final params = SetlistListParams(
      teamId: widget.teamId,
      worshipType: _worshipType,
      setlistType: 'CUE_SHEET',
    );
    final cueSheetAsync = ref.watch(setlistsProvider(params));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd (E)', 'ko');

    return Scaffold(
      appBar: AppBar(
        title: const Text('큐시트'),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list_rounded,
              color:
                  _worshipType != null ? theme.colorScheme.primary : null,
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
      body: cueSheetAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 88),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(setlistsProvider(params)),
        ),
        data: (paged) {
          if (paged.content.isEmpty) {
            return ContiEmptyState(
              icon: Icons.list_alt_rounded,
              title: '아직 큐시트가 없어요',
              subtitle: '예배 순서를 만들어 보세요',
              actionLabel: '큐시트 만들기',
              onAction: () =>
                  context.push('/teams/${widget.teamId}/cuesheets/create'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(setlistsProvider(params)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: paged.content.length,
              itemBuilder: (context, index) {
                final cueSheet = paged.content[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ContiCard(
                    onTap: () => context.push(
                        '/teams/${widget.teamId}/cuesheets/${cueSheet.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with item count badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cueSheet.displayTitle,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Text(
                                '${cueSheet.songCount}개 항목',
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
                        // Date, worship type, and linked conti badge
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 14,
                                    color: theme
                                        .colorScheme.onSurfaceVariant),
                                AppSpacing.hGapXs,
                                Text(
                                  dateFormat.format(cueSheet.worshipDate),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (cueSheet.worshipType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: Text(
                                  cueSheet.worshipTypeDisplayName ??
                                      cueSheet.worshipType!,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (cueSheet.contiId != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.link_rounded,
                                        size: 12,
                                        color:
                                            theme.colorScheme.primary),
                                    AppSpacing.hGapXs,
                                    Text(
                                      '콘티 연결됨',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
            context.push('/teams/${widget.teamId}/cuesheets/create'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
