import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
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
      appBar: AppBar(title: Text(_isEdit ? '찬양 수정하기' : '새 찬양 추가하기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppPadding.paddingForm,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목 *'),
              validator: (v) => v == null || v.trim().isEmpty ? '제목을 입력해 주세요' : null,
            ),
            AppSpacing.gapLg,
            TextFormField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: '아티스트'),
            ),
            AppSpacing.gapLg,
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
                AppSpacing.hGapLg,
                Expanded(
                  child: TextFormField(
                    controller: _bpmController,
                    decoration: const InputDecoration(
                      labelText: '빠르기',
                      hintText: 'BPM',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,
            // Tags
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: '태그',
                      hintText: '태그를 입력해 보세요',
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(onPressed: _addTag, icon: const Icon(Icons.add)),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        ))
                    .toList(),
              ),
            ],
            // Tag suggestions from existing tags
            _TagSuggestions(
              teamId: widget.teamId,
              selectedTags: _tags,
              onTagSelected: (tag) {
                if (!_tags.contains(tag)) {
                  setState(() => _tags.add(tag));
                }
              },
            ),
            AppSpacing.gapLg,
            TextFormField(
              controller: _youtubeController,
              decoration: const InputDecoration(
                labelText: '유튜브 링크',
                hintText: 'https://youtube.com/...',
              ),
            ),
            AppSpacing.gapLg,
            TextFormField(
              controller: _musicUrlController,
              decoration: const InputDecoration(
                labelText: '음원 링크',
                hintText: 'https://...',
              ),
            ),
            AppSpacing.gapLg,
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: '메모'),
              maxLines: 4,
            ),
            AppSpacing.gapXxxl,
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? '수정하기' : '추가하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSuggestions extends ConsumerWidget {
  final int teamId;
  final List<String> selectedTags;
  final ValueChanged<String> onTagSelected;

  const _TagSuggestions({
    required this.teamId,
    required this.selectedTags,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider(teamId));
    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        final suggestions =
            tags.where((t) => !selectedTags.contains(t.tag)).toList();
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: suggestions.map((t) {
              return ActionChip(
                label: Text('${t.tag} (${t.count})'),
                onPressed: () => onTagSelected(t.tag),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
