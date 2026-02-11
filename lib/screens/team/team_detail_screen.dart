import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_skeleton.dart';

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
          error: (_, _) => const Text('팀'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            onPressed: () => context.push('/teams/$teamId/members'),
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 4, itemHeight: 80),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (team) {
          if (team == null) {
            return const Center(child: Text('팀을 찾을 수 없습니다'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (team.description != null &&
                  team.description!.isNotEmpty) ...[
                Text(
                  team.description!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapLg,
              ],

              // Invite code card
              ContiCard(
                borderGradient: AppTheme.primaryGradient,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('초대 코드',
                              style: theme.textTheme.labelSmall),
                          Text(
                            team.inviteCode,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: team.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('초대 코드가 복사되었습니다')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              AppSpacing.gapXxl,

              // Navigation cards (bento grid style)
              _NavigationCard(
                icon: Icons.music_note_rounded,
                title: '찬양 DB',
                subtitle: '찬양곡 관리',
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C5CFC), Color(0xFF5B8DEF)],
                ),
                onTap: () => context.push('/teams/$teamId/songs'),
              ),
              AppSpacing.gapMd,
              _NavigationCard(
                icon: Icons.queue_music_rounded,
                title: '콘티',
                subtitle: '세트리스트 관리',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF9A76)],
                ),
                onTap: () => context.push('/teams/$teamId/setlists'),
              ),
              AppSpacing.gapMd,
              _NavigationCard(
                icon: Icons.people_rounded,
                title: '팀원 관리',
                subtitle: '멤버 초대 및 역할 관리',
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B8DEF), Color(0xFF56CCF2)],
                ),
                onTap: () => context.push('/teams/$teamId/members'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}
