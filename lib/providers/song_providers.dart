import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/core/api/api_response.dart';
import 'package:conti_app/models/song.dart';
import 'package:conti_app/providers/auth_providers.dart';

// Songs (paginated)
class SongListParams {
  final int teamId;
  final int page;
  final String? keyword;
  final List<String>? tags;
  final String? key;

  SongListParams({
    required this.teamId,
    this.page = 0,
    this.keyword,
    this.tags,
    this.key,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongListParams &&
          teamId == other.teamId &&
          page == other.page &&
          keyword == other.keyword &&
          key == other.key;

  @override
  int get hashCode => Object.hash(teamId, page, keyword, key);
}

final songsProvider = FutureProvider.family<PagedData<SongResponse>, SongListParams>(
    (ref, params) async {
  final api = ref.watch(apiClientProvider);
  final queryParams = <String, dynamic>{
    'page': params.page,
    'size': 20,
    if (params.keyword != null) 'keyword': params.keyword,
    if (params.tags != null) 'tags': params.tags,
    if (params.key != null) 'key': params.key,
  };
  final response = await api.get<PagedData<SongResponse>>(
    '/teams/${params.teamId}/songs',
    queryParameters: queryParams,
    fromJson: (data) => PagedData.fromJson(data, SongResponse.fromJson),
  );
  return response.data ?? PagedData(content: [], totalElements: 0, totalPages: 0, number: 0, size: 20, first: true, last: true);
});

// Song detail
final songDetailProvider =
    FutureProvider.family<SongDetailResponse?, ({int teamId, int songId})>(
        (ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<SongDetailResponse>(
    '/teams/${params.teamId}/songs/${params.songId}',
    fromJson: (data) => SongDetailResponse.fromJson(data),
  );
  return response.data;
});

// Song usages
final songUsagesProvider =
    FutureProvider.family<List<SongUsageResponse>, ({int teamId, int songId})>(
        (ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<SongUsageResponse>>(
    '/teams/${params.teamId}/songs/${params.songId}/usages',
    fromJson: (data) => (data as List)
        .map((e) => SongUsageResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Tags
final tagsProvider =
    FutureProvider.family<List<TagResponse>, int>((ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<TagResponse>>(
    '/teams/$teamId/songs/tags',
    fromJson: (data) => (data as List)
        .map((e) => TagResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Song stats - top songs
final topSongsProvider =
    FutureProvider.family<List<TopSongResponse>, int>((ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<TopSongResponse>>(
    '/teams/$teamId/songs/stats',
    queryParameters: {'limit': 20},
    fromJson: (data) => (data as List)
        .map((e) => TopSongResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});

// Song stats - per song
final songStatsProvider =
    FutureProvider.family<SongStatsResponse?, ({int teamId, int songId})>(
        (ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<SongStatsResponse>(
    '/teams/${params.teamId}/songs/${params.songId}/stats',
    fromJson: (data) => SongStatsResponse.fromJson(data),
  );
  return response.data;
});

// Song arrangements
final songArrangementsProvider = FutureProvider.family<
    List<ArrangementResponse>,
    ({int teamId, int songId})>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<List<ArrangementResponse>>(
    '/teams/${params.teamId}/songs/${params.songId}/arrangements',
    fromJson: (data) => (data as List)
        .map((e) => ArrangementResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  return response.data ?? [];
});
