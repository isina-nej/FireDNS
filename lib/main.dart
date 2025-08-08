import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../path/path.dart';
import 'services/firebase_messaging_service.dart';
import 'dart:io' show Platform;
import 'screens/homepage_android.dart' as android;
import 'screens/homepage_windows.dart' as windows;
import 'utils/update_checker.dart';
import 'screens/force_update_page.dart';

// Background message handler برای FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // راه‌اندازی Firebase
  await Firebase.initializeApp();

  // تنظیم background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // راه‌اندازی FCM
  final fcmService = FirebaseMessagingService();
  await fcmService.initialize();

  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();

  runApp(
    FireDNSApp(
      themeManager: themeManager,
      languageManager: languageManager,
      // forceUpdate: !isLatest,
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
        // TODO: NotificationService provider will be added later
        // Provider<NotificationService>(
        //   create: (_) => NotificationService(),
        //   dispose: (_, service) => service.dispose(),
        // ),
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
