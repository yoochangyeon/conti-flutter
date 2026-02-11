import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/user.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTeams = ref.watch(userTeamsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'Conti',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: userTeams.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 3, itemHeight: 88),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (teams) {
          if (teams.isEmpty) {
            return ContiEmptyState(
              icon: Icons.group_outlined,
              title: '아직 참여한 팀이 없습니다',
              subtitle: '새 팀을 만들거나 초대 코드로 참여하세요',
              actionLabel: '새 팀 만들기',
              onAction: () => context.push('/teams/create'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userTeamsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('팀'),
      ),
    );
  }

  void _showTeamActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
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
      ),
    );
  }
}

// Color palette for team avatars based on name hash
const _teamColors = [
  [Color(0xFF7C5CFC), Color(0xFF5B8DEF)],
  [Color(0xFFFF6B9D), Color(0xFFFF9A76)],
  [Color(0xFF5B8DEF), Color(0xFF56CCF2)],
  [Color(0xFFFF9A76), Color(0xFFFFC857)],
  [Color(0xFF56CCF2), Color(0xFF7C5CFC)],
];

class _TeamCard extends StatelessWidget {
  final UserTeamResponse team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPair = _teamColors[team.teamName.hashCode.abs() % _teamColors.length];
    final gradient = LinearGradient(
      colors: colorPair,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ContiCard(
        onTap: () => context.push('/teams/${team.teamId}'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Gradient avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: AppRadius.borderMd,
              ),
              child: Center(
                child: Text(
                  team.teamName.isNotEmpty ? team.teamName[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.teamName,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: team.isAdmin
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      team.role,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: team.isAdmin
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
