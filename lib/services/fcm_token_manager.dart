import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../api/services/session_api_service.dart';
import '../api/services/api_client.dart';

class FcmTokenManager {
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmRegisteredKey = 'fcm_registered';

  final SessionApiService _sessionApi;

  FcmTokenManager({SessionApiService? sessionApi})
      : _sessionApi = sessionApi ?? SessionApiService();

  /// دریافت توکن جدید FCM و ثبت آن در سرور
  Future<void> refreshAndRegisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString(_fcmTokenKey);

      // دریافت توکن جدید
      final newToken = await FirebaseMessaging.instance.getToken();

      if (newToken == null) {
        debugPrint('❌ Failed to get FCM token');
        return;
      }

      // اگر توکن تغییر کرده باشد یا اولین بار است
      if (oldToken != newToken) {
        debugPrint('🔄 FCM token changed. Registering new token...');

        // بررسی JWT قبل از ثبت - اگر نداشته باشیم، ابتدا session جدید ایجاد می‌کنیم
        final response = await _ensureValidSessionAndRegister(newToken);

        if (response.status) {
          // ذخیره توکن جدید و وضعیت ثبت
          await prefs.setString(_fcmTokenKey, newToken);
          await prefs.setBool(_fcmRegisteredKey, true);
          debugPrint('✅ FCM token registered successfully');
        } else {
          debugPrint('❌ Failed to register FCM token: ${response.message}');
          // در صورت شکست، وضعیت ثبت را false می‌کنیم
          await prefs.setBool(_fcmRegisteredKey, false);
        }
      } else {
        debugPrint('ℹ️ FCM token unchanged');
      }
    } catch (e) {
      debugPrint('❌ Error in refreshAndRegisterToken: $e');
    }
  }

  /// تضمین وجود session معتبر و ثبت FCM token
  Future<dynamic> _ensureValidSessionAndRegister(String fcmToken) async {
    // اگر JWT داریم، مستقیماً سعی در ثبت می‌کنیم
    final currentJwt = ApiClient.jwt;
    if (currentJwt != null && currentJwt.isNotEmpty) {
      final result = await _sessionApi.initSession(fcmToken);
      if (result.status) {
        return result;
      }
      // اگر JWT معتبر نبود، ادامه می‌دهیم تا session جدید ایجاد کنیم
      debugPrint('🔄 Current JWT might be invalid, creating new session');
    }

    // ایجاد session جدید با FCM token
    debugPrint('🆕 Creating new session with FCM token');
    return await _sessionApi.initSession(fcmToken);
  }

  /// بررسی وضعیت توکن در هنگام راه‌اندازی برنامه
  Future<void> checkTokenOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool(_fcmRegisteredKey) ?? false;

      if (!isRegistered) {
        debugPrint('🆕 First time FCM registration');
        await refreshAndRegisterToken();
      } else {
        // بررسی صحت توکن فعلی
        final storedToken = prefs.getString(_fcmTokenKey);
        final currentToken = await FirebaseMessaging.instance.getToken();

        if (storedToken != currentToken) {
          debugPrint(
              '🔄 Stored FCM token is different from current. Updating...');
          await refreshAndRegisterToken();
        }
      }
    } catch (e) {
      debugPrint('❌ Error in checkTokenOnStartup: $e');
    }
  }

  /// تنظیم listener برای تغییرات توکن
  void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed automatically');
      refreshAndRegisterToken();
    });
  }
}
