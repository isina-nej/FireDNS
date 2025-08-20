import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/navigation_service.dart';
import 'routes/app_routes.dart';
import 'services/local_notification_service.dart';
import 'styles/theme_manager.dart';
import 'styles/language_manager.dart';
import 'services/notification_service.dart';
import 'services/notification_service_provider.dart';
import 'services/dns_test_settings_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/fcm_token_manager.dart';
import 'utils/update_checker.dart';
import 'screens/force_update_page.dart';
import 'api/models/update_info.dart';
import 'l10n/localization_extension.dart';
import 'api/services/api_client.dart';

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

/// نتیجه بوت اولیه برنامه (Dependencies container ساده)
class _BootResult {
  final ThemeManager themeManager;
  final LanguageManager languageManager;
  final DnsTestSettingsService dnsTestSettingsService;
  const _BootResult({
    required this.themeManager,
    required this.languageManager,
    required this.dnsTestSettingsService,
  });
}

/// انجام مراحل اولیه راه‌اندازی (Bootstrapping)
Future<_BootResult> _bootstrap() async {
  debugPrint('[BOOT] Starting bootstrap sequence');
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase & notifications init
  await Firebase.initializeApp();
  debugPrint('[BOOT] Firebase initialized');
  await LocalNotificationService.initialize();
  debugPrint('[BOOT] Local notifications initialized');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Core managers
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();
  debugPrint('[BOOT] Language loaded: ${languageManager.locale}');

  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();
  debugPrint('[BOOT] Theme mode: ${themeManager.themeMode}');

  final dnsTestSettingsService = DnsTestSettingsService();
  await dnsTestSettingsService.loadSettings();
  debugPrint('[BOOT] DNS test settings loaded');

  // بارگذاری JWT موجود از SharedPreferences (در صورت وجود)
  await _loadExistingJwtIfAvailable();

  // FCM services
  final fcmService = FirebaseMessagingService();
  await fcmService.initialize();
  debugPrint('[BOOT] FCM service initialized');
  final fcmTokenManager = FcmTokenManager();
  await fcmTokenManager.checkTokenOnStartup();
  fcmTokenManager.setupTokenRefreshListener();
  debugPrint('[BOOT] FCM token manager ready');

  return _BootResult(
    themeManager: themeManager,
    languageManager: languageManager,
    dnsTestSettingsService: dnsTestSettingsService,
  );
}

Future<void> main() async {
  runZonedGuarded(() async {
    final boot = await _bootstrap();
    runApp(FireDNSApp(
      themeManager: boot.themeManager,
      languageManager: boot.languageManager,
      dnsTestSettingsService: boot.dnsTestSettingsService,
    ));
  }, (error, stack) {
    // TODO: ارسال لاگ به سرور خطا (Crashlytics / Sentry) در آینده
    debugPrint('[FATAL] Uncaught zone error: $error');
    debugPrint(stack.toString());
  });
}

/// بارگذاری JWT موجود از SharedPreferences و تنظیم آن در ApiClient
Future<void> _loadExistingJwtIfAvailable() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final existingJwt = prefs.getString('jwt');
    if (existingJwt != null && existingJwt.isNotEmpty) {
      ApiClient.setJwt(existingJwt);
      debugPrint('[BOOT] Existing JWT loaded and set in ApiClient');
    } else {
      debugPrint('[BOOT] No existing JWT found');
    }
  } catch (e, s) {
    debugPrint('[BOOT] Error loading existing JWT: $e');
    debugPrint(s.toString());
  }
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
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: widget.themeManager),
        ChangeNotifierProvider<LanguageManager>.value(
            value: widget.languageManager),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
          lazy: false,
        ),
        ChangeNotifierProvider<DnsTestSettingsService>.value(
            value: widget.dnsTestSettingsService),
      ],
      child: Builder(
        builder: (context) {
          NotificationServiceProvider.init(context); // global access setup
          return Consumer2<ThemeManager, LanguageManager>(
            builder: (context, themeManager, languageManager, _) {
              final light =
                  _buildTheme(themeManager.lightTheme, languageManager);
              final dark = _buildTheme(themeManager.darkTheme, languageManager);
              return MaterialApp(
                navigatorKey: NavigationService.navigatorKey,
                title: context.tr('appTitle'),
                initialRoute: AppRoutes.home,
                routes: AppRoutes.routes,
                onGenerateRoute: AppRoutes.onGenerateRoute,
                locale: languageManager.locale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LanguageManager.supportedLocales,
                theme: light,
                darkTheme: dark,
                themeMode: themeManager.themeMode,
                builder: (context, child) => _UpdateGate(
                  languageManager: languageManager,
                  child: child,
                ),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

/// ویجت مسئول مدیریت منطق بروزرسانی (جلوگیری از شلوغی در App)
class _UpdateGate extends StatefulWidget {
  final LanguageManager languageManager;
  final Widget? child;
  const _UpdateGate({required this.languageManager, required this.child});

  @override
  State<_UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<_UpdateGate> {
  static const Duration interval = Duration(hours: 48);
  Future<(_GateState, UpdateInfo?)>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(_GateState, UpdateInfo?)> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final lastRaw = prefs.getString('last_update_check');
      DateTime? last;
      if (lastRaw != null) {
        try {
          last = DateTime.parse(lastRaw);
        } catch (_) {}
      }
      if (last == null || now.difference(last) > interval) {
        final (isLatest, info) = await UpdateChecker.checkForUpdates(
            languageCode: widget.languageManager.locale.languageCode);
        await prefs.setString('last_update_check', now.toIso8601String());
        if (!isLatest && info != null) {
          return (_GateState.needsUpdate, info);
        }
      }
      return (_GateState.ok, null);
    } catch (e, s) {
      debugPrint('[UpdateGate] Failed to check updates: $e');
      debugPrint(s.toString());
      return (_GateState.ok, null); // Fail-open
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(_GateState, UpdateInfo?)>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (state, info) = snapshot.data!;
        if (state == _GateState.needsUpdate && info != null) {
          return ForceUpdatePage(
            updateUrl: info.updateUrl,
            currentAppVersion: UpdateChecker.currentVersion,
          );
        }
        // Directionality wrapper برای پشتیبانی از RTL
        return Directionality(
          textDirection: widget.languageManager.textDirection,
          child: widget.child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

enum _GateState { ok, needsUpdate }

ThemeData _buildTheme(ThemeData base, LanguageManager languageManager) {
  final font = languageManager.isEnglish ? 'Poppins' : 'IranSansX';
  final textTheme = base.textTheme.apply(
    fontFamily: font,
    bodyColor: base.textTheme.bodyLarge?.color,
    displayColor: base.textTheme.displayLarge?.color,
  );
  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: font),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: TextStyle(
        fontFamily: font,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
