import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/team.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

class TeamMembersScreen extends ConsumerWidget {
  final int teamId;

  const TeamMembersScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('팀원 관리')),
      body: membersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 72),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(teamMembersProvider(teamId)),
        ),
        data: (members) {
          if (members.isEmpty) {
            return const ContiEmptyState(
              icon: Icons.people_outline_rounded,
              title: '팀원이 없습니다',
              subtitle: '초대 코드를 공유하여 팀원을 초대하세요',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teamMembersProvider(teamId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: member.profileImage != null
                          ? NetworkImage(member.profileImage!)
                          : null,
                      child: member.profileImage == null
                          ? Text(member.userName.isNotEmpty ? member.userName[0] : '?')
                          : null,
                    ),
                    title: Text(member.userName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.roleDisplayName),
                        if (member.positions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: member.positions.map((p) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.isPrimary
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.15)
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: p.isPrimary
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: p.isPrimary
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    trailing: _buildRoleBadge(theme, member),
                    onTap: () => context.push(
                        '/teams/$teamId/members/${member.memberId}/positions'),
                    onLongPress: () => _showMemberOptions(context, ref, member),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showMemberOptions(BuildContext context, WidgetRef ref, TeamMemberResponse member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(member.userName, style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('역할 변경'),
              onTap: () {
                Navigator.pop(context);
                _showRoleChangeDialog(context, ref, member);
              },
            ),
            ListTile(
              leading: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
              title: Text('멤버 제거', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('멤버 제거'),
                    content: Text('${member.userName}님을 팀에서 제거하시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('제거')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final api = ref.read(apiClientProvider);
                  final response = await api.delete('/teams/$teamId/members/${member.memberId}');
                  if (response.success) {
                    ref.invalidate(teamMembersProvider(teamId));
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.error?.message ?? '멤버 제거에 실패했습니다')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildRoleBadge(ThemeData theme, TeamMemberResponse member) {
    final (color, bgColor, label) = switch (member.role) {
      'ADMIN' => (theme.colorScheme.onPrimaryContainer, theme.colorScheme.primaryContainer, '관리자'),
      'EDITOR' => (theme.colorScheme.onTertiaryContainer, theme.colorScheme.tertiaryContainer, '편집자'),
      'SCHEDULER' => (theme.colorScheme.onSecondaryContainer, theme.colorScheme.secondaryContainer, '스케줄러'),
      _ => (null, null, null),
    };

    if (color == null) return null;

    return Chip(
      label: Text(label!),
      backgroundColor: bgColor,
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }

  void _showRoleChangeDialog(BuildContext context, WidgetRef ref, TeamMemberResponse member) {
    final roles = [
      ('ADMIN', '관리자', '모든 권한'),
      ('EDITOR', '편집자', '곡/콘티 편집, 노트 작성'),
      ('SCHEDULER', '스케줄러', '스케줄 관리'),
      ('VIEWER', '뷰어', '조회만 가능'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${member.userName} 역할 변경'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: roles.map((role) {
              final (value, label, desc) = role;
              final isSelected = member.role == value;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Theme.of(ctx).colorScheme.primary : null,
                ),
                title: Text(label),
                subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onTap: isSelected
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final api = ref.read(apiClientProvider);
                        await api.patch(
                          '/teams/$teamId/members/${member.memberId}',
                          data: {'role': value},
                        );
                        ref.invalidate(teamMembersProvider(teamId));
                      },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}
