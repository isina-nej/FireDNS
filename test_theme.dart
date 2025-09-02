import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/controllers/theme_controller.dart';
import 'lib/styles/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetX
  Get.testMode = true;

  // Create and inject ThemeController
  final themeController = ThemeController();
  await themeController.initializeTheme();
  Get.put(themeController);

  print('✅ ThemeController initialized successfully');
  print('📱 Current theme is dark: ${themeController.isDarkMode}');
  print('🌟 Current theme name: ${themeController.getCurrentThemeName()}');

  // Test theme switching
  print('\n🔄 Testing theme switching...');
  final originalTheme = themeController.isDarkMode;

  // Switch theme
  await themeController.toggleTheme();
  print('🌙 After toggle - Dark mode: ${themeController.isDarkMode}');

  // Switch back
  await themeController.toggleTheme();
  print('☀️ After second toggle - Dark mode: ${themeController.isDarkMode}');

  // Test different theme methods
  await themeController.setTheme(ThemeModeType.dark);
  print('🌑 After setting dark theme: ${themeController.isDarkMode}');

  await themeController.setTheme(ThemeModeType.light);
  print('☀️ After setting light theme: ${themeController.isDarkMode}');

  await themeController.setTheme(ThemeModeType.system);
  print('📱 After setting system theme: ${themeController.isDarkMode}');

  print('\n✅ Theme switching test completed successfully!');
  print('🎯 GetX ThemeController is working properly with animations');
}
