import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/core/api/api_response.dart';
import 'package:conti_app/models/notification.dart';
import 'package:conti_app/providers/auth_providers.dart';

// Notifications (paginated)
final notificationsProvider = FutureProvider.family<
    PagedData<NotificationResponse>, int>((ref, page) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<PagedData<NotificationResponse>>(
    '/notifications',
    queryParameters: {'page': page, 'size': 20},
    fromJson: (data) => PagedData.fromJson(data, NotificationResponse.fromJson),
  );
  return response.data ??
      PagedData(
        content: [],
        totalElements: 0,
        totalPages: 0,
        number: 0,
        size: 20,
        first: true,
        last: true,
      );
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<UnreadCountResponse>(
    '/notifications/unread-count',
    fromJson: (data) => UnreadCountResponse.fromJson(data),
  );
  return response.data?.count ?? 0;
});
