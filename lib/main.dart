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
import 'package:shared_preferences/shared_preferences.dart';
import 'api/services/session_api_service.dart';
// import 'screens/homepage_windows.dart' as windows;
import 'utils/update_checker.dart';
import 'screens/force_update_page.dart';

// Background message handler برای FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // راه‌اندازی مدیریت زبان اول از همه
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();

  // راه‌اندازی Firebase
  await Firebase.initializeApp();

  // تنظیم background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // راه‌اندازی FCM
  final fcmService = FirebaseMessagingService();
  await fcmService.initialize();

  // ارسال FCM و دریافت JWT فقط یک بار پس از نصب
  final prefs = await SharedPreferences.getInstance();
  final isRegistered = prefs.getBool('fcm_registered') ?? false;
  if (!isRegistered) {
    // دریافت توکن FCM
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      // ارسال به سرور و دریافت JWT
      final sessionApi = SessionApiService();
      final response = await sessionApi.initSession(fcmToken);
      if (response.data != null) {
        final jwt = response.data!.jwt;
        // ذخیره امن JWT
        await prefs.setString('jwt', jwt);
        // ثبت ارسال FCM
        await prefs.setBool('fcm_registered', true);
        // پرینت برای دیباگ
        debugPrint('JWT دریافت شده: $jwt');
        print('JWT دریافت شده: $jwt');
      } else {
        debugPrint('دریافت JWT ناموفق بود: ${response.errorMessage}');
        print('دریافت JWT ناموفق بود: ${response.errorMessage}');
      }
    } else {
      debugPrint('توکن FCM دریافت نشد');
      print('توکن FCM دریافت نشد');
    }
  }

  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();

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
                    ? android.FireDNSHomePage(title: context.tr('appTitle'))
                    //windows.FireDNSHomePage(title: context.tr('appTitle'))
                    : android.FireDNSHomePage(title: context.tr('appTitle'))),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
