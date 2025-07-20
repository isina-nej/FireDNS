import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';

/// کلاس مدیریت درخواست‌های HTTP
class ApiClient {
  static const String _baseUrl = 'https://dns-changer-0.vercel.app';
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;
  final Map<String, String> _defaultHeaders;

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

      debugPrint('GET Request: $uri');
      debugPrint('Headers: $mergedHeaders');

      final response = await _client
          .get(uri, headers: mergedHeaders)
          .timeout(_timeout);

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
      final jsonBody = body != null ? jsonEncode(body) : null;

      debugPrint('POST Request: $uri');
      debugPrint('Headers: $mergedHeaders');
      debugPrint('Body: $jsonBody');

      final response = await _client
          .post(uri, headers: mergedHeaders, body: jsonBody)
          .timeout(_timeout);

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

  /// درخواست DELETE
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._defaultHeaders, ...?headers};

      debugPrint('DELETE Request: $uri');
      debugPrint('Headers: $mergedHeaders');

      final response = await _client
          .delete(uri, headers: mergedHeaders)
          .timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return _handleError<T>(e);
    }
  }

  /// ساخت URI
  Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$_baseUrl$path');

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
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>.fromJson(jsonData, fromJson);
      } else {
        return ApiResponse<T>(
          status: false,
          message: jsonData['message'] as String? ?? 'خطای سرور',
          errorCode: jsonData['errorCode'] as String?,
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
