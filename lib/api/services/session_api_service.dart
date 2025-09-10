import 'package:firedns/api/models/session_data.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        ApiClient.setJwt(_jwt!);
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
      // قبل از درخواست refresh، jwt قبلی را از SharedPreferences می‌خوانیم
      final prefs = await SharedPreferences.getInstance();
      final currentJwt = prefs.getString('jwt');

      // اگر jwt وجود ندارد، یک سشن جدید ایجاد می‌کنیم
      if (currentJwt == null || currentJwt.isEmpty) {
        // اینجا می‌توانیم از initSession استفاده کنیم یا کاربر را به صفحه ورود هدایت کنیم
        return const ApiResponse<SessionData>(
          status: false,
          message: 'لطفا دوباره وارد شوید.',
          errorCode: 'NO_JWT_ERROR',
        );
      }

      ApiClient.setJwt(currentJwt);

      final response = await _apiClient.post<SessionData>(
        '/api/session/refresh',
        fromJson: (data) => SessionData.fromJson(data),
      );

      // اگر پاسخ موفق بود و jwt جدید داشت، آن را ذخیره می‌کنیم
      if (response.status && response.data?.jwt != null) {
        await prefs.setString('jwt', response.data!.jwt);
        ApiClient.setJwt(response.data!.jwt);
      }

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
