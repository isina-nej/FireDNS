import 'package:flutter/material.dart';
import '../path/path.dart';

/// کلاس مدیریت تمام استایل‌های متن و Typography
class AppTextStyles {
  // فونت پیش‌فرض
  static const String _fontFamily = 'System';

  // سایزهای فونت
  static const double _fontSizeXS = 10.0;
  static const double _fontSizeS = 12.0;
  static const double _fontSizeM = 14.0;
  static const double _fontSizeL = 16.0;
  static const double _fontSizeXL = 18.0;
  static const double _fontSizeXXL = 20.0;
  static const double _fontSizeXXXL = 24.0;
  static const double _fontSizeHuge = 28.0;
  static const double _fontSizeGiant = 32.0;

  // وزن‌های فونت
  static const FontWeight _fontWeightLight = FontWeight.w300;
  static const FontWeight _fontWeightRegular = FontWeight.w400;
  static const FontWeight _fontWeightMedium = FontWeight.w500;
  static const FontWeight _fontWeightSemiBold = FontWeight.w600;
  static const FontWeight _fontWeightBold = FontWeight.w700;

  // استایل‌های Title و Header
  static const TextStyle titleLarge = TextStyle(
    fontSize: _fontSizeGiant,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: _fontSizeXXXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: _fontSizeXXL,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  // استایل‌های Header
  static const TextStyle headlineLarge = TextStyle(
    fontSize: _fontSizeXXXL,
    fontWeight: _fontWeightBold,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: _fontSizeXXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: _fontSizeXL,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  // استایل‌های Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightRegular,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightRegular,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightRegular,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
  );

  // استایل‌های Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
  );

  // استایل‌های دکمه
  static const TextStyle buttonLarge = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textWhite,
    fontFamily: _fontFamily,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWhite,
    fontFamily: _fontFamily,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWhite,
    fontFamily: _fontFamily,
  );

  // استایل‌های AppBar
  static const TextStyle appBarTitle = TextStyle(
    fontSize: _fontSizeXXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  // استایل‌های کپشن و توضیحات
  static const TextStyle caption = TextStyle(
    fontSize: _fontSizeXS,
    fontWeight: _fontWeightRegular,
    color: AppColors.textLight,
    fontFamily: _fontFamily,
  );

  static const TextStyle overline = TextStyle(
    fontSize: _fontSizeXS,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
    letterSpacing: 0.5,
  );

  // استایل‌های خطا و موفقیت
  static const TextStyle error = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textError,
    fontFamily: _fontFamily,
  );

  static const TextStyle success = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSuccess,
    fontFamily: _fontFamily,
  );

  static const TextStyle warning = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWarning,
    fontFamily: _fontFamily,
  );

  // استایل‌های مخصوص DNS و شبکه
  static const TextStyle dnsValue = TextStyle(
    fontSize: _fontSizeL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle pingValue = TextStyle(
    fontSize: _fontSizeXL,
    fontWeight: _fontWeightBold,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
  );

  // استایل‌های متن سفید (برای پس‌زمینه‌های تیره)
  static const TextStyle whiteTitle = TextStyle(
    fontSize: _fontSizeXL,
    fontWeight: _fontWeightSemiBold,
    color: AppColors.textWhite,
    fontFamily: _fontFamily,
  );

  static const TextStyle whiteBody = TextStyle(
    fontSize: _fontSizeM,
    fontWeight: _fontWeightMedium,
    color: AppColors.textWhite,
    fontFamily: _fontFamily,
  );

  static const TextStyle whiteCaption = TextStyle(
    fontSize: _fontSizeS,
    fontWeight: _fontWeightRegular,
    color: AppColors.textWhite,
    fontFamily: _fontFamily,
  );
}
