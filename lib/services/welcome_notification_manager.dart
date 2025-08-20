import 'package:shared_preferences/shared_preferences.dart';
import '../api/models/notification_model.dart';
import '../constants/welcome_messages.dart';

/// مدیریت نوتیفیکیشن‌های خوش‌آمدگویی
class WelcomeNotificationManager {
  static const String _welcomeShownKey = 'welcome_notification_shown';
  static const String _lastLanguageKey = 'last_welcome_language';

  /// بررسی اینکه آیا نوتیفیکیشن خوش‌آمدگویی قبلاً نمایش داده شده یا خیر
  static Future<bool> shouldShowWelcomeNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(_welcomeShownKey) ?? false;
      return !hasShown;
    } catch (e) {
      print('Error checking welcome notification status: $e');
      return true; // در صورت خطا، نوتیفیکیشن نمایش داده شود
    }
  }

  /// بررسی اینکه آیا زبان تغییر کرده و نیاز به نوتیفیکیشن جدید هست
  static Future<bool> shouldUpdateWelcomeForLanguageChange() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLanguage = prefs.getString('language_code') ?? 'fa';
      final lastWelcomeLanguage = prefs.getString(_lastLanguageKey);

      return lastWelcomeLanguage != null &&
          lastWelcomeLanguage != currentLanguage &&
          WelcomeMessages.supportedLanguages.contains(currentLanguage);
    } catch (e) {
      print('Error checking language change for welcome: $e');
      return false;
    }
  }

  /// علامت‌گذاری نمایش نوتیفیکیشن خوش‌آمدگویی
  static Future<void> markWelcomeNotificationShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLanguage = prefs.getString('language_code') ?? 'fa';

      await prefs.setBool(_welcomeShownKey, true);
      await prefs.setString(_lastLanguageKey, currentLanguage);
    } catch (e) {
      print('Error marking welcome notification as shown: $e');
    }
  }

  /// ایجاد نوتیفیکیشن خوش‌آمدگویی
  static Future<NotificationModel> createWelcomeNotification({
    String? languageCode,
  }) async {
    // تشخیص زبان
    String targetLanguage = languageCode ?? await _getCurrentLanguage();

    // اگر زبان پشتیبانی نمی‌شود، از انگلیسی استفاده کن
    if (!WelcomeMessages.supportedLanguages.contains(targetLanguage)) {
      targetLanguage = 'en';
    }

    // دریافت پیام خوش‌آمدگویی
    final welcomeTitle = WelcomeMessages.getWelcomeTitle(targetLanguage);
    final welcomeMessage =
        WelcomeMessages.getWelcomeMessageText(targetLanguage);

    // ایجاد نوتیفیکیشن
    return NotificationModel(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      title: welcomeTitle,
      message: welcomeMessage,
      date: DateTime.now(),
      type: NotificationType.success,
      isRead: false,
    );
  }

  /// دریافت زبان فعلی کاربر
  static Future<String> _getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('language_code') ?? 'fa';
    } catch (e) {
      print('Error getting current language: $e');
      return 'fa';
    }
  }

  /// ریست کردن وضعیت نوتیفیکیشن خوش‌آمدگویی (برای تست)
  static Future<void> resetWelcomeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_welcomeShownKey);
      await prefs.remove(_lastLanguageKey);
    } catch (e) {
      print('Error resetting welcome status: $e');
    }
  }
}
