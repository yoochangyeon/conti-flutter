import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/models/team.dart';
import 'package:conti_app/models/user.dart';
import 'package:conti_app/models/schedule.dart';
import 'package:conti_app/providers/auth_providers.dart';

// Selected team
final selectedTeamIdProvider = StateProvider<int?>((ref) => null);

// User teams
final userTeamsProvider = FutureProvider<List<UserTeamResponse>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<UserTeamResponse>>(
    '/users/me/teams',
    fromJson: (data) => (data as List)
        .map((e) => UserTeamResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Team detail
final teamDetailProvider =
    FutureProvider.family<TeamResponse?, int>((ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<TeamResponse>(
    '/teams/$teamId',
    fromJson: (data) => TeamResponse.fromJson(data),
  );
  return response.data;
});

// Team members
final teamMembersProvider =
    FutureProvider.family<List<TeamMemberResponse>, int>((ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<TeamMemberResponse>>(
    '/teams/$teamId/members',
    fromJson: (data) => (data as List)
        .map((e) => TeamMemberResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Team notices
final teamNoticesProvider =
    FutureProvider.family<List<TeamNoticeResponse>, int>((ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<TeamNoticeResponse>>(
    '/teams/$teamId/notices',
    fromJson: (data) => (data as List)
        .map((e) => TeamNoticeResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Member blockout dates
final memberBlockoutsProvider = FutureProvider.family<
    List<BlockoutDateResponse>,
    ({int teamId, int memberId})>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<BlockoutDateResponse>>(
    '/teams/${params.teamId}/members/${params.memberId}/blockouts',
    fromJson: (data) => (data as List)
        .map((e) => BlockoutDateResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Team blockouts in date range (admin)
final teamBlockoutsProvider = FutureProvider.family<
    List<BlockoutDateResponse>,
    ({int teamId, String fromDate, String toDate})>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<BlockoutDateResponse>>(
    '/teams/${params.teamId}/blockouts',
    queryParameters: {'fromDate': params.fromDate, 'toDate': params.toDate},
    fromJson: (data) => (data as List)
        .map((e) => BlockoutDateResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});
