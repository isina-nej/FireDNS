import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/navigation_service.dart';
import 'routes/app_routes.dart';
import 'services/local_notification_service.dart';
import 'styles/theme_manager.dart';
import 'styles/language_manager.dart';
import 'services/notification_service.dart';
import 'services/notification_service_provider.dart';
import 'services/dns_test_settings_service.dart';
import 'services/firebase_messaging_service.dart';

import 'utils/update_checker.dart';
import 'screens/force_update_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/models/update_info.dart';
import 'l10n/localization_extension.dart';
import 'services/fcm_token_manager.dart';

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

Future<void> main() async {
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

  // راه‌اندازی مدیریت توکن FCM
  final fcmTokenManager = FcmTokenManager();
  await fcmTokenManager.checkTokenOnStartup();
  fcmTokenManager.setupTokenRefreshListener();

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
      child: Builder(builder: (context) {
        // Init NotificationServiceProvider for global access
        NotificationServiceProvider.init(context);
        return Consumer2<ThemeManager, LanguageManager>(
            builder: (context, themeManager, languageManager, child) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey,
            title: context.tr('appTitle'),
            initialRoute: AppRoutes.home,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,

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
              // اگر نیاز به بروزرسانی باشد، صفحه بروزرسانی را نمایش می‌دهیم
              if (_needsUpdate == true && _updateInfo != null) {
                return ForceUpdatePage(
                  updateUrl: _updateInfo!.updateUrl,
                  currentAppVersion: UpdateChecker.currentVersion,
                );
              }
              // اگر در حال بررسی وضعیت بروزرسانی هستیم، نمایش لودینگ
              if (_needsUpdate == null) {
                return const Center(child: CircularProgressIndicator());
              }
              // در غیر این صورت نمایش محتوای اصلی با جهت مناسب
              return Directionality(
                textDirection: languageManager.textDirection,
                child: child!,
              );
            },
            debugShowCheckedModeBanner: false,
          );
        });
      }),
    );
  }
}
