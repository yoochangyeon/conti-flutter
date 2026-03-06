import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';

class TeamMoreTab extends ConsumerWidget {
  final int teamId;

  const TeamMoreTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // Invite code section
          teamAsync.whenOrNull(
            data: (team) {
              if (team == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded,
                          color: AppColors.primary, size: 20),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('초대 코드',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: AppColors.primary)),
                            Text(
                              team.inviteCode,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppColors.primary, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: team.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('초대 코드가 복사되었어요')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),

          // Team management section
          _SectionLabel('팀 관리'),
          _MoreMenuItem(
            icon: Icons.people_rounded,
            iconColor: AppColors.primary,
            title: '팀원 관리',
            subtitle: '멤버 초대 및 역할 관리',
            onTap: () => context.push('/teams/$teamId/members'),
          ),
          _MoreMenuItem(
            icon: Icons.campaign_rounded,
            iconColor: AppColors.orange,
            title: '공지사항',
            subtitle: '팀 공지 및 안내',
            onTap: () => context.push('/teams/$teamId/notices'),
          ),

          const Divider(height: 32, indent: 20, endIndent: 20),

          // Schedule & stats section
          _SectionLabel('일정 · 통계'),
          _MoreMenuItem(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primary,
            title: '내 일정',
            subtitle: '나의 봉사 일정 확인',
            onTap: () => context.push('/teams/$teamId/my-schedule'),
          ),
          _MoreMenuItem(
            icon: Icons.grid_view_rounded,
            iconColor: AppColors.teal,
            title: '스케줄 매트릭스',
            subtitle: '날짜별 포지션 배정 현황',
            onTap: () => context.push('/teams/$teamId/schedule-matrix'),
          ),
          _MoreMenuItem(
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.purple,
            title: '찬양 통계',
            subtitle: '사용 빈도 및 키 분석',
            onTap: () => context.push('/teams/$teamId/songs/stats'),
          ),
          _MoreMenuItem(
            icon: Icons.copy_all_rounded,
            iconColor: AppColors.green,
            title: '콘티 템플릿',
            subtitle: '자주 쓰는 콘티 양식 관리',
            onTap: () => context.push('/teams/$teamId/setlist-templates'),
          ),

          const Divider(height: 32, indent: 20, endIndent: 20),

          // Account section
          _SectionLabel('계정'),
          _MoreMenuItem(
            icon: Icons.person_rounded,
            iconColor: AppColors.gray600,
            title: '프로필 · 설정',
            subtitle: '계정 정보 및 알림 설정',
            onTap: () => context.push('/profile'),
          ),
          _MoreMenuItem(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.gray600,
            title: '알림',
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.gray500))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.gray400, size: 20),
      onTap: onTap,
    );
  }
}
