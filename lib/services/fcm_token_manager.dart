import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firedns/api/services/api_client.dart';
import 'package:firedns/api/services/fcm_api_service.dart';
import 'package:firedns/api/services/session_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmTokenManager {
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmRegisteredKey = 'fcm_registered';

  final SessionApiService _sessionApi;
  final FcmApiService _fcmApi;

  FcmTokenManager({SessionApiService? sessionApi, FcmApiService? fcmApi})
      : _sessionApi = sessionApi ?? SessionApiService(),
        _fcmApi = fcmApi ?? FcmApiService();

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
    // مرحله 1: تضمین وجود JWT معتبر
    await _ensureValidSession(fcmToken);

    // مرحله 2: ثبت FCM token در endpoint مخصوص
    final platform = Platform.isIOS ? 'ios' : 'android';
    final fcmResult = await _fcmApi.registerFcmToken(
      deviceId: fcmToken,
      fcmToken: fcmToken,
      platform: platform,
    );

    if (fcmResult.status) {
      debugPrint('✅ FCM token registered successfully in /api/fcm/register');
    } else {
      debugPrint('❌ Failed to register FCM token: ${fcmResult.message}');
    }

    return fcmResult;
  }

  /// تضمین وجود JWT معتبر
  Future<void> _ensureValidSession(String fcmToken) async {
    final currentJwt = ApiClient.jwt;
    if (currentJwt != null && currentJwt.isNotEmpty) {
      // JWT موجود است، فعلاً فرض می‌کنیم معتبر است
      debugPrint('ℹ️ Using existing JWT for FCM registration');
      return;
    }

    // اگر JWT نداریم، session جدید ایجاد می‌کنیم
    debugPrint('🆕 Creating new session for FCM token registration');
    final sessionResult = await _sessionApi.initSession(fcmToken);
    if (!sessionResult.status) {
      throw Exception('Failed to create session: ${sessionResult.message}');
    }
    debugPrint('✅ New session created successfully');
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
