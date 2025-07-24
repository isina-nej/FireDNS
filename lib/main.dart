import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../path/path.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ایجاد ThemeManager و بارگذاری تنظیمات
  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();

  // ایجاد LanguageManager و بارگذاری تنظیمات
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();

  runApp(
    FireDNSApp(themeManager: themeManager, languageManager: languageManager),
  );
}

/// اپلیکیشن اصلی Fire DNS
class FireDNSApp extends StatelessWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const FireDNSApp({
    super.key,
    required this.themeManager,
    required this.languageManager,
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

            home: const FireDNSHomePage(title: 'Fire DNS'),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
