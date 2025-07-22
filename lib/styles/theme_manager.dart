import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

/// کلاس مدیریت تم اپلیکیشن
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// دریافت تم روشن (همان تم تاریک)
  ThemeData get lightTheme => AppThemes.darkTheme;

  /// دریافت تم تاریک
  ThemeData get darkTheme => AppThemes.darkTheme;

  /// بارگذاری تنظیمات تم از SharedPreferences
  Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey) ?? 0;

      switch (savedThemeIndex) {
        case 0:
          _themeMode = ThemeMode.system;
          break;
        case 1:
          _themeMode = ThemeMode.light;
          break;
        case 2:
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      // در صورت بروز خطا، از تم سیستم استفاده کن
      _themeMode = ThemeMode.system;
    }
  }

  /// ذخیره تنظیمات تم در SharedPreferences
  Future<void> saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int themeIndex;

      switch (_themeMode) {
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
    _themeMode = ThemeMode.system;
    notifyListeners();
    await saveThemeMode();
  }

  /// تغییر به تم روشن
  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
    notifyListeners();
    await saveThemeMode();
  }

  /// تغییر به تم تاریک
  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
    notifyListeners();
    await saveThemeMode();
  }

  /// تغییر بین روشن و تاریک
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkTheme();
    } else if (_themeMode == ThemeMode.dark) {
      await setLightTheme();
    } else {
      // اگر سیستم است، به تاریک تغییر بده
      await setDarkTheme();
    }
  }

  /// بررسی اینکه آیا تم فعلی تاریک است یا نه (بر اساس brightness سیستم)
  bool isDarkModeActive(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
    }
  }

  /// دریافت نام تم فعلی
  String get themeName {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'سیستم';
      case ThemeMode.light:
        return 'روشن';
      case ThemeMode.dark:
        return 'تاریک';
    }
  }

  /// دریافت آیکون تم فعلی
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_7;
      case ThemeMode.dark:
        return Icons.brightness_2;
    }
  }
}
