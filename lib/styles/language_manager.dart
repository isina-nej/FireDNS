import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// کلاس مدیریت زبان اپلیکیشن
class LanguageManager extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  static const String _countryKey = 'country_code';

  late Locale _locale;

  Locale get locale => _locale;

  bool get isFarsi => _locale.languageCode == 'fa';
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isRussian => _locale.languageCode == 'ru';
  bool get isChinese => _locale.languageCode == 'zh';
  bool get isSpanish => _locale.languageCode == 'es';
  bool get isFrench => _locale.languageCode == 'fr';
  bool get isGerman => _locale.languageCode == 'de';
  bool get isPortuguese => _locale.languageCode == 'pt';
  bool get isJapanese => _locale.languageCode == 'ja';
  bool get isKorean => _locale.languageCode == 'ko';
  bool get isHindi => _locale.languageCode == 'hi';
  bool get isItalian => _locale.languageCode == 'it';

  /// جهت متن بر اساس زبان
  TextDirection get textDirection =>
      _locale.languageCode == 'fa' || _locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr;

  /// فونت فعلی براساس زبان
  String get fontFamily => isEnglish ? 'Poppins' : 'IranSansX';

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
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'pt':
        return 'Português';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'hi':
        return 'हिन्दी';
      case 'it':
        return 'Italiano';
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
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'pt':
        return '🇵🇹';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'hi':
        return '🇮🇳';
      case 'it':
        return '🇮🇹';
      default:
        return '🇺🇸';
    }
  }

  /// چک کردن پشتیبانی از زبان
  bool isLanguageSupported(String languageCode) {
    return supportedLocales
        .any((locale) => locale.languageCode == languageCode);
  }

  /// تنظیم زبان بر اساس زبان دستگاه
  Locale getDeviceLanguage(Locale deviceLocale) {
    // اگر زبان دستگاه پشتیبانی می‌شود، از آن استفاده کن
    if (isLanguageSupported(deviceLocale.languageCode)) {
      // پیدا کردن تنظیمات کشور مناسب از لیست زبان‌های پشتیبانی شده
      final supportedLocale = supportedLocales.firstWhere(
        (locale) => locale.languageCode == deviceLocale.languageCode,
      );
      return supportedLocale;
    }
    // در غیر این صورت از انگلیسی استفاده کن
    return const Locale('en', 'US');
  }

  /// بارگذاری تنظیمات زبان از SharedPreferences
  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceLocale = PlatformDispatcher.instance.locale;

      // اگر زبان قبلاً تنظیم نشده است
      if (!prefs.containsKey(_languageKey)) {
        _locale = getDeviceLanguage(deviceLocale);
        await saveLanguage();
      } else {
        // استفاده از تنظیمات ذخیره شده
        final languageCode = prefs.getString(_languageKey)!;
        final countryCode = prefs.getString(_countryKey);
        _locale = Locale(languageCode, countryCode ?? '');
      }

      notifyListeners();
    } catch (e) {
      // در صورت بروز خطا، از زبان دستگاه یا انگلیسی استفاده کن
      final deviceLocale = PlatformDispatcher.instance.locale;
      _locale = getDeviceLanguage(deviceLocale);
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
    if (_locale.languageCode != 'fa') {
      _locale = const Locale('fa', 'IR');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان انگلیسی
  Future<void> setEnglish() async {
    if (_locale.languageCode != 'en') {
      _locale = const Locale('en', 'US');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان عربی
  Future<void> setArabic() async {
    if (_locale.languageCode != 'ar') {
      _locale = const Locale('ar', 'SA');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان روسی
  Future<void> setRussian() async {
    if (_locale.languageCode != 'ru') {
      _locale = const Locale('ru', 'RU');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان چینی
  Future<void> setChinese() async {
    if (_locale.languageCode != 'zh') {
      _locale = const Locale('zh', 'CN');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان اسپانیایی
  Future<void> setSpanish() async {
    if (_locale.languageCode != 'es') {
      _locale = const Locale('es', 'ES');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان فرانسوی
  Future<void> setFrench() async {
    if (_locale.languageCode != 'fr') {
      _locale = const Locale('fr', 'FR');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان آلمانی
  Future<void> setGerman() async {
    if (_locale.languageCode != 'de') {
      _locale = const Locale('de', 'DE');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان پرتغالی
  Future<void> setPortuguese() async {
    if (_locale.languageCode != 'pt') {
      _locale = const Locale('pt', 'PT');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان ژاپنی
  Future<void> setJapanese() async {
    if (_locale.languageCode != 'ja') {
      _locale = const Locale('ja', 'JP');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان کره‌ای
  Future<void> setKorean() async {
    if (_locale.languageCode != 'ko') {
      _locale = const Locale('ko', 'KR');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان هندی
  Future<void> setHindi() async {
    if (_locale.languageCode != 'hi') {
      _locale = const Locale('hi', 'IN');
      notifyListeners();
      await saveLanguage();
    }
  }

  /// تغییر به زبان ایتالیایی
  Future<void> setItalian() async {
    if (_locale.languageCode != 'it') {
      _locale = const Locale('it', 'IT');
      notifyListeners();
      await saveLanguage();
    }
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
    Locale('es', 'ES'), // اسپانیایی
    Locale('fr', 'FR'), // فرانسوی
    Locale('de', 'DE'), // آلمانی
    Locale('pt', 'PT'), // پرتغالی
    Locale('ja', 'JP'), // ژاپنی
    Locale('ko', 'KR'), // کره‌ای
    Locale('hi', 'IN'), // هندی
    Locale('it', 'IT'), // ایتالیایی
  ];
}
