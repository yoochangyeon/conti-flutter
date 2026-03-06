import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conti_app/core/constants/app_spacing.dart';
import 'package:conti_app/core/constants/app_theme.dart';
import 'package:conti_app/models/notification.dart';

final _notificationSettingsProvider =
    StateNotifierProvider<_NotificationSettingsNotifier, Map<String, bool>>(
        (ref) {
  return _NotificationSettingsNotifier();
});

class _NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  _NotificationSettingsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, bool>{};
    for (final type in NotificationType.values) {
      settings[type.name] = prefs.getBool('notif_${type.name}') ?? true;
    }
    state = settings;
  }

  Future<void> toggle(String typeName) async {
    final current = state[typeName] ?? true;
    state = {...state, typeName: !current};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$typeName', !current);
  }
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(_notificationSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              '받고 싶은 알림을 선택해 주세요',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          for (final type in NotificationType.values)
            SwitchListTile(
              title: Text(type.displayName),
              subtitle: Text(
                _subtitleForType(type),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              value: settings[type.name] ?? true,
              activeTrackColor: AppColors.primary,
              onChanged: (_) =>
                  ref.read(_notificationSettingsProvider.notifier).toggle(type.name),
            ),
        ],
      ),
    );
  }

  String _subtitleForType(NotificationType type) {
    return switch (type) {
      NotificationType.scheduleAssigned => '봉사에 배정되었을 때 알려드려요',
      NotificationType.scheduleResponse => '멤버가 배정에 응답했을 때 알려드려요',
      NotificationType.scheduleReminder => '봉사 D-1, D-2 리마인더를 보내드려요',
      NotificationType.setlistUpdated => '콘티가 수정되었을 때 알려드려요',
    };
  }
}
