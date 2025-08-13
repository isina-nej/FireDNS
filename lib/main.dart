import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../path/path.dart';
import 'services/firebase_messaging_service.dart';
import 'services/notification_service.dart';
import 'services/dns_test_settings_service.dart';
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
  
  // Load DNS test settings
  final dnsTestSettingsService = DnsTestSettingsService();
  await dnsTestSettingsService.loadSettings();

  runApp(
    FireDNSApp(
      themeManager: themeManager,
      languageManager: languageManager,
      dnsTestSettingsService: dnsTestSettingsService,
      // forceUpdate: !isLatest,
    ),
  );
}

/// اپلیکیشن اصلی Fire DNS

class FireDNSApp extends StatelessWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;
  final DnsTestSettingsService dnsTestSettingsService;
  final bool forceUpdate;

  const FireDNSApp({
    super.key,
    required this.themeManager,
    required this.languageManager,
    required this.dnsTestSettingsService,
    this.forceUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
        ChangeNotifierProvider<LanguageManager>.value(value: languageManager),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
          lazy: false, // Initialize immediately
        ),
        ChangeNotifierProvider<DnsTestSettingsService>.value(
          value: dnsTestSettingsService,
        ),
        ChangeNotifierProvider<DnsTestSettingsService>(
          create: (_) => DnsTestSettingsService(),
          lazy: false, // Initialize immediately
        ),
      ],
      child: Consumer2<ThemeManager, LanguageManager>(
        builder: (context, themeManager, languageManager, child) {
          return MaterialApp(
            title: context.tr('appTitle'),

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
                ? const ForceUpdatePage(
                    updateUrl: UpdateChecker.updateUrl,
                    currentAppVersion: UpdateChecker.currentVersion,
                  )
                : (Platform.isWindows
                    ?android.FireDNSHomePage(title: context.tr('appTitle'))
                     //windows.FireDNSHomePage(title: context.tr('appTitle'))
                    : android.FireDNSHomePage(title: context.tr('appTitle'))),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
