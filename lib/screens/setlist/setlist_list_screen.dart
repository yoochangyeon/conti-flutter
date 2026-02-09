import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';

class SetlistListScreen extends ConsumerStatefulWidget {
  final int teamId;

  const SetlistListScreen({super.key, required this.teamId});

  @override
  ConsumerState<SetlistListScreen> createState() => _SetlistListScreenState();
}

class _SetlistListScreenState extends ConsumerState<SetlistListScreen> {
  String? _worshipType;

  @override
  Widget build(BuildContext context) {
    final params = SetlistListParams(teamId: widget.teamId, worshipType: _worshipType);
    final setlistsAsync = ref.watch(setlistsProvider(params));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd (E)', 'ko');

    return Scaffold(
      appBar: AppBar(
        title: const Text('콘티'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _worshipType = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('전체')),
              const PopupMenuItem(value: '주일 1부 예배', child: Text('주일 1부 예배')),
              const PopupMenuItem(value: '주일 2부 예배', child: Text('주일 2부 예배')),
              const PopupMenuItem(value: '수요 예배', child: Text('수요 예배')),
              const PopupMenuItem(value: '금요 기도회', child: Text('금요 기도회')),
              const PopupMenuItem(value: '청년 예배', child: Text('청년 예배')),
            ],
          ),
        ],
      ),
      body: setlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (paged) {
          if (paged.content.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('등록된 콘티가 없습니다', style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(setlistsProvider(params)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paged.content.length,
              itemBuilder: (context, index) {
                final setlist = paged.content[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/teams/${widget.teamId}/setlists/${setlist.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  setlist.displayTitle,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '${setlist.songCount}곡',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(setlist.worshipDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (setlist.worshipType != null) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    setlist.worshipType!,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teams/${widget.teamId}/setlists/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
