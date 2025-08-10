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
    required String userId,
    required String deviceId,
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _apiClient.post<bool>(
        '/api/fcm/register',
        body: {
          'userId': userId,
          'deviceId': deviceId,
          'token': token,
          'platform': platform,
        },
        fromJson: (data) => true,
      );

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
