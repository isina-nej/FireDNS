import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../path/path.dart';
import 'dart:io' show Platform;
import 'screens/homepage_android.dart' as android;
import 'screens/homepage_windows.dart' as windows;
import 'utils/update_checker.dart';
import 'screens/force_update_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();

  // چک کردن آپدیت
  final isLatest = await UpdateChecker.isLatestVersion();

  runApp(
    FireDNSApp(
      themeManager: themeManager,
      languageManager: languageManager,
      forceUpdate: !isLatest,
    ),
  );
}

/// اپلیکیشن اصلی Fire DNS

class FireDNSApp extends StatelessWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;
  final bool forceUpdate;

  const FireDNSApp({
    super.key,
    required this.themeManager,
    required this.languageManager,
    this.forceUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
        ChangeNotifierProvider<LanguageManager>.value(value: languageManager),
      ],
      child: Consumer2<ThemeManager, LanguageManager>(
        builder: (context, themeManager, languageManager, child) {
          return MaterialApp(
            title: 'Fire DNS',

            // تنظیمات زبان و محلی‌سازی
            locale: languageManager.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageManager.supportedLocales,

            // تنظیمات تم
            theme: themeManager.lightTheme,
            darkTheme: themeManager.darkTheme,
            themeMode: themeManager.themeMode,

            // تنظیمات جهت متن
            builder: (context, child) {
              return Directionality(
                textDirection: languageManager.textDirection,
                child: child!,
              );
            },

            home: forceUpdate
                ? const ForceUpdatePage(updateUrl: UpdateChecker.updateUrl)
                : (Platform.isWindows
                      ? const windows.FireDNSHomePage(title: 'Fire DNS')
                      : const android.FireDNSHomePage(title: 'Fire DNS')),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
