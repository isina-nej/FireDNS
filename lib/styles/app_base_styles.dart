import 'package:flutter/material.dart';
import '../path/path.dart';

/// کلاس پایه برای استایل‌های متن در تم‌ها
class AppBaseStyles {
  // سایزهای فونت
  static const double _fontSizeXS = 10.0;
  static const double _fontSizeS = 12.0;
  static const double _fontSizeM = 14.0;
  static const double _fontSizeL = 16.0;
  static const double _fontSizeXL = 18.0;
  static const double _fontSizeXXL = 20.0;
  static const double _fontSizeXXXL = 24.0;
  static const double _fontSizeGiant = 32.0;

  // وزن‌های فونت
  static const FontWeight _fontWeightRegular = FontWeight.w400;
  static const FontWeight _fontWeightMedium = FontWeight.w500;
  static const FontWeight _fontWeightSemiBold = FontWeight.w600;
  static const FontWeight _fontWeightBold = FontWeight.w700;

  // استایل‌های پایه Title و Header
  static const TextStyle titleLargeBase = TextStyle(
    fontSize: _fontSizeGiant,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMediumBase = TextStyle(
    fontSize: _fontSizeXXXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmallBase = TextStyle(
    fontSize: _fontSizeXXL,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
  );

  // استایل‌های پایه Header
  static const TextStyle headlineLargeBase = TextStyle(
    fontSize: _fontSizeXXXL,
    fontWeight: _fontWeightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMediumBase = TextStyle(
    fontSize: _fontSizeXXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
  );

  // استایل پایه دکمه‌ها
  static const TextStyle buttonBase = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmallBase = TextStyle(
    fontSize: _fontSizeXL,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
  );

  // استایل‌های پایه Body Text
  static const TextStyle bodyLargeBase = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightRegular,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMediumBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightRegular,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmallBase = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightRegular,
    color: AppColors.textSecondary,
  );

  // استایل‌های پایه Label
  static const TextStyle labelLargeBase = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMediumBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmallBase = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSecondary,
  );

  // استایل‌های پایه دکمه
  static const TextStyle buttonLargeBase = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textWhite,
  );

  static const TextStyle buttonMediumBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWhite,
  );

  static const TextStyle buttonSmallBase = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWhite,
  );

  // استایل پایه AppBar
  static const TextStyle appBarTitleBase = TextStyle(
    fontSize: _fontSizeXXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
  );

  // استایل‌های پایه کپشن و توضیحات
  static const TextStyle captionBase = TextStyle(
    fontSize: _fontSizeXS,
    fontWeight: _fontWeightRegular,
    color: AppColors.textLight,
  );

  static const TextStyle overlineBase = TextStyle(
    fontSize: _fontSizeXS,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  // استایل‌های پایه خطا و موفقیت
  static const TextStyle errorBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textError,
  );

  static const TextStyle successBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSuccess,
  );

  static const TextStyle warningBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWarning,
  );

  // استایل‌های پایه مخصوص DNS و شبکه
  static const TextStyle dnsValueBase = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle pingValueBase = TextStyle(
    fontSize: _fontSizeXL,
    fontWeight: _fontWeightBold,
    color: AppColors.textPrimary,
  );

  // استایل‌های پایه وضعیت
  static const TextStyle statusTextBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSecondary,
  );

  // استایل‌های متن سفید (برای پس‌زمینه‌های تیره)
  static const TextStyle whiteTitleBase = TextStyle(
    fontSize: _fontSizeXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textWhite,
  );

  static const TextStyle whiteBodyBase = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWhite,
  );

  static const TextStyle whiteCaptionBase = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightRegular,
    color: AppColors.textWhite,
  );
}
