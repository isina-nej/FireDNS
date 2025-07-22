/// فایل اصلی export کردن تمام استایل‌ها
/// این فایل تمام کلاس‌های استایل را در یک مکان جمع می‌کند
library app_styles;

// Export کردن تمام فایل‌های استایل
export 'app_colors.dart';
export 'app_sizes.dart';
export 'app_text_styles.dart';
export 'app_button_styles.dart';
export 'app_card_styles.dart';
export 'app_themes.dart';
export 'theme_manager.dart';
export 'language_manager.dart';

/// کلاس اصلی که تمام استایل‌ها را در خود جمع می‌کند
class AppStyles {
  // Private constructor تا نتوان instance ساخت
  AppStyles._();

  // نام اپلیکیشن
  static const String appName = 'Fire DNS';

  // ورژن استایل
  static const String styleVersion = '1.0.0';

  // راهنمای استفاده سریع
  static const String usage = '''
  برای استفاده از استایل‌ها:
  
  1. import 'package:your_app/styles/app_styles.dart';
  
  2. استفاده از رنگ‌ها:
     - AppColors.primaryRed
     - AppColors.textPrimary
  
  3. استفاده از سایزها:
     - AppSizes.paddingL
     - AppSizes.radiusM
  
  4. استفاده از متن:
     - AppTextStyles.titleLarge
     - AppTextStyles.bodyMedium
  
  5. استفاده از دکمه‌ها:
     - AppButtonStyles.primaryButton
     - AppButtonStyles.secondaryButton
  
  6. استفاده از کارت‌ها:
     - AppCardStyles.primaryCard
     - AppCardStyles.borderedCard
  ''';
}
