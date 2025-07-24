import 'package:flutter/material.dart';
import '../path/path.dart';

/// کلاس مدیریت تم‌های اپلیکیشن
class AppThemes {
  // تم تاریک (Dark Theme)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // رنگ‌های اصلی
    colorScheme: const ColorScheme.dark(
      primary: AppColors.fireRed,
      secondary: AppColors.gradientOrange,
      surface: AppColors.darkNavy,
      background: AppColors.darkNavy,
      error: AppColors.fireRed,
      onPrimary: AppColors.pureWhite,
      onSecondary: AppColors.pureWhite,
      onSurface: AppColors.pureWhite,
      onBackground: AppColors.pureWhite,
      onError: AppColors.pureWhite,
    ),

    // رنگ اصلی اپ
    primaryColor: AppColors.fireRed,
    scaffoldBackgroundColor: AppColors.darkNavy,

    // تم AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkNavy,
      foregroundColor: AppColors.pureWhite,
      elevation: AppSizes.elevationNone,
      centerTitle: true,
      titleTextStyle: AppTextStyles.appBarTitle,
      iconTheme: IconThemeData(
        color: AppColors.pureWhite,
        size: AppSizes.iconL,
      ),
    ),

    // تم کارت‌ها
    cardTheme: CardThemeData(
      color: AppColors.darkNavy,
      elevation: AppSizes.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        side: const BorderSide(color: AppColors.brightBlue, width: 1),
      ),
      margin: const EdgeInsets.all(AppSizes.marginS),
    ),

    // تم دکمه‌های elevated
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.fireRed,
        foregroundColor: AppColors.pureWhite,
        elevation: AppSizes.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL,
          vertical: AppSizes.paddingM,
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),

    // تم دکمه‌های outlined
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gradientOrange,
        side: const BorderSide(
          color: AppColors.gradientOrange,
          width: AppSizes.borderThin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL,
          vertical: AppSizes.paddingM,
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),

    // تم دکمه‌های متنی
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brightBlue,
        textStyle: AppTextStyles.buttonMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingS,
        ),
      ),
    ),

    // تم فیلدهای ورودی
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkNavy,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(
          color: AppColors.brightBlue,
          width: AppSizes.borderThin,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(
          color: AppColors.brightBlue,
          width: AppSizes.borderThin,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(
          color: AppColors.gradientOrange,
          width: AppSizes.borderMedium,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(
          color: AppColors.fireRed,
          width: AppSizes.borderThin,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
        vertical: AppSizes.paddingM,
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.lightGray,
      ),
    ),

    // تم سوییچ‌ها
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.pureWhite;
        }
        return AppColors.softGray;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.fireRed;
        }
        return AppColors.darkNavy;
      }),
    ),

    // تم آیکون‌ها
    iconTheme: const IconThemeData(
      color: AppColors.pureWhite,
      size: AppSizes.iconL,
    ),

    // تم متن‌ها
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.pureWhite),
      displayMedium: TextStyle(color: AppColors.pureWhite),
      displaySmall: TextStyle(color: AppColors.pureWhite),
      headlineLarge: TextStyle(color: AppColors.pureWhite),
      headlineMedium: TextStyle(color: AppColors.pureWhite),
      headlineSmall: TextStyle(color: AppColors.pureWhite),
      titleLarge: TextStyle(color: AppColors.pureWhite),
      titleMedium: TextStyle(color: AppColors.pureWhite),
      titleSmall: TextStyle(color: AppColors.lightGray),
      bodyLarge: TextStyle(color: AppColors.pureWhite),
      bodyMedium: TextStyle(color: AppColors.lightGray),
      bodySmall: TextStyle(color: AppColors.softGray),
      labelLarge: TextStyle(color: AppColors.lightGray),
      labelMedium: TextStyle(color: AppColors.lightGray),
      labelSmall: TextStyle(color: AppColors.softGray),
    ),

    // تم Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.fireRed,
      foregroundColor: AppColors.pureWhite,
      elevation: AppSizes.elevationHigh,
      shape: CircleBorder(),
    ),

    // تم Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.darkNavy,
      elevation: AppSizes.elevationHigh,
      width: AppSizes.drawerWidth,
    ),

    // تم Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.brightBlue,
      thickness: AppSizes.borderThin,
      space: AppSizes.spaceM,
    ),
  );
}
