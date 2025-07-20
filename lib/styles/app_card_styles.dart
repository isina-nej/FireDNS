import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

/// کلاس مدیریت تمام استایل‌های کارت و Container
class AppCardStyles {
  // کارت اصلی
  static BoxDecoration primaryCard = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSizes.radiusL),
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
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSizes.radiusXS), // 2dp corners
    border: Border.all(
      color: AppColors.cardBorder,
      width: AppSizes.borderThick, // 4dp border
    ),
  );

  // کارت ساده بدون سایه
  static BoxDecoration simpleCard = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.cardBorder, width: AppSizes.borderThin),
  );

  // کارت با گرادیانت قرمز
  static BoxDecoration redGradientCard = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: AppColors.redGradient,
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

  // کارت با گرادیانت سبز
  static BoxDecoration greenGradientCard = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: AppColors.greenGradient,
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
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.cardBorder, width: AppSizes.borderThin),
  );

  // Container برای ping box
  static BoxDecoration pingBoxContainer = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
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
    color: AppColors.textPrimary,
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
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.cardBorder, width: AppSizes.borderThin),
  );

  // Container انتخاب شده
  static BoxDecoration selectedContainer = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(
      color: AppColors.primaryRed,
      width: AppSizes.borderMedium,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.withOpacity(AppColors.primaryRed, 0.1),
        blurRadius: AppSizes.elevationMedium,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Container متحرک (نمونه برای انیمیشن)
  static BoxDecoration animatedContainer = BoxDecoration(
    color: AppColors.cardBackground,
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
    color: AppColors.primaryRed,
    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
  );

  // Error container
  static BoxDecoration errorContainer = BoxDecoration(
    color: AppColors.withOpacity(AppColors.textError, 0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.textError, width: AppSizes.borderThin),
  );

  // Success container
  static BoxDecoration successContainer = BoxDecoration(
    color: AppColors.withOpacity(AppColors.textSuccess, 0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(
      color: AppColors.textSuccess,
      width: AppSizes.borderThin,
    ),
  );

  // Warning container
  static BoxDecoration warningContainer = BoxDecoration(
    color: AppColors.withOpacity(AppColors.textWarning, 0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(
      color: AppColors.textWarning,
      width: AppSizes.borderThin,
    ),
  );
}
