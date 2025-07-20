import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// کلاس مدیریت زبان اپلیکیشن
class LanguageManager extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  static const String _countryKey = 'country_code';

  Locale _locale = const Locale('fa', 'IR'); // پیش‌فرض فارسی

  Locale get locale => _locale;

  bool get isFarsi => _locale.languageCode == 'fa';
  bool get isEnglish => _locale.languageCode == 'en';

  /// جهت متن بر اساس زبان
  TextDirection get textDirection =>
      _locale.languageCode == 'fa' ? TextDirection.rtl : TextDirection.ltr;

  /// نام زبان فعلی
  String get languageName => _locale.languageCode == 'fa' ? 'فارسی' : 'English';

  /// آیکون زبان فعلی
  String get languageFlag => _locale.languageCode == 'fa' ? '🇮🇷' : '🇺🇸';

  /// بارگذاری تنظیمات زبان از SharedPreferences
  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'fa';
      final countryCode = prefs.getString(_countryKey) ?? 'IR';

      _locale = Locale(languageCode, countryCode);
      notifyListeners();
    } catch (e) {
      // در صورت بروز خطا، از زبان پیش‌فرض استفاده کن
      _locale = const Locale('fa', 'IR');
    }
  }

  /// ذخیره تنظیمات زبان در SharedPreferences
  Future<void> saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _locale.languageCode);
      await prefs.setString(_countryKey, _locale.countryCode ?? '');
    } catch (e) {
      // خطا در ذخیره
    }
  }

  /// تغییر به زبان فارسی
  Future<void> setFarsi() async {
    _locale = const Locale('fa', 'IR');
    notifyListeners();
    await saveLanguage();
  }

  /// تغییر به زبان انگلیسی
  Future<void> setEnglish() async {
    _locale = const Locale('en', 'US');
    notifyListeners();
    await saveLanguage();
  }

  /// تغییر بین زبان‌ها
  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'fa') {
      await setEnglish();
    } else {
      await setFarsi();
    }
  }

  /// زبان‌های پشتیبانی شده
  static const List<Locale> supportedLocales = [
    Locale('fa', 'IR'), // فارسی
    Locale('en', 'US'), // انگلیسی
  ];
}
