import 'package:firedns/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firedns/styles/language_manager.dart';

/// سرویس مدیریت تنظیمات تست DNS
class DnsTestSettingsService extends ChangeNotifier {
  static const String _testTypeKey = 'dns_test_type';
  static const String _testCountKey = 'dns_test_count';

  String _testType = 'auto'; // پیش‌فرض: تست خودکار
  int _testCount = 5; // پیش‌فرض: 5 تست

  /// نوع تست فعلی
  String get testType => _testType;

  /// تعداد تست فعلی
  int get testCount => _testCount;

  /// نمایش منوی تست - بر اساس نوع تست
  bool get showTestMenu => _testType == 'auto';

  /// بارگذاری تنظیمات از SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _testType = prefs.getString(_testTypeKey) ?? 'auto';
      _testCount = prefs.getInt(_testCountKey) ?? 5;
      notifyListeners();
    } catch (e) {
      // در صورت بروز خطا، از مقادیر پیش‌فرض استفاده کن
      _testType = 'auto';
      _testCount = 5;
    }
  }

  /// ذخیره تنظیمات در SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_testTypeKey, _testType);
      await prefs.setInt(_testCountKey, _testCount);
    } catch (e) {
      // خطا در ذخیره
    }
  }

  /// تغییر نوع تست
  Future<void> setTestType(String type) async {
    if (type != _testType) {
      _testType = type;
      notifyListeners();
      await saveSettings();
    }
  }

  /// تغییر تعداد تست
  Future<void> setTestCount(int count) async {
    if (count != _testCount) {
      _testCount = count;
      notifyListeners();
      await saveSettings();
    }
  }

  /// نام نوع تست به فارسی
  String getTestTypeName(String type, BuildContext context) {
    switch (type) {
      case 'simultaneous':
        return context.tr('simultaneousTest');
      case 'sequential':
        return context.tr('sequentialTest');
      case 'advanced':
        return context.tr('advancedTest');
      case 'auto':
        return context.tr('autoTest');
      default:
        return context.tr('simultaneousTest');
    }
  }
}
