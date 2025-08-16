import 'package:flutter/foundation.dart';
import '../../path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';

/// سرویس مدیریت سشن و احراز هویت
class SessionApiService {
  late final ApiClient _apiClient;
  String? _jwt;

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
      // ذخیره jwt در متغیر داخلی و SharedPreferences
      if (response.data != null) {
        _jwt = response.data!.jwt;
        // ذخیره در SharedPreferences
        // import 'package:shared_preferences/shared_preferences.dart';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt', _jwt!);
        } catch (e) {
          debugPrint('Error saving jwt: $e');
        }
        // ست کردن jwt در ApiClient
        _apiClient.setJwt(_jwt!);
      }
      return response;
    } catch (e) {
      debugPrint('Error initializing session: $e');
      return ApiResponse<SessionData>(
        status: false,
        message: 'خطا در ایجاد سشن: ${e.toString()}',
        errorCode: 'SESSION_INIT_ERROR',
      );
    }
    // ...existing code...
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
