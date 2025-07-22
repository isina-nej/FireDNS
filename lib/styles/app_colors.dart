import 'package:flutter/material.dart';

/// کلاس مدیریت تمام رنگ‌های اپلیکیشن
class AppColors {
  // رنگ‌های اصلی (Primary Colors)
  static const Color fireRed = Color(0xFFE63946);
  static const Color gradientOrange = Color(0xFFF4A261);
  static const Color brightBlue = Color(0xFF457B9D);
  static const Color darkNavy = Color(0xFF1D3557);

  // رنگ‌های خنثی (Neutral Colors)
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF1FAEE);
  static const Color softGray = Color(0xFFA8A8A8);

  // رنگ‌های پس‌زمینه
  static const Color backgroundLight = lightGray;
  static const Color backgroundWhite = pureWhite;
  static const Color backgroundGrey = softGray;
  static const Color backgroundCard = darkNavy;

  // رنگ‌های متن
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textWhite = Colors.white;
  static const Color textSuccess = Color(0xFF4CAF50);
  static const Color textError = Color(0xFFFF5252);
  static const Color textWarning = Color(0xFFFF9800);

  // رنگ‌های کشو و صفحات
  static const Color drawerBackground = darkNavy;
  static const Color redSettingsBackground = fireRed;
  static const Color personalBackground = darkNavy;
  static const Color configBackground = darkNavy;

  // رنگ‌های سوییچ و دکمه‌ها
  static const Color switchActiveThumb = pureWhite;
  static const Color switchActiveTrack = fireRed;
  static const Color switchInactiveThumb = softGray;
  static const Color switchInactiveTrack = darkNavy;

  // رنگ‌های وضعیت
  static const Color statusConnected = gradientOrange;
  static const Color statusDisconnected = fireRed;
  static const Color statusUnknown = softGray;
  static const Color statusPrivate = brightBlue;
  static const Color statusNotPrivate = fireRed;

  // رنگ‌های کارت و بخش‌ها
  static const Color cardBackground = darkNavy;
  static const Color cardBorder = brightBlue;
  static const Color cardShadow = Color(0x1A000000);
  static const Color shadow = Color(0x1A000000); // سایه عمومی

  // رنگ‌های گرادیانت
  static const List<Color> fireGradient = [fireRed, gradientOrange];
  static const List<Color> blueGradient = [brightBlue, darkNavy];

  // رنگ‌های DNS و شبکه
  static const Color dnsConnected = statusConnected;
  static const Color dnsDisconnected = statusDisconnected;
  static const Color vpnActive = brightBlue;
  static const Color vpnInactive = statusUnknown;
  static const Color pingGood = gradientOrange;
  static const Color pingMedium = brightBlue;
  static const Color pingBad = fireRed;

  // رنگ‌های آیکون
  static const Color iconPrimary = pureWhite;
  static const Color iconSecondary = lightGray;
  static const Color iconAccent = fireRed;
  static const Color iconSuccess = gradientOrange;
  static const Color iconError = fireRed;
  static const Color iconWarning = brightBlue;

  // شفافیت‌ها
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // رنگ‌های تم تاریک
  static const Color darkBackground = darkNavy;
  static const Color darkSurface = darkNavy;
  static const Color darkSurfaceVariant = brightBlue;
  static const Color darkCardBackground = darkNavy;
  static const Color darkTextPrimary = pureWhite;
  static const Color darkTextSecondary = lightGray;
  static const Color darkTextLight = softGray;
  static const Color darkBorder = brightBlue;
  static const Color darkShadow = Color(0x33000000);

  // رنگ‌های دارک مود برای کامپوننت‌ها
  static const Color darkDrawerBackground = darkNavy;
  static const Color darkPersonalBackground = darkNavy;
  static const Color darkConfigBackground = darkNavy;
  static const Color darkRedSettingsBackground = fireRed;

  // رنگ‌های آیکون در دارک مود
  static const Color darkIconPrimary = pureWhite;
  static const Color darkIconSecondary = lightGray;
}
