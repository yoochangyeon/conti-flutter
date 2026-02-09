import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/user.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTeams = ref.watch(userTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: userTeams.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (teams) {
          if (teams.isEmpty) {
            return _EmptyTeamView();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userTeamsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return _TeamCard(team: team);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeamActions(context),
        icon: const Icon(Icons.add),
        label: const Text('팀'),
      ),
    );
  }

  void _showTeamActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('새 팀 만들기'),
              onTap: () {
                Navigator.pop(context);
                context.push('/teams/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('팀 참여하기'),
              onTap: () {
                Navigator.pop(context);
                context.push('/teams/join');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTeamView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              '아직 참여한 팀이 없습니다',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '새 팀을 만들거나 초대 코드로 참여하세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/teams/create'),
              icon: const Icon(Icons.add),
              label: const Text('새 팀 만들기'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/teams/join'),
              icon: const Icon(Icons.group_add),
              label: const Text('팀 참여하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final UserTeamResponse team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/teams/${team.teamId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  team.teamName.isNotEmpty ? team.teamName[0] : '?',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.teamName, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: team.isAdmin
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        team.role,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: team.isAdmin
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
