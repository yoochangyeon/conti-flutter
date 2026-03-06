import 'package:flutter/material.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_theme.dart';

class ContiErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ContiErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            AppSpacing.gapXl,
            Text(
              message ?? '일시적인 오류가 발생했어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.gray200 : AppColors.gray800,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapSm,
            const Text(
              '잠시 후 다시 시도해 주세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapXxl,
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
