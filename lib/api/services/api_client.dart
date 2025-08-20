import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../path/path.dart';

const String baseApiUrl = 'https://api.fire-dns.ir';

/// کلاس مدیریت درخواست‌های HTTP
class ApiClient {
  // دسترسی فقط خواندنی به مقدار فعلی JWT
  static String? get jwt => _jwt;
  // متد برای ست کردن jwt به صورت static تا در همه instanceها اعمال شود
  static void setJwt(String jwt) {
    debugPrint('[APIClient][JWT] setJwt called with: $jwt');
    _jwt = jwt;
    debugPrint('[APIClient][JWT] _jwt is now: $_jwt');
  }

  static const String baseUrl = baseApiUrl;
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;
  final Map<String, String> _defaultHeaders;
  static String? _jwt;

  ApiClient({http.Client? client})
      : _client = client ?? http.Client(),
        _defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

  /// درخواست GET
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final mergedHeaders = {..._defaultHeaders, ...?headers};
      if (ApiClient._jwt != null) {
        debugPrint(
            '[APIClient][JWT] Adding Authorization header: Bearer ${ApiClient._jwt}');
        mergedHeaders['Authorization'] = 'Bearer ${ApiClient._jwt}';
      } else {
        debugPrint(
            '[APIClient][JWT] No JWT set, Authorization header will NOT be added.');
      }

      debugPrint('GET Request: $uri');
      debugPrint('Headers: $mergedHeaders');

      final response =
          await _client.get(uri, headers: mergedHeaders).timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('GET Error: $e');
      return _handleError<T>(e);
    }
  }

  /// درخواست POST
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._defaultHeaders, ...?headers};
      if (ApiClient._jwt != null) {
        debugPrint(
            '[APIClient][JWT] Adding Authorization header: Bearer ${ApiClient._jwt}');
        mergedHeaders['Authorization'] = 'Bearer ${ApiClient._jwt}';
      } else {
        debugPrint(
            '[APIClient][JWT] No JWT set, Authorization header will NOT be added.');
      }
      final jsonBody = body != null ? jsonEncode(body) : null;

      debugPrint('[APIClient][POST] Request: $uri');
      debugPrint('[APIClient][POST] Headers: $mergedHeaders');
      debugPrint('[APIClient][POST] Body: $jsonBody');

      final response = await _client
          .post(uri, headers: mergedHeaders, body: jsonBody)
          .timeout(_timeout);

      debugPrint('[APIClient][POST] Response Status: ${response.statusCode}');
      debugPrint('[APIClient][POST] Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('POST Error: $e');
      return _handleError<T>(e);
    }
  }

  /// درخواست PATCH
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._defaultHeaders, ...?headers};
      if (ApiClient._jwt != null) {
        debugPrint(
            '[APIClient][JWT] Adding Authorization header: Bearer ${ApiClient._jwt}');
        mergedHeaders['Authorization'] = 'Bearer ${ApiClient._jwt}';
      } else {
        debugPrint(
            '[APIClient][JWT] No JWT set, Authorization header will NOT be added.');
      }
      final jsonBody = body != null ? jsonEncode(body) : null;

      debugPrint('PATCH Request: $uri');
      debugPrint('Headers: $mergedHeaders');
      debugPrint('Body: $jsonBody');

      final response = await _client
          .patch(uri, headers: mergedHeaders, body: jsonBody)
          .timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('PATCH Error: $e');
      return _handleError<T>(e);
    }
  }

  /// درخواست PUT
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._defaultHeaders, ...?headers};
      if (ApiClient._jwt != null) {
        debugPrint(
            '[APIClient][JWT] Adding Authorization header: Bearer ${ApiClient._jwt}');
        mergedHeaders['Authorization'] = 'Bearer ${ApiClient._jwt}';
      } else {
        debugPrint(
            '[APIClient][JWT] No JWT set, Authorization header will NOT be added.');
      }
      final jsonBody = body != null ? jsonEncode(body) : null;

      debugPrint('PUT Request: $uri');
      debugPrint('Headers: $mergedHeaders');
      debugPrint('Body: $jsonBody');

      final response = await _client
          .put(uri, headers: mergedHeaders, body: jsonBody)
          .timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('PUT Error: $e');
      return _handleError<T>(e);
    }
  }

  /// درخواست DELETE
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._defaultHeaders, ...?headers};
      if (ApiClient._jwt != null) {
        debugPrint(
            '[APIClient][JWT] Adding Authorization header: Bearer ${ApiClient._jwt}');
        mergedHeaders['Authorization'] = 'Bearer ${ApiClient._jwt}';
      } else {
        debugPrint(
            '[APIClient][JWT] No JWT set, Authorization header will NOT be added.');
      }

      debugPrint('DELETE Request: $uri');
      debugPrint('Headers: $mergedHeaders');

      final response =
          await _client.delete(uri, headers: mergedHeaders).timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return _handleError<T>(e);
    }
  }

  /// ساخت URI
  Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$baseUrl$path');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }

    return uri;
  }

  /// مدیریت پاسخ
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    try {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse<T>.fromJson(jsonData, fromJson);
        } else {
          return ApiResponse<T>(
            status: false,
            message: jsonData['message'] as String? ?? 'خطای سرور',
            errorCode: jsonData['errorCode']?.toString(),
          );
        }
      } else {
        // JSON is not a map (unexpected)
        return ApiResponse<T>(
          status: false,
          message: 'پاسخ سرور نامعتبر است',
          errorCode: 'INVALID_JSON',
        );
      }
    } catch (e) {
      debugPrint('JSON Parse Error: $e');
      return ApiResponse<T>(
        status: false,
        message: 'خطا در تجزیه پاسخ سرور',
        errorCode: 'JSON_PARSE_ERROR',
      );
    }
  }

  /// مدیریت خطا
  ApiResponse<T> _handleError<T>(dynamic error) {
    // گزارش خطا به سرور در پس‌زمینه
    Future(() {
      try {
        ErrorReporter.reportNetworkError(
          endpoint: 'api_request',
          error: error.toString(),
          statusCode: error is HttpException ? 500 : null,
        );
      } catch (e) {
        debugPrint('[ApiClient] Failed to report network error: $e');
      }
    });

    if (error is SocketException) {
      return ApiResponse<T>(
        status: false,
        message: 'خطا در اتصال به اینترنت',
        errorCode: 'NETWORK_ERROR',
      );
    } else if (error is HttpException) {
      return ApiResponse<T>(
        status: false,
        message: 'خطای HTTP: ${error.message}',
        errorCode: 'HTTP_ERROR',
      );
    } else if (error.toString().contains('TimeoutException')) {
      return ApiResponse<T>(
        status: false,
        message: 'درخواست منقضی شد',
        errorCode: 'TIMEOUT_ERROR',
      );
    } else {
      return ApiResponse<T>(
        status: false,
        message: 'خطای نامشخص: ${error.toString()}',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// بستن client
  void dispose() {
    _client.close();
  }
}
