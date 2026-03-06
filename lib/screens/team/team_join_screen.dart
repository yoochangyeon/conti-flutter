import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';

class TeamJoinScreen extends ConsumerStatefulWidget {
  const TeamJoinScreen({super.key});

  @override
  ConsumerState<TeamJoinScreen> createState() => _TeamJoinScreenState();
}

class _TeamJoinScreenState extends ConsumerState<TeamJoinScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);

    final api = ref.read(apiClientProvider);
    final response = await api.post('/teams/join/$code');

    if (mounted) {
      setState(() => _isLoading = false);
      if (response.success) {
        ref.invalidate(userTeamsProvider);
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀에 참여했어요!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error?.message ?? '팀 참여에 실패했어요')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('팀 참여하기')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '팀 관리자에게 받은 초대 코드를 입력해 주세요',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.gray600,
              ),
            ),
            AppSpacing.gapXxl,
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '초대 코드',
                hintText: '초대 코드를 입력해 주세요',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            AppSpacing.gapXxxl,
            FilledButton(
              onPressed: _isLoading ? null : _join,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('참여하기'),
            ),
          ],
        ),
      ),
    );
  }
}
