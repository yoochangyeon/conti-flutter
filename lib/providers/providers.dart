import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/core/api/api_client.dart';
import 'package:conti_app/core/api/api_response.dart';
import 'package:conti_app/core/storage/secure_storage.dart';
import 'package:conti_app/models/user.dart';
import 'package:conti_app/models/team.dart';
import 'package:conti_app/models/song.dart';
import 'package:conti_app/models/setlist.dart';

// Core providers
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storage: ref.watch(secureStorageProvider));
});

// Auth state
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserResponse? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserResponse? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthNotifier(this._api, this._storage) : super(const AuthState());

  Future<void> checkAuth() async {
    final hasToken = await _storage.hasTokens();
    if (!hasToken) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    await fetchUser();
  }

  Future<void> fetchUser() async {
    final response = await _api.get<UserResponse>(
      '/users/me',
      fromJson: (data) => UserResponse.fromJson(data),
    );
    if (response.success && response.data != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.data,
      );
    } else {
      await _storage.clearTokens();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> devLogin() async {
    final response = await _api.devLogin();
    if (response.success && response.data != null) {
      final tokenData = response.data!;
      await _storage.saveTokens(
        accessToken: tokenData['accessToken'] as String,
        refreshToken: tokenData['refreshToken'] as String,
      );
      await fetchUser();
      return true;
    }
    state = state.copyWith(error: response.error?.message ?? '로그인 실패');
    return false;
  }

  Future<bool> loginWithProvider(String provider, String code) async {
    final response = await _api.post<TokenResponse>(
      '/auth/login/$provider',
      data: {'code': code},
      fromJson: (data) => TokenResponse.fromJson(data),
    );
    if (response.success && response.data != null) {
      await _storage.saveTokens(
        accessToken: response.data!.accessToken,
        refreshToken: response.data!.refreshToken,
      );
      await fetchUser();
      return true;
    }
    state = state.copyWith(error: response.error?.message ?? '로그인 실패');
    return false;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> updateProfile(UserUpdateRequest request) async {
    final response = await _api.patch<UserResponse>(
      '/users/me',
      data: request.toJson(),
      fromJson: (data) => UserResponse.fromJson(data),
    );
    if (response.success && response.data != null) {
      state = state.copyWith(user: response.data);
      return true;
    }
    return false;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

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

// Setlists (paginated)
class SetlistListParams {
  final int teamId;
  final int page;
  final String? worshipType;
  final DateTime? fromDate;
  final DateTime? toDate;

  SetlistListParams({
    required this.teamId,
    this.page = 0,
    this.worshipType,
    this.fromDate,
    this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetlistListParams &&
          teamId == other.teamId &&
          page == other.page &&
          worshipType == other.worshipType;

  @override
  int get hashCode => Object.hash(teamId, page, worshipType);
}

final setlistsProvider = FutureProvider.family<PagedData<SetlistResponse>, SetlistListParams>(
    (ref, params) async {
  final api = ref.watch(apiClientProvider);
  final queryParams = <String, dynamic>{
    'page': params.page,
    'size': 20,
    if (params.worshipType != null) 'worshipType': params.worshipType,
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
