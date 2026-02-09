import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:conti_app/providers/providers.dart';

class SongDetailScreen extends ConsumerWidget {
  final int teamId;
  final int songId;

  const SongDetailScreen({super.key, required this.teamId, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songDetailProvider((teamId: teamId, songId: songId)));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('찬양 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/teams/$teamId/songs/$songId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteSong(context, ref),
          ),
        ],
      ),
      body: songAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (song) {
          if (song == null) return const Center(child: Text('곡을 찾을 수 없습니다'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(song.title, style: theme.textTheme.headlineSmall),
              if (song.artist != null) ...[
                const SizedBox(height: 4),
                Text(song.artist!, style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
              ],
              const SizedBox(height: 16),
              // Tags
              if (song.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: song.tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Info row
              Row(
                children: [
                  if (song.originalKey != null)
                    _InfoChip(icon: Icons.music_note, label: 'Key: ${song.originalKey}'),
                  if (song.bpm != null)
                    _InfoChip(icon: Icons.speed, label: 'BPM: ${song.bpm}'),
                  _InfoChip(icon: Icons.history, label: '${song.usageCount}회 사용'),
                ],
              ),
              const SizedBox(height: 24),
              // Links
              if (song.youtubeUrl != null && song.youtubeUrl!.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.play_circle_outline, color: Colors.red),
                  title: const Text('YouTube'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(song.youtubeUrl!),
                ),
              ],
              if (song.musicUrl != null && song.musicUrl!.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: const Text('음원 링크'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(song.musicUrl!),
                ),
              ],
              // Memo
              if (song.memo != null && song.memo!.isNotEmpty) ...[
                const Divider(height: 32),
                Text('메모', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(song.memo!),
              ],
              // Files
              if (song.files.isNotEmpty) ...[
                const Divider(height: 32),
                Text('악보 파일', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...song.files.map((file) => ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.fileName),
                      subtitle: file.fileType != null ? Text(file.fileType!) : null,
                      trailing: const Icon(Icons.download),
                      onTap: () => _openUrl(file.fileUrl),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteSong(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('찬양 삭제'),
        content: const Text('이 찬양을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final api = ref.read(apiClientProvider);
      await api.delete('/teams/$teamId/songs/$songId');
      if (context.mounted) context.pop();
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
