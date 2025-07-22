import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_sizes.dart';
import '';

/// کلاس مدیریت تمام استایل‌های کارت و Container
class AppCardStyles {
  // کارت اصلی
  static BoxDecoration primaryCard = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusL),
    border: Border.all(color: AppColors.brightBlue, width: AppSizes.borderThin),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: AppSizes.elevationMedium,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // کارت با border (مطابق UI specs)
  static BoxDecoration borderedCard = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusXS), // 2dp corners
    border: Border.all(
      color: AppColors.brightBlue,
      width: AppSizes.borderThick, // 4dp border
    ),
  );

  // کارت ساده بدون سایه
  static BoxDecoration simpleCard = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.brightBlue, width: AppSizes.borderThin),
  );

  // کارت با گرادیانت قرمز
  static BoxDecoration redGradientCard = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.fireRed, AppColors.gradientOrange],
    ),
    borderRadius: BorderRadius.circular(AppSizes.radiusL),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: AppSizes.elevationHigh,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // کارت با گرادیانت آبی
  static BoxDecoration greenGradientCard = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.brightBlue, AppColors.darkNavy],
    ),
    borderRadius: BorderRadius.circular(AppSizes.radiusL),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: AppSizes.elevationMedium,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // کارت وضعیت اتصال
  static BoxDecoration connectionCard = BoxDecoration(
    color: AppColors.backgroundGrey,
    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
    border: Border.all(color: AppColors.cardBorder, width: AppSizes.borderThin),
  );

  // Container برای DNS input
  static BoxDecoration dnsInputContainer = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.brightBlue, width: AppSizes.borderThin),
  );

  // Container برای ping box
  static BoxDecoration pingBoxContainer = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.brightBlue, width: AppSizes.borderThin),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: AppSizes.elevationLow,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Container آیکونی
  static BoxDecoration iconContainer = BoxDecoration(
    color: AppColors.fireRed,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
  );

  // Container شفاف
  static BoxDecoration transparentContainer = const BoxDecoration(
    color: Colors.transparent,
  );

  // Container با پس‌زمینه خاکستری
  static BoxDecoration greyContainer = BoxDecoration(
    color: AppColors.backgroundGrey,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
  );

  // Container سرور (در صفحه config)
  static BoxDecoration serverContainer = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.brightBlue, width: AppSizes.borderThin),
  );

  // Container انتخاب شده
  static BoxDecoration selectedContainer = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.fireRed, width: AppSizes.borderMedium),
    boxShadow: [
      BoxShadow(
        color: AppColors.fireRed.withOpacity(0.1),
        blurRadius: AppSizes.elevationMedium,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Container متحرک (نمونه برای انیمیشن)
  static BoxDecoration animatedContainer = BoxDecoration(
    color: AppColors.darkNavy,
    borderRadius: BorderRadius.circular(AppSizes.radiusL),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: AppSizes.elevationVeryHigh,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Divider style
  static BoxDecoration dividerStyle = BoxDecoration(
    color: AppColors.cardBorder,
    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
  );

  // Badge container
  static BoxDecoration badgeContainer = BoxDecoration(
    color: AppColors.fireRed,
    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
  );

  // Error container
  static BoxDecoration errorContainer = BoxDecoration(
    color: AppColors.fireRed.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.fireRed, width: AppSizes.borderThin),
  );

  // Success container
  static BoxDecoration successContainer = BoxDecoration(
    color: AppColors.gradientOrange.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(
      color: AppColors.gradientOrange,
      width: AppSizes.borderThin,
    ),
  );

  // Warning container
  static BoxDecoration warningContainer = BoxDecoration(
    color: AppColors.brightBlue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.brightBlue, width: AppSizes.borderThin),
  );
}
