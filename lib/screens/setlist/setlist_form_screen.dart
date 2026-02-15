import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/setlist.dart';
import 'package:conti_app/models/schedule.dart';

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
  int? _selectedTemplateId;
  String? _selectedTemplateName;

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
      final queryParams = _selectedTemplateId != null
          ? '?templateId=$_selectedTemplateId'
          : '';
      await api.post(
        '/teams/${widget.teamId}/setlists$queryParams',
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
              items: WorshipType.values
                  .map((t) => DropdownMenuItem(
                      value: t.jsonValue, child: Text(t.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _worshipType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: '메모'),
              maxLines: 4,
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              _TemplateSelector(
                teamId: widget.teamId,
                selectedTemplateId: _selectedTemplateId,
                selectedTemplateName: _selectedTemplateName,
                onSelected: (id, name) => setState(() {
                  _selectedTemplateId = id;
                  _selectedTemplateName = name;
                }),
              ),
            ],
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

class _TemplateSelector extends ConsumerWidget {
  final int teamId;
  final int? selectedTemplateId;
  final String? selectedTemplateName;
  final void Function(int? id, String? name) onSelected;

  const _TemplateSelector({
    required this.teamId,
    required this.selectedTemplateId,
    required this.selectedTemplateName,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(setlistTemplatesProvider(teamId));
    final theme = Theme.of(context);

    return templatesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (templates) {
        if (templates.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('템플릿으로 시작', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('빈 콘티'),
                  selected: selectedTemplateId == null,
                  onSelected: (_) => onSelected(null, null),
                ),
                ...templates.map((t) => ChoiceChip(
                      label: Text(t.name),
                      selected: selectedTemplateId == t.id,
                      onSelected: (_) => onSelected(t.id, t.name),
                    )),
              ],
            ),
          ],
        );
      },
    );
  }
}
