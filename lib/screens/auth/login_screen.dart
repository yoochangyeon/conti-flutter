import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/animated/conti_scale_tap.dart';
import '../../widgets/animated/conti_fade_in.dart';

const _kakaoYellow = Color(0xFFFEE500);
const _kakaoText = Color(0xFF3A1D1D);


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _devLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).devLogin();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('로그인에 실패했어요. 백엔드 서버가 실행 중인지 확인해 주세요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 중 오류가 발생했어요: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo with solid primary color
              ContiFadeIn(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.borderXl,
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 48,
                        color: AppColors.white,
                      ),
                    ),
                    AppSpacing.gapXxl,
                    Text(
                      'Conti',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      '예배팀을 위한 콘티 관리 플랫폼',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Kakao Login
              ContiFadeIn(
                delay: const Duration(milliseconds: 100),
                child: ContiScaleTap(
                  onTap: _isLoading ? null : () {},
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () {},
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('카카오로 시작하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kakaoYellow,
                        foregroundColor: _kakaoText,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderLg),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapMd,

              // Google Login
              ContiFadeIn(
                delay: const Duration(milliseconds: 150),
                child: ContiScaleTap(
                  onTap: _isLoading ? null : () {},
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {},
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text('Google로 시작하기'),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapXxl,

              // Dev Login
              if (_isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: _devLogin,
                  child: Text(
                    '개발자 로그인',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
