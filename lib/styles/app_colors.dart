import 'package:flutter/material.dart';

/// کلاس مدیریت تمام رنگ‌های اپلیکیشن
class AppColors {
  // رنگ‌های اصلی
  static const primaryBlue = Color(0xFF5A9CFF);
  static const primaryText = Color(0xFF222B45);

  // رنگ‌های پس‌زمینه
  static const selectedLight = Color(0xFFE3F2FD);
  // static const backgroundLight = Color(0xFFF7F8FA);

  // رنگ‌های وضعیت پینگ
  static const pingExcellent = Color(0xFF4CAF50);
  static const pingGood = Color(0xFF8BC34A);
  static const pingMedium = Color(0xFFFFC107);
  static const pingPoor = Color(0xFFFF9800);
  static const pingBad = Color(0xFFF44336);
  // رنگ پینگ غیرقابل دسترس (افزوده شده)
  static const pingUnreachable = Color(0xFF800000); // قرمز تیره / Maroon

  // رنگ‌های متن و آیکن خاکستری
  static const textGrey = Color(0xFF607D8B);
  static const iconGrey = Color(0xFFB0BEC5);
  static const textLightGrey = Color(0xFF90A4AE);

  // رنگ‌های دارک مود (موجود)
  // رنگ‌های اصلی (Primary Colors)
  static const Color fireRed = Color(0xFFE63946);
  static const Color gradientOrange = Color(
    0xFFFF9800,
  ); // بهینه‌شده برای خوانایی و انرژی
  static const Color brightBlue = Color(
    0xFF3D5AFE,
  ); // آبی روشن‌تر برای تاکید بهتر
  static const Color darkNavy = Color(0xFF1E1E1E); // تیره‌تر برای دارک مود بهتر

  // رنگ‌های خنثی (Neutral Colors)
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFE0E0E0); // بهبود خوانایی در دارک مود
  static const Color softGray = Color(
    0xFF9E9E9E,
  ); // کنتراست بهتر برای متون ثانویه

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
  // static const Color pingGood = gradientOrange;
  // static const Color pingMedium = brightBlue;
  // static const Color pingBad = fireRed;

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

  // رنگ‌های تم تاریک - بهینه‌شده برای خوانایی و کاهش خستگی چشم
  static const Color darkBackground = Color(
    0xFF121212,
  ); // پس‌زمینه تیره‌تر برای کاهش خستگی چشم
  static const Color darkSurface = Color(
    0xFF1E1E1E,
  ); // سطوح با کمی روشنایی برای عمق
  static const Color darkSurfaceVariant = Color(
    0xFF242424,
  ); // واریانت برای لایه‌بندی بصری
  static const Color darkCardBackground = Color(
    0xFF1E1E1E,
  ); // کارت‌ها با عمق مناسب
  static const Color darkTextPrimary = Color(
    0xFFE0E0E0,
  ); // متن اصلی با خوانایی بالا
  static const Color darkTextSecondary = Color(
    0xFF9E9E9E,
  ); // متن ثانویه با کنتراست مناسب
  static const Color darkTextLight = Color(0xFF757575); // متن کم‌اهمیت
  static const Color darkBorder = Color(0xFF3D5AFE); // حاشیه با تاکید مناسب
  static const Color darkShadow = Color(0x40000000); // سایه نرم‌تر

  // رنگ‌های دارک مود برای کامپوننت‌ها - طراحی شده برای تجربه کاربری بهتر
  static const Color darkDrawerBackground = Color(
    0xFF1A1A1A,
  ); // کشو کمی روشن‌تر از پس‌زمینه
  static const Color darkPersonalBackground = Color(0xFF242424); // تنوع در عمق
  static const Color darkConfigBackground = Color(
    0xFF1E1E1E,
  ); // همخوانی با سایر المان‌ها
  static const Color darkRedSettingsBackground = Color(
    0xFF2C2C2C,
  ); // تیره‌تر برای تنظیمات

  // رنگ‌های آیکون در دارک مود - بهینه‌شده برای وضوح
  static const Color darkIconPrimary = Color(
    0xFFE0E0E0,
  ); // آیکون‌های اصلی با وضوح بالا
  static const Color darkIconSecondary = Color(
    0xFF9E9E9E,
  ); // آیکون‌های ثانویه با کنتراست مناسب

  // رنگ‌های اکسنت برای دارک مود - برای نمایش وضعیت‌ها
  static const Color darkAccentSuccess = Color(
    0xFF81C784,
  ); // سبز ملایم برای موفقیت
  static const Color darkAccentWarning = Color(
    0xFFFFB74D,
  ); // نارنجی ملایم برای هشدار
  static const Color darkAccentError = Color(0xFFE57373); // قرمز ملایم برای خطا
}
