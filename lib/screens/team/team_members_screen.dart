import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/team.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (members) {
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
                    subtitle: Text(member.role),
                    trailing: member.isAdmin
                        ? Chip(
                            label: const Text('관리자'),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () => _showMemberOptions(context, ref, member),
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
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(member.isAdmin ? 'VIEWER로 변경' : 'ADMIN으로 변경'),
              onTap: () async {
                Navigator.pop(context);
                final api = ref.read(apiClientProvider);
                final newRole = member.isAdmin ? 'VIEWER' : 'ADMIN';
                await api.patch(
                  '/teams/$teamId/members/${member.memberId}/role',
                  data: {'role': newRole},
                );
                ref.invalidate(teamMembersProvider(teamId));
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
                  await api.delete('/teams/$teamId/members/${member.memberId}');
                  ref.invalidate(teamMembersProvider(teamId));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
