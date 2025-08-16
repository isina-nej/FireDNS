import 'package:flutter/foundation.dart';
import '../../path/path.dart';
import '../../services/fcm_service.dart';

/// سرویس مدیریت نوتیفیکیشن‌ها (FCM)
class FcmApiService {
  late final ApiClient _apiClient;
  late final FcmService _fcmService;

  FcmApiService({ApiClient? apiClient}) {
    _apiClient = apiClient ?? ApiClient();
    _fcmService = FcmService();
    _initializeFcm();
  }

  Future<void> _initializeFcm() async {
    try {
      await _fcmService.initialize();
    } catch (e) {
      debugPrint('Error initializing FCM service: $e');
    }
  }

  /// ثبت توکن FCM
  Future<ApiResponse<bool>> registerFcmToken({
    required String deviceId,
    required String fcmToken,
    required String platform,
  }) async {
    try {
      final requestBody = {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': platform,
      };
      debugPrint('[FCM_REGISTER] زمان ارسال: ${DateTime.now()}');
      debugPrint('[FCM_REGISTER] داده ارسالی: $requestBody');
      debugPrint(
          '[FCM_REGISTER] هدرهای پیش‌فرض: Content-Type: application/json, Accept: application/json');
      // JWT فقط اگر قبلاً ست شده باشد در هدر Authorization قرار می‌گیرد و قابل دسترسی مستقیم نیست
      final response = await _apiClient.post<bool>(
        '/api/fcm/register',
        body: requestBody,
        fromJson: (data) => true,
      );
      debugPrint('[FCM_REGISTER] زمان دریافت پاسخ: ${DateTime.now()}');
      debugPrint('[FCM_REGISTER] پاسخ دریافتی: ${response.toJson()}');
      if (!response.status) {
        debugPrint(
            '[FCM_REGISTER] خطا: ${response.message} | کد خطا: ${response.errorCode}');
      }
      return response;
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در ثبت توکن: ${e.toString()}',
        errorCode: 'FCM_REGISTER_ERROR',
      );
    }
  }

  /// حذف توکن FCM
  Future<ApiResponse<bool>> unregisterFcmToken({
    required String deviceId,
  }) async {
    try {
      final response = await _apiClient.delete<bool>(
        '/api/fcm/unregister?deviceId=$deviceId',
        fromJson: (data) => true,
      );
      return response;
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در حذف توکن: ${e.toString()}',
        errorCode: 'FCM_UNREGISTER_ERROR',
      );
    }
  }

  /// ارسال نوتیفیکیشن (فقط ادمین)
  Future<ApiResponse<bool>> sendNotification({
    required String title,
    required String body,
    required List<String> tokens,
  }) async {
    try {
      final response = await _apiClient.post<bool>(
        '/api/fcm/send',
        body: {'title': title, 'body': body, 'tokens': tokens},
        fromJson: (data) => true,
      );

      return response;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در ارسال نوتیفیکیشن: ${e.toString()}',
        errorCode: 'SEND_NOTIFICATION_ERROR',
      );
    }
  }

  /// بستن سرویس
  void dispose() {
    _apiClient.dispose();
  }
}
