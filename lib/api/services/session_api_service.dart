import 'package:flutter/foundation.dart';
import '../../path/path.dart';
import '../models/session_data.dart';

/// سرویس مدیریت سشن و احراز هویت
class SessionApiService {
  late final ApiClient _apiClient;

  SessionApiService({ApiClient? apiClient}) {
    _apiClient = apiClient ?? ApiClient();
  }

  /// ایجاد کاربر مهمان و دریافت توکن
  Future<ApiResponse<SessionData>> initSession(String deviceId) async {
    try {
      final response = await _apiClient.post<SessionData>(
        '/api/session/init',
        body: {'deviceId': deviceId},
        fromJson: (data) => SessionData.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error initializing session: $e');
      return ApiResponse<SessionData>(
        status: false,
        message: 'خطا در ایجاد سشن: ${e.toString()}',
        errorCode: 'SESSION_INIT_ERROR',
      );
    }
  }

  /// تمدید سشن
  Future<ApiResponse<SessionData>> refreshSession() async {
    try {
      final response = await _apiClient.post<SessionData>(
        '/api/session/refresh',
        fromJson: (data) => SessionData.fromJson(data),
      );

      return response;
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      return ApiResponse<SessionData>(
        status: false,
        message: 'خطا در تمدید سشن: ${e.toString()}',
        errorCode: 'SESSION_REFRESH_ERROR',
      );
    }
  }

  /// بستن سرویس
  void dispose() {
    _apiClient.dispose();
  }
}
