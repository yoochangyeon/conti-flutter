import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/song.dart';

class SongFormScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int? songId;

  const SongFormScreen({super.key, required this.teamId, this.songId});

  @override
  ConsumerState<SongFormScreen> createState() => _SongFormScreenState();
}

class _SongFormScreenState extends ConsumerState<SongFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _memoController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _musicUrlController = TextEditingController();
  final _bpmController = TextEditingController();
  final _tagController = TextEditingController();
  String? _selectedKey;
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.songId != null;
    if (_isEdit) {
      _loadSong();
    }
  }

  Future<void> _loadSong() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<SongDetailResponse>(
      '/teams/${widget.teamId}/songs/${widget.songId}',
      fromJson: (data) => SongDetailResponse.fromJson(data),
    );
    if (response.success && response.data != null && mounted) {
      final song = response.data!;
      setState(() {
        _titleController.text = song.title;
        _artistController.text = song.artist ?? '';
        _memoController.text = song.memo ?? '';
        _youtubeController.text = song.youtubeUrl ?? '';
        _musicUrlController.text = song.musicUrl ?? '';
        _bpmController.text = song.bpm?.toString() ?? '';
        _selectedKey = song.originalKey;
        _tags = List.from(song.tags);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _memoController.dispose();
    _youtubeController.dispose();
    _musicUrlController.dispose();
    _bpmController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final api = ref.read(apiClientProvider);
    final bpm = _bpmController.text.trim().isNotEmpty
        ? int.tryParse(_bpmController.text.trim())
        : null;

    if (_isEdit) {
      final request = SongUpdateRequest(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim().isEmpty ? null : _artistController.text.trim(),
        originalKey: _selectedKey,
        bpm: bpm,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        youtubeUrl: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
        musicUrl: _musicUrlController.text.trim().isEmpty ? null : _musicUrlController.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
      );
      await api.patch(
        '/teams/${widget.teamId}/songs/${widget.songId}',
        data: request.toJson(),
      );
    } else {
      final request = SongCreateRequest(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim().isEmpty ? null : _artistController.text.trim(),
        originalKey: _selectedKey,
        bpm: bpm,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        youtubeUrl: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
        musicUrl: _musicUrlController.text.trim().isEmpty ? null : _musicUrlController.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
      );
      await api.post(
        '/teams/${widget.teamId}/songs',
        data: request.toJson(),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ref.invalidate(songsProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '찬양 수정' : '찬양 추가')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목 *'),
              validator: (v) => v == null || v.trim().isEmpty ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: '아티스트'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedKey,
                    decoration: const InputDecoration(labelText: '원키'),
                    items: AppConstants.musicKeys
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
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
            // Tags
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(labelText: '태그 추가'),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(onPressed: _addTag, icon: const Icon(Icons.add)),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _youtubeController,
              decoration: const InputDecoration(labelText: 'YouTube URL'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _musicUrlController,
              decoration: const InputDecoration(labelText: '음원 URL'),
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
                  : Text(_isEdit ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }
}
