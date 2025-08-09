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
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isRussian => _locale.languageCode == 'ru';
  bool get isChinese => _locale.languageCode == 'zh';

  /// جهت متن بر اساس زبان
  TextDirection get textDirection =>
      _locale.languageCode == 'fa' || _locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr;

  /// نام زبان فعلی
  String get languageName {
    switch (_locale.languageCode) {
      case 'fa':
        return 'فارسی';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'ru':
        return 'Русский';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  /// آیکون زبان فعلی
  String get languageFlag {
    switch (_locale.languageCode) {
      case 'fa':
        return '🇮🇷';
      case 'en':
        return '🇺🇸';
      case 'ar':
        return '🇸🇦';
      case 'ru':
        return '🇷🇺';
      case 'zh':
        return '🇨🇳';
      default:
        return '🇺🇸';
    }
  }

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

  /// تغییر به زبان عربی
  Future<void> setArabic() async {
    _locale = const Locale('ar', 'SA');
    notifyListeners();
    await saveLanguage();
  }

  /// تغییر به زبان روسی
  Future<void> setRussian() async {
    _locale = const Locale('ru', 'RU');
    notifyListeners();
    await saveLanguage();
  }

  /// تغییر به زبان چینی
  Future<void> setChinese() async {
    _locale = const Locale('zh', 'CN');
    notifyListeners();
    await saveLanguage();
  }

  /// تغییر به زبان بعدی
  Future<void> toggleLanguage() async {
    switch (_locale.languageCode) {
      case 'fa':
        await setEnglish();
        break;
      case 'en':
        await setArabic();
        break;
      case 'ar':
        await setRussian();
        break;
      case 'ru':
        await setChinese();
        break;
      case 'zh':
        await setFarsi();
        break;
      default:
        await setFarsi();
    }
  }

  /// زبان‌های پشتیبانی شده
  static const List<Locale> supportedLocales = [
    Locale('fa', 'IR'), // فارسی
    Locale('en', 'US'), // انگلیسی
    Locale('ar', 'SA'), // عربی
    Locale('ru', 'RU'), // روسی
    Locale('zh', 'CN'), // چینی
  ];
}
