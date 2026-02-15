import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/models/schedule.dart';
import 'package:conti_app/providers/auth_providers.dart';

// Schedules for a specific setlist
final setlistSchedulesProvider = FutureProvider.family<
    List<ServiceScheduleResponse>,
    ({int teamId, int setlistId})>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<ServiceScheduleResponse>>(
    '/teams/${params.teamId}/setlists/${params.setlistId}/schedules',
    fromJson: (data) => (data as List)
        .map((e) => ServiceScheduleResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// My upcoming schedules in a team
final mySchedulesProvider =
    FutureProvider.family<List<ServiceScheduleResponse>, int>(
        (ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<ServiceScheduleResponse>>(
    '/teams/$teamId/my-schedules',
    fromJson: (data) => (data as List)
        .map((e) => ServiceScheduleResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Schedule matrix
class ScheduleMatrixParams {
  final int teamId;
  final String fromDate;
  final String toDate;

  ScheduleMatrixParams({
    required this.teamId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleMatrixParams &&
          teamId == other.teamId &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(teamId, fromDate, toDate);
}

final scheduleMatrixProvider = FutureProvider.family<
    ScheduleMatrixResponse, ScheduleMatrixParams>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<ScheduleMatrixResponse>(
    '/teams/${params.teamId}/schedules/matrix',
    queryParameters: {'from': params.fromDate, 'to': params.toDate},
    fromJson: (data) =>
        ScheduleMatrixResponse.fromJson(data as Map<String, dynamic>),
  );
  return response.data!;
});
