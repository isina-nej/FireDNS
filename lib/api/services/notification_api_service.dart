import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';

/// سرویس API برای دریافت اعلانات
class NotificationApiService {
  final ApiClient _apiClient;
  
  NotificationApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// دریافت لیست اعلانات
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _apiClient.get<List<NotificationModel>>(
        '/api/notifications', // endpoint
        fromJson: (data) {
          final List<dynamic> jsonList = data as List<dynamic>;
          return jsonList
              .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
              .toList();
        },
      );
      return response;
    } catch (e, stackTrace) {
      debugPrint('Error in getNotifications: $e');
      debugPrintStack(stackTrace: stackTrace);
      return ApiResponse<List<NotificationModel>>(
        status: false,
        message: 'خطا در دریافت اعلانات',
        errorCode: 'NOTIFICATIONS_ERROR',
      );
    }
  }

  /// علامت‌گذاری اعلان به عنوان خوانده شده
  Future<ApiResponse<bool>> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.post<bool>(
        '/api/notifications/$notificationId/read', // endpoint
        fromJson: (data) => data as bool? ?? false,
      );
      return response;
    } catch (e, stackTrace) {
      debugPrint('Error in markAsRead: $e');
      debugPrintStack(stackTrace: stackTrace);
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در به‌روزرسانی وضعیت اعلان',
        errorCode: 'MARK_READ_ERROR',
      );
    }
  }

  /// علامت‌گذاری همه اعلانات به عنوان خوانده شده
  Future<ApiResponse<bool>> markAllAsRead() async {
    try {
      final response = await _apiClient.post<bool>(
        '/api/notifications/read-all', // endpoint
        fromJson: (data) => data as bool? ?? false,
      );
      return response;
    } catch (e, stackTrace) {
      debugPrint('Error in markAllAsRead: $e');
      debugPrintStack(stackTrace: stackTrace);
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در به‌روزرسانی وضعیت اعلانات',
        errorCode: 'MARK_ALL_READ_ERROR',
      );
    }
  }

  /// حذف اعلان
  Future<ApiResponse<bool>> deleteNotification(String notificationId) async {
    try {
      final response = await _apiClient.delete<bool>(
        '/api/notifications/$notificationId', // endpoint
        fromJson: (data) => data as bool? ?? false,
      );
      return response;
    } catch (e, stackTrace) {
      debugPrint('Error in deleteNotification: $e');
      debugPrintStack(stackTrace: stackTrace);
      return ApiResponse<bool>(
        status: false,
        message: 'خطا در حذف اعلان',
        errorCode: 'DELETE_NOTIFICATION_ERROR',
      );
    }
  }

  /// بستن client
  void dispose() {
    _apiClient.dispose();
  }
}