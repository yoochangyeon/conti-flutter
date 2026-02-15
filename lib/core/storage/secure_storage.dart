import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_impl.dart';

class SecureStorage {
  final FlutterSecureStorage? _storage;

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
      writeWebStorage(key, value);
    } else {
      await _storage!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      return readWebStorage(key);
    }
    return _storage!.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      deleteWebStorage(key);
    } else {
      await _storage!.delete(key: key);
    }
  }
}
