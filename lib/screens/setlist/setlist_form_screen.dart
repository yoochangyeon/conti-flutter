import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/setlist.dart';

class SetlistFormScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int? setlistId;

  const SetlistFormScreen({super.key, required this.teamId, this.setlistId});

  @override
  ConsumerState<SetlistFormScreen> createState() => _SetlistFormScreenState();
}

class _SetlistFormScreenState extends ConsumerState<SetlistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _worshipDate = DateTime.now();
  String? _worshipType;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.setlistId != null;
    if (_isEdit) {
      _loadSetlist();
    }
  }

  Future<void> _loadSetlist() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<SetlistDetailResponse>(
      '/teams/${widget.teamId}/setlists/${widget.setlistId}',
      fromJson: (data) => SetlistDetailResponse.fromJson(data),
    );
    if (response.success && response.data != null && mounted) {
      final s = response.data!;
      setState(() {
        _titleController.text = s.title ?? '';
        _memoController.text = s.memo ?? '';
        _worshipDate = s.worshipDate;
        _worshipType = s.worshipType;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _worshipDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _worshipDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final api = ref.read(apiClientProvider);

    if (_isEdit) {
      final request = SetlistUpdateRequest(
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        worshipDate: _worshipDate,
        worshipType: _worshipType,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      await api.patch(
        '/teams/${widget.teamId}/setlists/${widget.setlistId}',
        data: request.toJson(),
      );
    } else {
      final request = SetlistCreateRequest(
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        worshipDate: _worshipDate,
        worshipType: _worshipType,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      await api.post(
        '/teams/${widget.teamId}/setlists',
        data: request.toJson(),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '콘티 수정' : '콘티 만들기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목 (선택)',
                hintText: '예: 부활절 특별 예배',
              ),
            ),
            const SizedBox(height: 16),
            // Date picker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '예배 날짜 *',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(dateFormat.format(_worshipDate)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _worshipType,
              decoration: const InputDecoration(labelText: '예배 종류'),
              items: AppConstants.worshipTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _worshipType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: '메모'),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? '수정' : '만들기'),
            ),
          ],
        ),
      ),
    );
  }
}
