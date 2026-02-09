import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/team.dart';

class TeamCreateScreen extends ConsumerStatefulWidget {
  const TeamCreateScreen({super.key});

  @override
  ConsumerState<TeamCreateScreen> createState() => _TeamCreateScreenState();
}

class _TeamCreateScreenState extends ConsumerState<TeamCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final api = ref.read(apiClientProvider);
    final request = TeamCreateRequest(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
    );

    final response = await api.post(
      '/teams',
      data: request.toJson(),
      fromJson: (data) => TeamResponse.fromJson(data),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response.success) {
        ref.invalidate(userTeamsProvider);
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀이 생성되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error?.message ?? '팀 생성 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 팀 만들기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '팀 이름',
                hintText: '예: 주일 예배팀',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '팀 이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '설명 (선택)',
                hintText: '팀에 대한 설명을 입력해주세요',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('팀 만들기'),
            ),
          ],
        ),
      ),
    );
  }
}
