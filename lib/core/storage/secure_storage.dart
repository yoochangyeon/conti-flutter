import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:conti_app/core/constants/app_constants.dart';

class SecureStorage {
  final FlutterSecureStorage? _storage;

  /// 웹에서는 flutter_secure_storage의 Web Crypto API 초기화 문제로
  /// 비동기 작업이 행(hang)될 수 있어 in-memory 저장소를 사용한다.
  static final Map<String, String> _webStore = {};

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = kIsWeb ? null : (storage ?? const FlutterSecureStorage());

  Future<void> saveAccessToken(String token) async {
    await _write(AppConstants.accessTokenKey, token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _write(AppConstants.refreshTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    return _read(AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _read(AppConstants.refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _delete(AppConstants.accessTokenKey),
      _delete(AppConstants.refreshTokenKey),
    ]);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _webStore[key] = value;
    } else {
      await _storage!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      return _webStore[key];
    }
    return _storage!.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      _webStore.remove(key);
    } else {
      await _storage!.delete(key: key);
    }
  }
}
