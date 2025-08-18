import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/local_notification_service.dart';

import '../path/path.dart';
import 'services/firebase_messaging_service.dart';
import 'services/notification_service.dart';
import 'services/dns_test_settings_service.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'api/services/session_api_service.dart';
import 'utils/update_checker.dart';
import 'screens/force_update_page.dart';
import 'api/services/fcm_api_service.dart';

// Background message handler برای FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  // پردازش پیام در پس‌زمینه
  if (message.notification != null) {
    print('Background Message Title: ${message.notification?.title}');
    print('Background Message Body: ${message.notification?.body}');

    // نمایش نوتیفیکیشن در پس‌زمینه
    await LocalNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification!.title ?? 'Fire DNS',
      body: message.notification!.body ?? '',
      payload: message.data.toString(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 شروع اجرای برنامه...');

  // راه‌اندازی مدیریت زبان
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();

  // راه‌اندازی مدیریت تم
  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();

  // راه‌اندازی Firebase
  await Firebase.initializeApp();

  // راه‌اندازی Local Notifications
  await LocalNotificationService.initialize();

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

        // ارسال FCM به سرور
        final fcmApi = FcmApiService();
        final deviceId = fcmToken;
        final fcmTokenKey = fcmToken;
        final platform = Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'other';
        final fcmResponse = await fcmApi.registerFcmToken(
          deviceId: deviceId,
          fcmToken: fcmTokenKey,
          platform: platform,
        );
        debugPrint('ثبت FCM سمت سرور: ${fcmResponse.toJson()}');
      } else {
        debugPrint('دریافت JWT ناموفق بود: ${response.errorMessage}');
        print('دریافت JWT ناموفق بود: ${response.errorMessage}');
      }
    } else {
      debugPrint('توکن FCM دریافت نشد');
      print('توکن FCM دریافت نشد');
    }
  }

  // final themeManager = ThemeManager();
  // await themeManager.loadThemeMode();

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

class FireDNSApp extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;
  final DnsTestSettingsService dnsTestSettingsService;

  const FireDNSApp({
    super.key,
    required this.themeManager,
    required this.languageManager,
    required this.dnsTestSettingsService,
  });

  @override
  State<FireDNSApp> createState() => _FireDNSAppState();
}

class _FireDNSAppState extends State<FireDNSApp> {
  bool? _needsUpdate;
  static const Duration updateCheckInterval = Duration(hours: 48); // هر ۴۸ ساعت

  @override
  void initState() {
    super.initState();
    _checkForUpdatesIfNeeded();
  }

  Future<void> _checkForUpdatesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckStr = prefs.getString('last_update_check');
    DateTime? lastCheck;
    if (lastCheckStr != null) {
      try {
        lastCheck = DateTime.parse(lastCheckStr);
      } catch (_) {}
    }
    final now = DateTime.now();
    if (lastCheck == null || now.difference(lastCheck) > updateCheckInterval) {
      await _checkForUpdates();
      await prefs.setString('last_update_check', now.toIso8601String());
    } else {
      setState(() {
        _needsUpdate = false;
      });
    }
  }

  UpdateInfo? _updateInfo;
  Future<void> _checkForUpdates() async {
    final languageCode = widget.languageManager.locale.languageCode;
    final (isLatest, updateInfo) =
        await UpdateChecker.checkForUpdates(languageCode: languageCode);
    if (mounted) {
      setState(() {
        _needsUpdate = !isLatest;
        _updateInfo = updateInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: widget.themeManager),
        ChangeNotifierProvider<LanguageManager>.value(
            value: widget.languageManager),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
          lazy: false, // Initialize immediately
        ),
        ChangeNotifierProvider<DnsTestSettingsService>.value(
          value: widget.dnsTestSettingsService,
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
            theme: themeManager.lightTheme.copyWith(
              textTheme: themeManager.lightTheme.textTheme
                  .apply(
                    fontFamily:
                        languageManager.isEnglish ? 'Poppins' : 'IranSansX',
                    bodyColor:
                        themeManager.lightTheme.textTheme.bodyLarge?.color,
                    displayColor:
                        themeManager.lightTheme.textTheme.displayLarge?.color,
                  )
                  .copyWith(
                    bodyLarge: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    bodyMedium: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    titleLarge: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    titleMedium: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    titleSmall: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    labelLarge: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                  ),
              primaryTextTheme: themeManager.lightTheme.primaryTextTheme.apply(
                fontFamily: languageManager.fontFamily,
              ),
              appBarTheme: themeManager.lightTheme.appBarTheme.copyWith(
                titleTextStyle: TextStyle(
                    fontFamily: languageManager.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            darkTheme: themeManager.darkTheme.copyWith(
              textTheme: themeManager.darkTheme.textTheme
                  .apply(
                    fontFamily:
                        languageManager.isEnglish ? 'Poppins' : 'IranSansX',
                    bodyColor:
                        themeManager.darkTheme.textTheme.bodyLarge?.color,
                    displayColor:
                        themeManager.darkTheme.textTheme.displayLarge?.color,
                  )
                  .copyWith(
                    bodyLarge: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    bodyMedium: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    titleLarge: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    titleMedium: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    titleSmall: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                    labelLarge: TextStyle(
                        fontFamily: languageManager.isEnglish
                            ? 'Poppins'
                            : 'IranSansX'),
                  ),
              primaryTextTheme: themeManager.darkTheme.primaryTextTheme.apply(
                fontFamily: languageManager.fontFamily,
              ),
              appBarTheme: themeManager.darkTheme.appBarTheme.copyWith(
                titleTextStyle: TextStyle(
                    fontFamily: languageManager.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            themeMode: themeManager.themeMode,

            // تنظیمات جهت متن
            builder: (context, child) {
              return Directionality(
                textDirection: languageManager.textDirection,
                child: child!,
              );
            },

            home: _needsUpdate == true && _updateInfo != null
                ? ForceUpdatePage(
                    updateUrl: _updateInfo!.updateUrl,
                    currentAppVersion: UpdateChecker.currentVersion,
                  )
                : _needsUpdate == null
                    ? const Center(child: CircularProgressIndicator())
                    : FireDNSHomePage(title: context.tr('appTitle')),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
