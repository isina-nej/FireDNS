import 'package:firedns/services/notification_cache_service.dart';
import 'package:firedns/services/notification_service_provider.dart';
import 'package:firedns/services/welcome_notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// کلاس کمکی برای تست نوتیفیکیشن‌های خوش‌آمدگویی
class WelcomeNotificationTester {
  /// ریست کردن وضعیت نوتیفیکیشن خوش‌آمدگویی (برای تست)
  static Future<void> resetWelcomeStatus() async {
    await WelcomeNotificationManager.resetWelcomeStatus();
    debugPrint('Welcome notification status reset');
  }

  /// پاک کردن همه نوتیفیکیشن‌ها (برای تست)
  static Future<void> clearAllNotifications() async {
    await NotificationCacheService.clearCache();
    debugPrint('All notifications cleared');
  }

  /// ایجاد مجدد نوتیفیکیشن خوش‌آمدگویی
  static Future<void> recreateWelcomeNotification() async {
    try {
      await resetWelcomeStatus();
      await NotificationServiceProvider.checkLanguageChange();
      debugPrint('Welcome notification recreated');
    } catch (e) {
      debugPrint('Error recreating welcome notification: $e');
    }
  }

  /// تست تغییر زبان
  static Future<void> testLanguageChange(String newLanguageCode) async {
    try {
      // شبیه‌سازی تغییر زبان
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', newLanguageCode);

      await NotificationServiceProvider.checkLanguageChange();
      debugPrint('Language change test completed for: $newLanguageCode');
    } catch (e) {
      debugPrint('Error in language change test: $e');
    }
  }
}
