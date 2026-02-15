import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/schedule.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

class MyScheduleScreen extends ConsumerWidget {
  final int teamId;

  const MyScheduleScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(mySchedulesProvider(teamId));

    return Scaffold(
      appBar: AppBar(title: const Text('내 스케줄')),
      body: schedulesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 80),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(mySchedulesProvider(teamId)),
        ),
        data: (schedules) {
          if (schedules.isEmpty) {
            return const ContiEmptyState(
              icon: Icons.event_note_rounded,
              title: '예정된 스케줄이 없습니다',
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(mySchedulesProvider(teamId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _MyScheduleTile(
                    schedule: schedule,
                    teamId: teamId,
                    onRespond: (accept, reason) =>
                        _respond(ref, context, schedule.id, accept, reason),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _respond(WidgetRef ref, BuildContext context, int scheduleId,
      bool accept, String? reason) async {
    final api = ref.read(apiClientProvider);
    final response = await api.patch(
      '/teams/$teamId/schedules/$scheduleId/respond',
      data: {
        'accept': accept,
        if (reason != null) 'declinedReason': reason,
      },
    );
    if (response.success) {
      ref.invalidate(mySchedulesProvider(teamId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? '수락했습니다' : '거절했습니다')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error?.message ?? '요청에 실패했습니다')),
      );
    }
  }
}

class _MyScheduleTile extends StatelessWidget {
  final ServiceScheduleResponse schedule;
  final int teamId;
  final void Function(bool accept, String? reason) onRespond;

  const _MyScheduleTile({
    required this.schedule,
    required this.teamId,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = schedule.status == 'PENDING';

    return ContiCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  schedule.positionDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              _StatusBadge(status: schedule.status, displayName: schedule.statusDisplayName),
            ],
          ),
          AppSpacing.gapSm,
          if (schedule.declinedReason != null &&
              schedule.status == 'DECLINED') ...[
            Text(
              '거절 사유: ${schedule.declinedReason}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
            AppSpacing.gapSm,
          ],
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDeclineDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                          color: theme.colorScheme.error
                              .withValues(alpha: 0.5)),
                    ),
                    child: const Text('거절'),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: FilledButton(
                    onPressed: () => onRespond(true, null),
                    child: const Text('수락'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showDeclineDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('거절 사유'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '사유를 입력하세요 (선택)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRespond(false,
                  controller.text.trim().isEmpty ? null : controller.text.trim());
            },
            child: const Text('거절'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String displayName;

  const _StatusBadge({required this.status, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (status) {
      case 'ACCEPTED':
        color = Colors.green;
        break;
      case 'DECLINED':
        color = theme.colorScheme.error;
        break;
      case 'PENDING':
      default:
        color = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
