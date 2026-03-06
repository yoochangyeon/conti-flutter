import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/user.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final success = await ref.read(authProvider.notifier).updateProfile(
          UserUpdateRequest(name: _nameController.text.trim()),
        );
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 수정되었어요')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 수정에 실패했어요')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppPadding.paddingForm,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                AppSpacing.gapXxl,
                if (_isEditing) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '이름'),
                  ),
                  AppSpacing.gapLg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _nameController.text = user.name;
                          setState(() => _isEditing = false);
                        },
                        child: const Text('취소'),
                      ),
                      AppSpacing.hGapSm,
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('저장'),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Text(user.name, style: theme.textTheme.headlineSmall),
                  ),
                  AppSpacing.gapXs,
                  Center(
                    child: Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ],
                AppSpacing.gapXxxl,
                // Dark mode setting
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text('화면 설정', style: theme.textTheme.titleSmall),
                        ),
                        _ThemeModeOption(
                          title: '시스템 설정에 맞추기',
                          icon: Icons.settings_brightness_rounded,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                        _ThemeModeOption(
                          title: '라이트 모드',
                          icon: Icons.light_mode_rounded,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                        _ThemeModeOption(
                          title: '다크 모드',
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapLg,
                // Calendar subscribe
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('캘린더 구독',
                            style: theme.textTheme.titleSmall),
                        AppSpacing.gapSm,
                        Text(
                          'iCal URL을 복사해서 Google 캘린더, Apple 캘린더 등에 구독할 수 있어요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        AppSpacing.gapMd,
                        Consumer(builder: (context, ref, _) {
                          final tokenAsync =
                              ref.watch(calendarTokenProvider);
                          return tokenAsync.when(
                            loading: () => const SizedBox(
                              height: 40,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            ),
                            error: (e, _) => Text('오류: $e',
                                style: theme.textTheme.bodySmall),
                            data: (token) {
                              if (token == null) {
                                return Text('토큰을 가져올 수 없어요',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.gray500,
                                    ));
                              }
                              final url =
                                  '${AppConstants.baseUrl}${AppConstants.apiPrefix}/calendar.ics?token=$token';
                              return FilledButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: url));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            '캘린더 URL이 복사되었어요')),
                                  );
                                },
                                icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18),
                                label: const Text('iCal URL 복사하기'),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapXxl,
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isSelected
            ? AppColors.primary
            : AppColors.gray400,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? AppColors.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
