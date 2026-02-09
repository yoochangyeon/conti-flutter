import 'package:dio/dio.dart';
import 'package:conti_app/core/constants/app_constants.dart';
import 'package:conti_app/core/storage/secure_storage.dart';
import 'package:conti_app/core/api/api_response.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;

  ApiClient({required SecureStorage storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _storage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(
        baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
      ));

      final response = await dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(response.data, (data) => data);
        if (apiResponse.success && apiResponse.data != null) {
          final tokenData = apiResponse.data as Map<String, dynamic>;
          await _storage.saveTokens(
            accessToken: tokenData['accessToken'],
            refreshToken: tokenData['refreshToken'],
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Multipart file upload
  Future<ApiResponse<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileFieldName,
    Map<String, dynamic>? fields,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileFieldName: await MultipartFile.fromFile(filePath),
        if (fields != null) ...fields,
      });
      final response = await _dio.post(path, data: formData);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
      return ApiResponse.fromJson(e.response!.data, null);
    }
    return ApiResponse(
      success: false,
      error: ApiError(
        code: 'NETWORK_ERROR',
        message: e.message ?? '네트워크 오류가 발생했습니다.',
      ),
    );
  }

  // Dev login (for testing without OAuth)
  Future<ApiResponse<Map<String, dynamic>>> devLogin() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await dio.post('/dev/test-login');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
}
