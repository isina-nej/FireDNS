import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestThemeController {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
  }

  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
  }

  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkTheme();
    } else if (_themeMode == ThemeMode.dark) {
      await setLightTheme();
    } else {
      await setDarkTheme();
    }
  }
}

void main() {
  group('ThemeController Tests', () {
    late TestThemeController themeController;

    setUp(() {
      themeController = TestThemeController();
    });

    test('Initial theme should be system', () {
      expect(themeController.themeMode, ThemeMode.system);
      expect(themeController.isSystemMode, true);
      expect(themeController.isLightMode, false);
      expect(themeController.isDarkMode, false);
    });

    test('Should switch to light theme', () async {
      await themeController.setLightTheme();
      expect(themeController.themeMode, ThemeMode.light);
      expect(themeController.isLightMode, true);
      expect(themeController.isDarkMode, false);
      expect(themeController.isSystemMode, false);
    });

    test('Should switch to dark theme', () async {
      await themeController.setDarkTheme();
      expect(themeController.themeMode, ThemeMode.dark);
      expect(themeController.isDarkMode, true);
      expect(themeController.isLightMode, false);
      expect(themeController.isSystemMode, false);
    });

    test('Should switch to system theme', () async {
      await themeController.setSystemTheme();
      expect(themeController.themeMode, ThemeMode.system);
      expect(themeController.isSystemMode, true);
      expect(themeController.isLightMode, false);
      expect(themeController.isDarkMode, false);
    });

    test('Should toggle theme correctly', () async {
      // Start with system mode
      expect(themeController.themeMode, ThemeMode.system);

      // Toggle should go to dark (from system)
      await themeController.toggleTheme();
      expect(themeController.themeMode, ThemeMode.dark);

      // Toggle again should go to light
      await themeController.toggleTheme();
      expect(themeController.themeMode, ThemeMode.light);

      // Toggle again should go to dark
      await themeController.toggleTheme();
      expect(themeController.themeMode, ThemeMode.dark);
    });
  });
}
