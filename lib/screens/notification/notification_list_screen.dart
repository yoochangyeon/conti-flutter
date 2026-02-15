import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/models/notification.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/core/constants/app_spacing.dart';
import 'package:conti_app/widgets/conti_empty_state.dart';
import 'package:conti_app/widgets/conti_skeleton.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  Future<void> _markAllAsRead() async {
    final api = ref.read(apiClientProvider);
    final response = await api.patch('/notifications/read-all');
    if (response.success) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final api = ref.read(apiClientProvider);
    final response = await api.patch('/notifications/$notificationId/read');
    if (response.success) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider(0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('모두 읽음'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 5, itemHeight: 80),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (pagedData) {
          if (pagedData.content.isEmpty) {
            return const ContiEmptyState(
              icon: Icons.notifications_none_rounded,
              title: '알림이 없습니다',
              subtitle: '새로운 알림이 오면 여기에 표시됩니다',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: pagedData.content.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = pagedData.content[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _markAsRead(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationResponse notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    return switch (type) {
      'SCHEDULE_ASSIGNED' => Icons.assignment_ind_rounded,
      'SCHEDULE_RESPONSE' => Icons.how_to_reg_rounded,
      'SCHEDULE_REMINDER' => Icons.alarm_rounded,
      'SETLIST_UPDATED' => Icons.edit_note_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _colorForType(String type, ThemeData theme) {
    return switch (type) {
      'SCHEDULE_ASSIGNED' => theme.colorScheme.primary,
      'SCHEDULE_RESPONSE' => Colors.green,
      'SCHEDULE_REMINDER' => Colors.orange,
      'SETLIST_UPDATED' => theme.colorScheme.tertiary,
      _ => theme.colorScheme.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _colorForType(notification.type, theme);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return ListTile(
      onTap: onTap,
      tileColor: notification.isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(
          _iconForType(notification.type),
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            notification.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            timeAgo,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dateTime.month}/${dateTime.day}';
  }
}
