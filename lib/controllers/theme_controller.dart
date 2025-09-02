import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../path/path.dart';

/// کنترلر مدیریت تم اپلیکیشن با GetX
class ThemeController extends GetxController {
  static const String _themeKey = 'theme_mode';

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;

  ThemeMode get themeMode => _themeMode.value;

  bool get isDarkMode => _themeMode.value == ThemeMode.dark;
  bool get isLightMode => _themeMode.value == ThemeMode.light;
  bool get isSystemMode => _themeMode.value == ThemeMode.system;

  /// دریافت تم روشن
  ThemeData get lightTheme => AppThemes.lightTheme;

  /// دریافت تم تاریک
  ThemeData get darkTheme => AppThemes.darkTheme;

  /// بارگذاری تنظیمات تم از SharedPreferences
  Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey) ?? 0;

      switch (savedThemeIndex) {
        case 0:
          _themeMode.value = ThemeMode.system;
          break;
        case 1:
          _themeMode.value = ThemeMode.light;
          break;
        case 2:
          _themeMode.value = ThemeMode.dark;
          break;
        default:
          _themeMode.value = ThemeMode.system;
      }
      update();
    } catch (e) {
      // در صورت بروز خطا، از تم سیستم استفاده کن
      _themeMode.value = ThemeMode.system;
      update();
    }
  }

  /// ذخیره تنظیمات تم در SharedPreferences
  Future<void> saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int themeIndex;

      switch (_themeMode.value) {
        case ThemeMode.system:
          themeIndex = 0;
          break;
        case ThemeMode.light:
          themeIndex = 1;
          break;
        case ThemeMode.dark:
          themeIndex = 2;
          break;
      }

      await prefs.setInt(_themeKey, themeIndex);
    } catch (e) {
      // خطا در ذخیره - ممکن است نادیده گرفته شود
    }
  }

  /// تغییر به تم سیستم
  Future<void> setSystemTheme() async {
    _themeMode.value = ThemeMode.system;
    update();
    await saveThemeMode();
  }

  /// تغییر به تم روشن
  Future<void> setLightTheme() async {
    _themeMode.value = ThemeMode.light;
    update();
    await saveThemeMode();
  }

  /// تغییر به تم تاریک
  Future<void> setDarkTheme() async {
    _themeMode.value = ThemeMode.dark;
    update();
    await saveThemeMode();
  }

  /// تغییر بین روشن و تاریک
  Future<void> toggleTheme() async {
    if (_themeMode.value == ThemeMode.light) {
      await setDarkTheme();
    } else if (_themeMode.value == ThemeMode.dark) {
      await setLightTheme();
    } else {
      // اگر سیستم است، به تاریک تغییر بده
      await setDarkTheme();
    }
  }

  /// بررسی اینکه آیا تم فعلی تاریک است یا نه (بر اساس brightness سیستم)
  bool isDarkModeActive(BuildContext context) {
    switch (_themeMode.value) {
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
    }
  }

  /// دریافت تم فعلی
  String getCurrentTheme() {
    switch (_themeMode.value) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  /// دریافت نام تم فعلی
  String getThemeName(BuildContext context) {
    switch (_themeMode.value) {
      case ThemeMode.system:
        return context.tr('systemDefault');
      case ThemeMode.light:
        return context.tr('lightMode');
      case ThemeMode.dark:
        return context.tr('darkMode');
    }
  }

  /// تنظیم تم بر اساس مقدار رشته‌ای
  Future<void> setTheme(String theme) async {
    switch (theme) {
      case 'system':
        await setSystemTheme();
        break;
      case 'light':
        await setLightTheme();
        break;
      case 'dark':
        await setDarkTheme();
        break;
      default:
        await setSystemTheme();
        break;
    }
  }

  /// دریافت آیکون تم فعلی
  IconData get themeIcon {
    switch (_themeMode.value) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_7;
      case ThemeMode.dark:
        return Icons.brightness_2;
    }
  }
}
