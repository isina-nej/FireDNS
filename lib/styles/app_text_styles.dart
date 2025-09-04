import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// کلاس مدیریت تمام استایل‌های متن و Typography
class AppTextStyles {
  // تابع کمکی برای انتخاب فونت مناسب
  static String _getFont(bool isEnglish) {
    return isEnglish ? 'Poppins' : 'IranSansX';
  }

  // استایل‌های Title و Header
  static TextStyle titleLarge(BuildContext context) =>
      AppBaseStyles.titleLargeBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle titleMedium(BuildContext context) =>
      AppBaseStyles.titleMediumBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle titleSmall(BuildContext context) =>
      AppBaseStyles.titleSmallBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های Header
  static TextStyle headlineLarge(BuildContext context) =>
      AppBaseStyles.headlineLargeBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle headlineMedium(BuildContext context) =>
      AppBaseStyles.headlineMediumBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle headlineSmall(BuildContext context) =>
      AppBaseStyles.headlineSmallBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های Body Text
  static TextStyle bodyLarge(BuildContext context) =>
      AppBaseStyles.bodyLargeBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle bodyMedium(BuildContext context) =>
      AppBaseStyles.bodyMediumBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle bodySmall(BuildContext context) =>
      AppBaseStyles.bodySmallBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های Label
  static TextStyle labelLarge(BuildContext context) =>
      AppBaseStyles.labelLargeBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle labelMedium(BuildContext context) =>
      AppBaseStyles.labelMediumBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle labelSmall(BuildContext context) =>
      AppBaseStyles.labelSmallBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های دکمه
  static TextStyle buttonLarge(BuildContext context) =>
      AppBaseStyles.buttonLargeBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle buttonMedium(BuildContext context) =>
      AppBaseStyles.buttonMediumBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle buttonSmall(BuildContext context) =>
      AppBaseStyles.buttonSmallBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های AppBar
  static TextStyle appBarTitle(BuildContext context) =>
      AppBaseStyles.appBarTitleBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های کپشن و توضیحات
  static TextStyle caption(BuildContext context) =>
      AppBaseStyles.captionBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle overline(BuildContext context) =>
      AppBaseStyles.overlineBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های خطا و موفقیت
  static TextStyle error(BuildContext context) =>
      AppBaseStyles.errorBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle success(BuildContext context) =>
      AppBaseStyles.successBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle warning(BuildContext context) =>
      AppBaseStyles.warningBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های مخصوص DNS و شبکه
  static TextStyle dnsValue(BuildContext context) =>
      AppBaseStyles.dnsValueBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle pingValue(BuildContext context) =>
      AppBaseStyles.pingValueBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle statusText(BuildContext context) =>
      AppBaseStyles.statusTextBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  // استایل‌های متن سفید (برای پس‌زمینه‌های تیره)
  static TextStyle whiteTitle(BuildContext context) =>
      AppBaseStyles.whiteTitleBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle whiteBody(BuildContext context) =>
      AppBaseStyles.whiteBodyBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );

  static TextStyle whiteCaption(BuildContext context) =>
      AppBaseStyles.whiteCaptionBase.copyWith(
        fontFamily: _getFont(
            Provider.of<LanguageManager>(context, listen: false).isEnglish),
      );
}
