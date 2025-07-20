import 'package:flutter/material.dart';

/// کلاس مدیریت تمام رنگ‌های اپلیکیشن
class AppColors {
  // رنگ‌های اصلی
  static const Color primaryRed = Color(0xFFFF6B6B);
  static const Color primaryRedDark = Color(0xFFFF5252);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryBlue = Color(0xFF2196F3);

  // رنگ‌های پس‌زمینه
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundGrey = Color(0xFFE5E5E5);
  static const Color backgroundCard = Colors.white;

  // رنگ‌های متن
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textWhite = Colors.white;
  static const Color textSuccess = Color(0xFF4CAF50);
  static const Color textError = Color(0xFFFF5252);
  static const Color textWarning = Color(0xFFFF9800);

  // رنگ‌های کشو و صفحات
  static const Color drawerBackground = Color(0xFFF5F5F5);
  static const Color redSettingsBackground = primaryRed;
  static const Color personalBackground = backgroundLight;
  static const Color configBackground = backgroundLight;

  // رنگ‌های سوییچ و دکمه‌ها
  static const Color switchActiveThumb = Colors.white;
  static const Color switchActiveTrack = primaryGreen;
  static const Color switchInactiveThumb = Colors.grey;
  static const Color switchInactiveTrack = Color(0xFFE0E0E0);

  // رنگ‌های وضعیت
  static const Color statusConnected = primaryGreen;
  static const Color statusDisconnected = Color(0xFFFF5252);
  static const Color statusUnknown = Color(0xFF9E9E9E);
  static const Color statusPrivate = textSuccess;
  static const Color statusNotPrivate = textError;

  // رنگ‌های کارت و بخش‌ها
  static const Color cardBackground = backgroundWhite;
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x1A000000);
  static const Color shadow = Color(0x1A000000); // سایه عمومی

  // رنگ‌های گرادیانت
  static const List<Color> redGradient = [primaryRed, primaryRedDark];
  static const List<Color> greenGradient = [
    Color(0xFF66BB6A),
    Color(0xFF4CAF50),
  ];
  static const List<Color> blueGradient = [
    Color(0xFF42A5F5),
    Color(0xFF2196F3),
  ];

  // رنگ‌های DNS و شبکه
  static const Color dnsConnected = statusConnected;
  static const Color dnsDisconnected = statusDisconnected;
  static const Color vpnActive = primaryBlue;
  static const Color vpnInactive = statusUnknown;
  static const Color pingGood = primaryGreen;
  static const Color pingMedium = textWarning;
  static const Color pingBad = textError;

  // رنگ‌های آیکون
  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textSecondary;
  static const Color iconAccent = primaryRed;
  static const Color iconSuccess = statusConnected;
  static const Color iconError = statusDisconnected;
  static const Color iconWarning = textWarning;

  // شفافیت‌ها
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // رنگ‌های تم تاریک
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkCardBackground = Color(0xFF242424);
  static const Color darkTextPrimary = Color(0xFFE1E1E1);
  static const Color darkTextSecondary = Color(0xFFBBBBBB);
  static const Color darkTextLight = Color(0xFF888888);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkShadow = Color(0x33000000);

  // رنگ‌های دارک مود برای کامپوننت‌ها
  static const Color darkDrawerBackground = darkSurface;
  static const Color darkPersonalBackground = darkBackground;
  static const Color darkConfigBackground = darkBackground;
  static const Color darkRedSettingsBackground = Color(0xFF8B0000);

  // رنگ‌های آیکون در دارک مود
  static const Color darkIconPrimary = darkTextPrimary;
  static const Color darkIconSecondary = darkTextSecondary;
}
