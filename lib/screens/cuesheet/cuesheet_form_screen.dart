import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/setlist.dart';
import 'package:conti_app/models/schedule.dart';
import '../../core/constants/app_spacing.dart';

/// Form screen for creating or editing a cue sheet.
/// Includes conti linking and template selection on create.
class CueSheetFormScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int? cueSheetId;

  const CueSheetFormScreen({
    super.key,
    required this.teamId,
    this.cueSheetId,
  });

  @override
  ConsumerState<CueSheetFormScreen> createState() =>
      _CueSheetFormScreenState();
}

class _CueSheetFormScreenState
    extends ConsumerState<CueSheetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _worshipDate = DateTime.now();
  String? _worshipType;
  int? _selectedContiId;
  int? _originalContiId;
  bool _isLoading = false;
  bool _isEdit = false;
  int? _selectedTemplateId;
  String? _selectedTemplateName;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.cueSheetId != null;
    if (_isEdit) {
      _loadCueSheet();
    }
  }

  Future<void> _loadCueSheet() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<SetlistDetailResponse>(
      '/teams/${widget.teamId}/setlists/${widget.cueSheetId}',
      fromJson: (data) => SetlistDetailResponse.fromJson(data),
    );
    if (response.success && response.data != null && mounted) {
      final s = response.data!;
      setState(() {
        _titleController.text = s.title ?? '';
        _memoController.text = s.memo ?? '';
        _worshipDate = s.worshipDate;
        _worshipType = s.worshipType;
        _selectedContiId = s.contiId;
        _originalContiId = s.contiId;
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
      // Update cue sheet metadata
      final request = SetlistUpdateRequest(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        worshipDate: _worshipDate,
        worshipType: _worshipType,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );
      final response = await api.patch(
        '/teams/${widget.teamId}/setlists/${widget.cueSheetId}',
        data: request.toJson(),
      );

      // Sync conti link if changed
      if (response.success &&
          _selectedContiId != _originalContiId) {
        if (_selectedContiId != null) {
          await api.patch(
            '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/link-conti?contiId=$_selectedContiId',
          );
        } else if (_originalContiId != null) {
          await api.patch(
            '/teams/${widget.teamId}/setlists/${widget.cueSheetId}/unlink-conti',
          );
        }
      }
    } else {
      // Create new cue sheet
      final request = SetlistCreateRequest(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        worshipDate: _worshipDate,
        worshipType: _worshipType,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        setlistType: 'CUE_SHEET',
      );
      final queryParams = _selectedTemplateId != null
          ? '?templateId=$_selectedTemplateId'
          : '';
      final response = await api.post(
        '/teams/${widget.teamId}/setlists$queryParams',
        data: request.toJson(),
      );

      // If created successfully and a conti is selected, link it
      if (response.success &&
          _selectedContiId != null &&
          response.data != null) {
        final newId = response.data is Map
            ? (response.data as Map)['id']
            : null;
        if (newId != null) {
          await api.patch(
            '/teams/${widget.teamId}/setlists/$newId/link-conti?contiId=$_selectedContiId',
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ref.invalidate(setlistsProvider(SetlistListParams(
          teamId: widget.teamId, setlistType: 'CUE_SHEET')));
      if (_isEdit) {
        ref.invalidate(setlistDetailProvider(
            (teamId: widget.teamId, setlistId: widget.cueSheetId!)));
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
    final contiParams = SetlistListParams(
        teamId: widget.teamId, setlistType: 'CONTI');
    final contiListAsync =
        ref.watch(setlistsProvider(contiParams));

    return Scaffold(
      appBar: AppBar(
          title: Text(
              _isEdit ? '큐시트 수정하기' : '새 큐시트 만들기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppPadding.paddingForm,
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목 (선택)',
                hintText: '예: 부활절 주일 큐시트',
              ),
            ),
            AppSpacing.gapLg,

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
            AppSpacing.gapLg,

            // Worship type dropdown
            DropdownButtonFormField<String>(
              value: _worshipType,
              decoration:
                  const InputDecoration(labelText: '예배 종류'),
              items: WorshipType.values
                  .map((t) => DropdownMenuItem(
                      value: t.jsonValue,
                      child: Text(t.displayName)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _worshipType = v),
            ),
            AppSpacing.gapLg,

            // Memo field
            TextFormField(
              controller: _memoController,
              decoration:
                  const InputDecoration(labelText: '메모'),
              maxLines: 4,
            ),
            AppSpacing.gapXxl,

            // Conti link section
            Text('콘티 연결',
                style:
                    Theme.of(context).textTheme.titleSmall),
            AppSpacing.gapSm,
            contiListAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) =>
                  const Text('콘티 목록을 불러올 수 없어요'),
              data: (paged) {
                final contiItems = paged.content;
                if (contiItems.isEmpty) {
                  return Text(
                    '연결할 수 있는 콘티가 없어요',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  );
                }
                return DropdownButtonFormField<int?>(
                  value: _selectedContiId,
                  decoration: const InputDecoration(
                      labelText: '연결할 콘티 선택'),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('연결 안함')),
                    ...contiItems.map((c) =>
                        DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.displayTitle))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedContiId = v),
                );
              },
            ),

            // Template selector (only for create)
            if (!_isEdit) ...[
              AppSpacing.gapLg,
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

            AppSpacing.gapXxxl,

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                  : Text(_isEdit ? '저장하기' : '만들기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Template Selector ───

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
    final templatesAsync =
        ref.watch(setlistTemplatesProvider(teamId));
    final theme = Theme.of(context);

    return templatesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (templates) {
        if (templates.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('템플릿으로 시작해 보세요',
                style: theme.textTheme.titleSmall),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('빈 큐시트'),
                  selected: selectedTemplateId == null,
                  onSelected: (_) =>
                      onSelected(null, null),
                ),
                ...templates.map((t) => ChoiceChip(
                      label: Text(t.name),
                      selected: selectedTemplateId == t.id,
                      onSelected: (_) =>
                          onSelected(t.id, t.name),
                    )),
              ],
            ),
          ],
        );
      },
    );
  }
}
