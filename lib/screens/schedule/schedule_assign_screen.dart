import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/schedule.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_gradient_button.dart';

class ScheduleAssignScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int setlistId;

  const ScheduleAssignScreen({
    super.key,
    required this.teamId,
    required this.setlistId,
  });

  @override
  ConsumerState<ScheduleAssignScreen> createState() =>
      _ScheduleAssignScreenState();
}

class _ScheduleAssignScreenState extends ConsumerState<ScheduleAssignScreen> {
  MemberPosition? _selectedPosition;
  final Map<int, String> _assignments = {}; // teamMemberId -> position name
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('봉사 배정')),
      body: Column(
        children: [
          // Position selector
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('포지션을 선택해 주세요', style: theme.textTheme.titleSmall),
                AppSpacing.gapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 8,
                  children: MemberPosition.values.map((pos) {
                    final isSelected = _selectedPosition == pos;
                    return FilterChip(
                      label: Text(pos.displayName),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedPosition = pos),
                      selectedColor: AppColors.primaryLight,
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Divider(),

          // Members list
          Expanded(
            child: _selectedPosition == null
                ? Center(
                    child: Text('포지션을 먼저 선택해 주세요',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray500)))
                : membersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('오류가 발생했어요: $e',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.gray600))),
                    data: (members) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final isAssigned = _assignments.containsKey(
                                  member.memberId) &&
                              _assignments[member.memberId] ==
                                  _selectedPosition!.jsonValue;
                          final hasPositionMatch = member.positions.any(
                              (p) => p.position == _selectedPosition!.jsonValue);

                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm),
                            child: ContiCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm),
                              borderRadius: 16,
                              onTap: () {
                                setState(() {
                                  if (isAssigned) {
                                    _assignments.remove(member.memberId);
                                  } else {
                                    _assignments[member.memberId] =
                                        _selectedPosition!.jsonValue;
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryLight,
                                    backgroundImage:
                                        member.profileImage != null
                                            ? NetworkImage(
                                                member.profileImage!)
                                            : null,
                                    child: member.profileImage == null
                                        ? Text(
                                            member.userName.isNotEmpty
                                                ? member.userName[0]
                                                : '?',
                                            style: const TextStyle(
                                                color: AppColors.primary))
                                        : null,
                                  ),
                                  AppSpacing.hGapMd,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(member.userName,
                                            style:
                                                theme.textTheme.titleSmall),
                                        if (member.positions.isNotEmpty)
                                          Text(
                                            member.positions
                                                .map((p) => p.displayName)
                                                .join(', '),
                                            style:
                                                theme.textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (hasPositionMatch)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: AppSpacing.sm),
                                      child: Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  Checkbox(
                                    value: isAssigned,
                                    onChanged: (_) {
                                      setState(() {
                                        if (isAssigned) {
                                          _assignments
                                              .remove(member.memberId);
                                        } else {
                                          _assignments[member.memberId] =
                                              _selectedPosition!.jsonValue;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Save button
          if (_assignments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_assignments.length}명 배정 예정이에요',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  AppSpacing.gapSm,
                  SizedBox(
                    width: double.infinity,
                    child: ContiGradientButton(
                      label: '배정하기',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final api = ref.read(apiClientProvider);
    final schedules = _assignments.entries
        .map((e) => {'teamMemberId': e.key, 'position': e.value})
        .toList();
    final response = await api.post(
      '/teams/${widget.teamId}/setlists/${widget.setlistId}/schedules',
      data: {'schedules': schedules},
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (response.success) {
        ref.invalidate(setlistSchedulesProvider(
            (teamId: widget.teamId, setlistId: widget.setlistId)));
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('멤버가 배정되었어요')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.error?.message ?? '배정에 실패했어요')),
        );
      }
    }
  }
}
