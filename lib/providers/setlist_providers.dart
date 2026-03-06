import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/core/api/api_response.dart';
import 'package:conti_app/models/setlist.dart';
import 'package:conti_app/models/team.dart';
import 'package:conti_app/providers/auth_providers.dart';

// Setlists (paginated)
class SetlistListParams {
  final int teamId;
  final int page;
  final String? worshipType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? setlistType;

  SetlistListParams({
    required this.teamId,
    this.page = 0,
    this.worshipType,
    this.fromDate,
    this.toDate,
    this.setlistType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetlistListParams &&
          teamId == other.teamId &&
          page == other.page &&
          worshipType == other.worshipType &&
          setlistType == other.setlistType;

  @override
  int get hashCode => Object.hash(teamId, page, worshipType, setlistType);
}

final setlistsProvider = FutureProvider.family<PagedData<SetlistResponse>, SetlistListParams>(
    (ref, params) async {
  final api = ref.watch(apiClientProvider);
  final queryParams = <String, dynamic>{
    'page': params.page,
    'size': 20,
    if (params.worshipType != null) 'worshipType': params.worshipType,
    if (params.setlistType != null) 'setlistType': params.setlistType,
    if (params.fromDate != null)
      'fromDate': params.fromDate!.toIso8601String().split('T')[0],
    if (params.toDate != null)
      'toDate': params.toDate!.toIso8601String().split('T')[0],
  };
  final response = await api.get<PagedData<SetlistResponse>>(
    '/teams/${params.teamId}/setlists',
    queryParameters: queryParams,
    fromJson: (data) => PagedData.fromJson(data, SetlistResponse.fromJson),
  );
  return response.data ?? PagedData(content: [], totalElements: 0, totalPages: 0, number: 0, size: 20, first: true, last: true);
});

// Setlist detail
final setlistDetailProvider =
    FutureProvider.family<SetlistDetailResponse?, ({int teamId, int setlistId})>(
        (ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<SetlistDetailResponse>(
    '/teams/${params.teamId}/setlists/${params.setlistId}',
    fromJson: (data) => SetlistDetailResponse.fromJson(data),
  );
  return response.data;
});

// Setlist templates
final setlistTemplatesProvider =
    FutureProvider.family<List<SetlistTemplateResponse>, int>(
        (ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<SetlistTemplateResponse>>(
    '/teams/$teamId/setlist-templates',
    fromJson: (data) => (data as List)
        .map((e) =>
            SetlistTemplateResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Setlist notes
final setlistNotesProvider = FutureProvider.family<
    List<SetlistNoteResponse>,
    ({int teamId, int setlistId, String? position})>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  final queryParams = <String, dynamic>{
    if (params.position != null) 'position': params.position,
  };
  final response = await api.get<List<SetlistNoteResponse>>(
    '/teams/${params.teamId}/setlists/${params.setlistId}/notes',
    queryParameters: queryParams,
    fromJson: (data) => (data as List)
        .map((e) => SetlistNoteResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});
