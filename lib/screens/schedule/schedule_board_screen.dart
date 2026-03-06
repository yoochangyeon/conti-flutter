import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/schedule.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

class ScheduleBoardScreen extends ConsumerWidget {
  final int teamId;
  final int setlistId;

  const ScheduleBoardScreen({
    super.key,
    required this.teamId,
    required this.setlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(
        setlistSchedulesProvider((teamId: teamId, setlistId: setlistId)));
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final theme = Theme.of(context);

    // Check if current user is admin
    final authState = ref.watch(authProvider);
    final isAdmin = membersAsync.whenOrNull(
          data: (members) => members
              .where((m) => m.userId == authState.user?.id)
              .any((m) => m.isAdmin),
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('스케줄 보드')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isAdmin)
            FloatingActionButton.small(
              heroTag: 'signup',
              onPressed: () => _showSignupDialog(context, ref),
              tooltip: '참여 신청',
              child: const Icon(Icons.how_to_reg_rounded),
            ),
          if (!isAdmin) AppSpacing.gapSm,
          if (isAdmin)
            FloatingActionButton.extended(
              heroTag: 'assign',
              onPressed: () => context.push(
                  '/teams/$teamId/setlists/$setlistId/schedule/assign'),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('봉사 배정'),
            ),
        ],
      ),
      body: schedulesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 72),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(setlistSchedulesProvider(
              (teamId: teamId, setlistId: setlistId))),
        ),
        data: (schedules) {
          if (schedules.isEmpty) {
            return ContiEmptyState(
              icon: Icons.event_available_rounded,
              title: '아직 배정된 멤버가 없어요',
              subtitle: isAdmin ? '멤버를 배정해 주세요' : null,
            );
          }

          // Group by position
          final grouped = <String, List<ServiceScheduleResponse>>{};
          for (final s in schedules) {
            grouped.putIfAbsent(s.positionDisplayName, () => []).add(s);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(setlistSchedulesProvider(
                (teamId: teamId, setlistId: setlistId))),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm, top: AppSpacing.md),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...entry.value.map((schedule) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ScheduleMemberTile(
                            schedule: schedule,
                            teamId: teamId,
                            isAdmin: isAdmin,
                            onRemove: isAdmin
                                ? () =>
                                    _removeSchedule(context, ref, schedule.id)
                                : null,
                          ),
                        )),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeSchedule(
      BuildContext context, WidgetRef ref, int scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('배정 취소'),
        content: const Text('이 멤버의 배정을 취소할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      final response = await api.delete('/teams/$teamId/schedules/$scheduleId');
      if (response.success) {
        ref.invalidate(setlistSchedulesProvider(
            (teamId: teamId, setlistId: setlistId)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error?.message ?? '배정 취소에 실패했어요')),
        );
      }
    }
  }

  Future<void> _showSignupDialog(BuildContext context, WidgetRef ref) async {
    final positions = MemberPosition.values;
    final selected = await showDialog<MemberPosition>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('참여 신청'),
        children: positions.map((p) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, p),
            child: Text(p.displayName),
          );
        }).toList(),
      ),
    );

    if (selected == null || !context.mounted) return;

    final api = ref.read(apiClientProvider);
    final response = await api.post<ServiceScheduleResponse>(
      '/teams/$teamId/setlists/$setlistId/schedules/signup',
      data: {'position': selected.jsonValue},
      fromJson: (data) =>
          ServiceScheduleResponse.fromJson(data as Map<String, dynamic>),
    );

    if (!context.mounted) return;

    if (response.success) {
      ref.invalidate(setlistSchedulesProvider(
          (teamId: teamId, setlistId: setlistId)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.displayName}으로 참여 신청했어요')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response.error?.message ?? '참여 신청에 실패했어요')),
      );
    }
  }
}

class _ScheduleMemberTile extends StatelessWidget {
  final ServiceScheduleResponse schedule;
  final int teamId;
  final bool isAdmin;
  final VoidCallback? onRemove;

  const _ScheduleMemberTile({
    required this.schedule,
    required this.teamId,
    required this.isAdmin,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(schedule.status);

    return ContiCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      borderRadius: 16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: schedule.profileImage != null
                ? NetworkImage(schedule.profileImage!)
                : null,
            child: schedule.profileImage == null
                ? Text(
                    schedule.memberName.isNotEmpty
                        ? schedule.memberName[0]
                        : '?',
                    style: const TextStyle(color: AppColors.primary))
                : null,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.memberName, style: theme.textTheme.titleSmall),
                if (schedule.declinedReason != null &&
                    schedule.status == 'DECLINED')
                  Text(
                    schedule.declinedReason!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(
              schedule.statusDisplayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isAdmin && onRemove != null)
            IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.error),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return AppColors.success;
      case 'DECLINED':
        return AppColors.error;
      case 'PENDING':
      default:
        return AppColors.gray500;
    }
  }
}
