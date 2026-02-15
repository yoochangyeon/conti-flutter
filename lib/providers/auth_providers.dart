import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/core/api/api_client.dart';
import 'package:conti_app/core/storage/secure_storage.dart';
import 'package:conti_app/models/user.dart';

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

// Calendar token
final calendarTokenProvider = FutureProvider<String?>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get<String>(
    '/users/me/calendar-token',
    fromJson: (data) => data as String,
  );
  return response.data;
});
