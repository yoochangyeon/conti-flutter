import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';

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
          const SnackBar(content: Text('팀에 참여했습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error?.message ?? '팀 참여 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 참여하기')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '팀 관리자에게 받은 초대 코드를 입력해주세요',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '초대 코드',
                hintText: '초대 코드 입력',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
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
