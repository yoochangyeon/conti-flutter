import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/team.dart';
import '../../core/constants/app_spacing.dart';

class TeamNoticesScreen extends ConsumerWidget {
  final int teamId;

  const TeamNoticesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(teamNoticesProvider(teamId));
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    final isAdmin = membersAsync.whenOrNull(
          data: (members) => members
              .any((m) => m.userId == authState.user?.id && m.isAdmin),
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showNoticeForm(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 64, color: theme.colorScheme.outline),
                  AppSpacing.gapLg,
                  Text('아직 공지사항이 없습니다',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(teamNoticesProvider(teamId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return _NoticeCard(
                  notice: notice,
                  isAdmin: isAdmin,
                  onPin: () => _togglePin(ref, notice.id),
                  onEdit: () => _showNoticeForm(context, ref, notice: notice),
                  onDelete: () =>
                      _deleteNotice(context, ref, notice.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNoticeForm(BuildContext context, WidgetRef ref,
      {TeamNoticeResponse? notice}) async {
    final titleCtrl = TextEditingController(text: notice?.title ?? '');
    final contentCtrl = TextEditingController(text: notice?.content ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(notice == null ? '공지사항 작성' : '공지사항 수정'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: '제목',
                  hintText: '공지 제목을 입력하세요',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                  labelText: '내용',
                  hintText: '공지 내용을 입력하세요',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(notice == null ? '작성' : '수정'),
          ),
        ],
      ),
    );

    if (result == true) {
      final api = ref.read(apiClientProvider);
      final data = {
        'title': titleCtrl.text,
        'content': contentCtrl.text,
      };
      if (notice == null) {
        await api.post('/teams/$teamId/notices', data: data);
      } else {
        await api.patch('/teams/$teamId/notices/${notice.id}', data: data);
      }
      ref.invalidate(teamNoticesProvider(teamId));
    }
  }

  Future<void> _togglePin(WidgetRef ref, int noticeId) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/teams/$teamId/notices/$noticeId/pin');
    ref.invalidate(teamNoticesProvider(teamId));
  }

  Future<void> _deleteNotice(
      BuildContext context, WidgetRef ref, int noticeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공지사항 삭제'),
        content: const Text('이 공지사항을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      await api.delete('/teams/$teamId/notices/$noticeId');
      ref.invalidate(teamNoticesProvider(teamId));
    }
  }
}

class _NoticeCard extends StatelessWidget {
  final TeamNoticeResponse notice;
  final bool isAdmin;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoticeCard({
    required this.notice,
    required this.isAdmin,
    required this.onPin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin,
                        size: 16, color: theme.colorScheme.primary),
                  ),
                Expanded(
                  child: Text(
                    notice.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton<String>(
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'pin',
                        child:
                            Text(notice.isPinned ? '고정 해제' : '고정'),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('수정'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제'),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          onPin();
                        case 'edit':
                          onEdit();
                        case 'delete':
                          onDelete();
                      }
                    },
                  ),
              ],
            ),
            if (notice.content != null && notice.content!.isNotEmpty) ...[
              AppSpacing.gapSm,
              Text(
                notice.content!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            AppSpacing.gapSm,
            Row(
              children: [
                Text(
                  notice.authorName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(notice.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}
