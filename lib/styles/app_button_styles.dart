import 'package:flutter/material.dart';
import '../path/path.dart';


/// کلاس مدیریت تمام استایل‌های دکمه‌ها
class AppButtonStyles {
  // دکمه اصلی (Primary)
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.fireRed,
    elevation: AppSizes.elevationMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXL,
      vertical: AppSizes.paddingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  // دکمه ثانویه (Secondary)
  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.brightBlue,
    elevation: AppSizes.elevationLow,
    side: const BorderSide(
      color: AppColors.gradientOrange,
      width: AppSizes.borderThin,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXL,
      vertical: AppSizes.paddingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  // دکمه سبز (Success)
  static ButtonStyle successButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.gradientOrange,
    elevation: AppSizes.elevationMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXL,
      vertical: AppSizes.paddingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  // دکمه خطرناک (Danger)
  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.fireRed,
    elevation: AppSizes.elevationMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXL,
      vertical: AppSizes.paddingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  // دکمه گرد (Rounded)
  static ButtonStyle roundedButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.brightBlue,
    elevation: AppSizes.elevationNone,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXXL,
      vertical: AppSizes.paddingL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusRound),
    ),
    textStyle: AppTextStyles.buttonLarge,
  );

  // دکمه متنی (Text Button)
  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.brightBlue,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingL,
      vertical: AppSizes.paddingS,
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  // دکمه آیکونی (Icon Button)
  static ButtonStyle iconButton = IconButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.all(AppSizes.paddingS),
    iconSize: AppSizes.iconL,
  );

  // دکمه شناور (Floating Action Button)
  static ButtonStyle floatingActionButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.fireRed,
    elevation: AppSizes.elevationHigh,
    shape: const CircleBorder(),
    padding: const EdgeInsets.all(AppSizes.paddingL),
  );

  // دکمه‌های مخصوص DNS
  static ButtonStyle connectButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.gradientOrange,
    elevation: AppSizes.elevationMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXXXL,
      vertical: AppSizes.paddingL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
    ),
    textStyle: AppTextStyles.buttonLarge,
  );

  static ButtonStyle disconnectButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.fireRed,
    elevation: AppSizes.elevationMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXXXL,
      vertical: AppSizes.paddingL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
    ),
    textStyle: AppTextStyles.buttonLarge,
  );

  // دکمه تغییر سرور
  static ButtonStyle changeServerButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.brightBlue,
    elevation: AppSizes.elevationNone,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXL,
      vertical: AppSizes.paddingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusXS),
    ),
    textStyle: AppTextStyles.labelMedium,
  );

  // دکمه کوچک
  static ButtonStyle smallButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.fireRed,
    elevation: AppSizes.elevationLow,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingL,
      vertical: AppSizes.paddingS,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
    ),
    textStyle: AppTextStyles.buttonSmall,
    minimumSize: const Size(AppSizes.minButtonWidth, AppSizes.minButtonHeight),
  );

  // دکمه بزرگ
  static ButtonStyle largeButton = ElevatedButton.styleFrom(
    foregroundColor: AppColors.pureWhite,
    backgroundColor: AppColors.fireRed,
    elevation: AppSizes.elevationMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingXXXL,
      vertical: AppSizes.paddingXL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
    ),
    textStyle: AppTextStyles.buttonLarge,
    minimumSize: const Size(AppSizes.buttonWidthL, AppSizes.buttonHeightL),
  );
}
