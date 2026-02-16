import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/song.dart';

class ArrangementFormScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int songId;
  final int? arrangementId;

  const ArrangementFormScreen({
    super.key,
    required this.teamId,
    required this.songId,
    this.arrangementId,
  });

  @override
  ConsumerState<ArrangementFormScreen> createState() =>
      _ArrangementFormScreenState();
}

class _ArrangementFormScreenState
    extends ConsumerState<ArrangementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bpmController = TextEditingController();
  final _meterController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedKey;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.arrangementId != null;
    if (_isEdit) {
      _loadArrangement();
    }
  }

  Future<void> _loadArrangement() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<ArrangementResponse>(
      '/teams/${widget.teamId}/songs/${widget.songId}/arrangements/${widget.arrangementId}',
      fromJson: (data) => ArrangementResponse.fromJson(data),
    );
    if (response.success && response.data != null && mounted) {
      final arr = response.data!;
      setState(() {
        _nameController.text = arr.name;
        _selectedKey = arr.songKey;
        _bpmController.text = arr.bpm?.toString() ?? '';
        _meterController.text = arr.meter ?? '';
        _durationController.text = arr.durationMinutes?.toString() ?? '';
        _descriptionController.text = arr.description ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bpmController.dispose();
    _meterController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final api = ref.read(apiClientProvider);
    final bpm = _bpmController.text.trim().isNotEmpty
        ? int.tryParse(_bpmController.text.trim())
        : null;
    final duration = _durationController.text.trim().isNotEmpty
        ? int.tryParse(_durationController.text.trim())
        : null;
    final meter = _meterController.text.trim().isEmpty
        ? null
        : _meterController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final basePath =
        '/teams/${widget.teamId}/songs/${widget.songId}/arrangements';

    late final dynamic response;
    if (_isEdit) {
      final request = ArrangementUpdateRequest(
        name: _nameController.text.trim(),
        songKey: _selectedKey,
        bpm: bpm,
        meter: meter,
        durationMinutes: duration,
        description: description,
      );
      response = await api.patch(
        '$basePath/${widget.arrangementId}',
        data: request.toJson(),
      );
    } else {
      final request = ArrangementCreateRequest(
        name: _nameController.text.trim(),
        songKey: _selectedKey,
        bpm: bpm,
        meter: meter,
        durationMinutes: duration,
        description: description,
      );
      response = await api.post(basePath, data: request.toJson());
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (response.success) {
        ref.invalidate(songDetailProvider(
            (teamId: widget.teamId, songId: widget.songId)));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response.error?.message ?? '저장에 실패했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '편곡 수정' : '편곡 추가')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '편곡 이름 *',
                hintText: '예: 풀밴드 버전, 어쿠스틱 버전',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedKey,
                    decoration: const InputDecoration(labelText: 'Key'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('선택 안함')),
                      ...AppConstants.musicKeys
                          .map((k) =>
                              DropdownMenuItem(value: k, child: Text(k))),
                    ],
                    onChanged: (v) => setState(() => _selectedKey = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bpmController,
                    decoration: const InputDecoration(labelText: 'BPM'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _meterController,
                    decoration: const InputDecoration(
                      labelText: '박자',
                      hintText: '예: 4/4, 6/8',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: '시간 (분)',
                      hintText: '예: 5',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '설명'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }
}
