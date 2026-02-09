import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  final int teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: teamAsync.when(
          data: (team) => Text(team?.name ?? '팀'),
          loading: () => const Text('팀'),
          error: (_, __) => const Text('팀'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/teams/$teamId/members'),
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (team) {
          if (team == null) return const Center(child: Text('팀을 찾을 수 없습니다'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (team.description != null && team.description!.isNotEmpty) ...[
                Text(team.description!, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
              ],
              // Invite code
              Card(
                child: ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('초대 코드'),
                  subtitle: Text(team.inviteCode),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: team.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대 코드가 복사되었습니다')),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Navigation cards
              _MenuCard(
                icon: Icons.music_note,
                title: '찬양 DB',
                subtitle: '찬양곡 관리',
                onTap: () => context.push('/teams/$teamId/songs'),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.queue_music,
                title: '콘티',
                subtitle: '세트리스트 관리',
                onTap: () => context.push('/teams/$teamId/setlists'),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.people,
                title: '팀원 관리',
                subtitle: '멤버 초대 및 역할 관리',
                onTap: () => context.push('/teams/$teamId/members'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
