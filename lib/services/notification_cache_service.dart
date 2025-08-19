import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/models/notification_model.dart';

class NotificationCacheService {
  static const String _notificationsKey = 'cached_notifications';

  /// ذخیره نوتیفیکیشن‌ها در کش
  static Future<bool> cacheNotifications(
      List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // تبدیل به JSON و ذخیره
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      final jsonString = jsonEncode(notificationsJson);
      print('Caching notifications: $jsonString');

      // ذخیره در SharedPreferences
      final success = await prefs.setString(_notificationsKey, jsonString);
      if (!success) {
        print('Failed to save notifications to cache');
        return false;
      }

      // تایید ذخیره‌سازی
      final savedData = prefs.getString(_notificationsKey);
      if (savedData == null) {
        print('Failed to verify cached data');
        return false;
      }
      print('Verified cached data: $savedData');

      return true;
    } catch (e) {
      print('Error caching notifications: $e');
      return false;
    }
  }

  /// دریافت نوتیفیکیشن‌ها از کش
  static Future<List<NotificationModel>> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_notificationsKey);
      print('Reading from cache: $cachedData');

      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final List<dynamic> notificationsJson = jsonDecode(cachedData);
          final notifications = <NotificationModel>[];

          for (final json in notificationsJson) {
            try {
              final notification = NotificationModel.fromJson(json);
              notifications.add(notification);
            } catch (e) {
              print('Error parsing individual notification: $e');
              print('Problematic JSON: $json');
              // ادامه پردازش سایر نوتیفیکیشن‌ها
              continue;
            }
          }

          print(
              'Successfully parsed ${notifications.length} notifications from cache');
          return notifications;
        } catch (e) {
          print('Error decoding JSON from cache: $e');
          print('Invalid cached data: $cachedData');
          // در صورت خطا در کل داده، کش را پاک می‌کنیم
          await clearCache();
        }
      }
    } catch (e) {
      print('Error reading from cache: $e');
    }
    print('No valid cached notifications found, returning empty list');
    return [];
  }

  static const int _maxNotifications =
      50; // حداکثر تعداد نوتیفیکیشن‌های ذخیره شده

  /// افزودن یک نوتیفیکیشن جدید به کش
  static Future<bool> addNotification(NotificationModel notification) async {
    try {
      final notifications = await getCachedNotifications();

      // بررسی وجود نوتیفیکیشن تکراری
      if (notifications.any((n) => n.id == notification.id)) {
        print('Notification with ID ${notification.id} already exists');
        return true;
      }

      // اضافه کردن در ابتدای لیست
      notifications.insert(0, notification);

      // محدود کردن تعداد نوتیفیکیشن‌ها
      if (notifications.length > _maxNotifications) {
        notifications.removeRange(_maxNotifications, notifications.length);
      }

      final success = await cacheNotifications(notifications);
      if (!success) {
        print('Failed to cache notification with ID ${notification.id}');
      }
      return success;
    } catch (e) {
      print('Error adding notification to cache: $e');
      print('Notification details: ${notification.toJson()}');
      return false;
    }
  }

  /// حذف یک نوتیفیکیشن از کش
  static Future<void> removeNotification(String notificationId) async {
    final notifications = await getCachedNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    await cacheNotifications(notifications);
  }

  /// علامت‌گذاری یک نوتیفیکیشن به عنوان خوانده شده
  static Future<void> markAsRead(String notificationId) async {
    final notifications = await getCachedNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await cacheNotifications(notifications);
    }
  }

  /// علامت‌گذاری همه نوتیفیکیشن‌ها به عنوان خوانده شده
  static Future<void> markAllAsRead() async {
    final notifications = await getCachedNotifications();
    final updatedNotifications =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    await cacheNotifications(updatedNotifications);
  }

  /// پاک کردن همه نوتیفیکیشن‌ها از کش
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }
}
