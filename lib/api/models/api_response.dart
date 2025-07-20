/// مدل پاسخ کلی API
class ApiResponse<T> {
  final bool status;
  final String message;
  final String? errorCode;
  final T? data;

  const ApiResponse({
    required this.status,
    this.message = 'پیام خطا موجود نیست',
    this.errorCode,
    this.data,
  });

  /// Factory constructor برای ایجاد از JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] as bool,
      message: json['message'] as String,
      errorCode: json['errorCode'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson([dynamic Function(T)? toJsonT]) {
    return {
      'status': status,
      'message': message,
      'errorCode': errorCode,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
    };
  }

  /// بررسی موفقیت آمیز بودن درخواست
  bool get isSuccess => status && errorCode == null;

  /// بررسی وجود خطا
  bool get hasError => !status || errorCode != null;

  /// دریافت پیام خطا
  String get errorMessage {
    if (hasError) {
      return errorCode != null ? '$message (کد خطا: $errorCode)' : message;
    }
    return '';
  }

  @override
  String toString() {
    return 'ApiResponse(status: $status, message: $message, errorCode: $errorCode, data: $data)';
  }
}

/// مدل خطاهای API
class ApiException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const ApiException({required this.message, this.errorCode, this.statusCode});

  @override
  String toString() {
    String result = 'ApiException: $message';
    if (errorCode != null) result += ' (کد خطا: $errorCode)';
    if (statusCode != null) result += ' (HTTP: $statusCode)';
    return result;
  }
}

/// انواع خطاهای شناخته شده API
enum ApiErrorCode {
  networkError,
  serverError,
  unauthorized,
  notFound,
  validationError,
  dbConnectionFail,
  unknown,
}

/// تبدیل کد خطای API به enum
ApiErrorCode parseErrorCode(String? errorCode) {
  if (errorCode == null) return ApiErrorCode.unknown;

  switch (errorCode.toUpperCase()) {
    case 'DB_CONN_FAIL':
      return ApiErrorCode.dbConnectionFail;
    case 'VALIDATION_ERROR':
      return ApiErrorCode.validationError;
    case 'UNAUTHORIZED':
      return ApiErrorCode.unauthorized;
    case 'NOT_FOUND':
      return ApiErrorCode.notFound;
    case 'NETWORK_ERROR':
      return ApiErrorCode.networkError;
    case 'SERVER_ERROR':
      return ApiErrorCode.serverError;
    default:
      return ApiErrorCode.unknown;
  }
}

/// Extension برای کار راحت‌تر با ApiErrorCode
extension ApiErrorCodeExtension on ApiErrorCode {
  /// پیام فارسی خطا
  String get persianMessage {
    switch (this) {
      case ApiErrorCode.networkError:
        return 'خطا در اتصال به اینترنت';
      case ApiErrorCode.serverError:
        return 'خطا در سرور';
      case ApiErrorCode.unauthorized:
        return 'دسترسی غیرمجاز';
      case ApiErrorCode.notFound:
        return 'موردی یافت نشد';
      case ApiErrorCode.validationError:
        return 'خطا در اعتبارسنجی داده‌ها';
      case ApiErrorCode.dbConnectionFail:
        return 'خطا در اتصال به پایگاه داده';
      case ApiErrorCode.unknown:
        return 'خطای نامشخص';
    }
  }
}
