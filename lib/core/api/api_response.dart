class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  ApiResponse({required this.success, this.data, this.error});

  /// Whether the response indicates a forbidden (403) error.
  bool get isForbidden => !success && (error?.isForbidden ?? false);

  /// Whether the response indicates a not-found (404) error.
  bool get isNotFound => !success && (error?.isNotFound ?? false);

  /// Whether the response indicates a server (500) error.
  bool get isServerError => !success && (error?.isServerError ?? false);

  /// Whether the response indicates a network error (no server response).
  bool get isNetworkError => !success && (error?.isNetworkError ?? false);

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;

  ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  /// Whether this is a network-level error (no server response).
  bool get isNetworkError => code == 'NETWORK_ERROR';

  /// Whether the server returned 403 Forbidden.
  bool get isForbidden => code == 'FORBIDDEN' || code == 'ACCESS_DENIED';

  /// Whether the requested resource was not found (404).
  bool get isNotFound => code == 'NOT_FOUND';

  /// Whether the server returned an internal error (500).
  bool get isServerError => code == 'INTERNAL_SERVER_ERROR';

  /// Whether the request was invalid (400 Bad Request / validation errors).
  bool get isBadRequest => code == 'BAD_REQUEST' || code == 'VALIDATION_ERROR';

  /// Whether authentication failed or token is invalid (401).
  bool get isUnauthorized => code == 'UNAUTHORIZED';
}

class PagedData<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;

  PagedData({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory PagedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedData(
      content: (json['content'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      number: json['number'] as int,
      size: json['size'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
    );
  }
}
