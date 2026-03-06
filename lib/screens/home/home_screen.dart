import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/user.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTeams = ref.watch(userTeamsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conti',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          _NotificationBell(),
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
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(userTeamsProvider),
        ),
        data: (teams) {
          if (teams.isEmpty) {
            return ContiEmptyState(
              icon: Icons.group_outlined,
              title: '아직 참여한 팀이 없어요',
              subtitle: '새 팀을 만들거나 초대 코드로 참여해 보세요',
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
                subtitle: const Text('직접 팀을 만들어 보세요'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/teams/create');
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add_outlined),
                title: const Text('팀 참여하기'),
                subtitle: const Text('초대 코드로 팀에 참여해요'),
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

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount.valueOrNull != null && unreadCount.valueOrNull! > 0,
        label: Text(
          '${unreadCount.valueOrNull ?? 0}',
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => context.push('/notifications'),
    );
  }
}

// Accent palette for team avatars based on name hash
const _teamAvatarColors = [
  AppColors.primary,
  AppColors.teal,
  AppColors.pink,
  AppColors.orange,
  AppColors.purple,
];

class _TeamCard extends StatelessWidget {
  final UserTeamResponse team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _teamAvatarColors[team.teamName.hashCode.abs() % _teamAvatarColors.length];
    final roleDisplay = AppConstants.roleNames[team.role] ?? team.role;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ContiCard(
        onTap: () => context.push('/teams/${team.teamId}'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Solid color avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: AppRadius.borderMd,
              ),
              child: Center(
                child: Text(
                  team.teamName.isNotEmpty ? team.teamName[0] : '?',
                  style: const TextStyle(
                    color: AppColors.white,
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
                  AppSpacing.gapXs,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: team.isAdmin
                          ? AppColors.primaryLight
                          : AppColors.gray100,
                      borderRadius: AppRadius.borderXs,
                    ),
                    child: Text(
                      roleDisplay,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: team.isAdmin
                            ? AppColors.primary
                            : AppColors.gray600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
