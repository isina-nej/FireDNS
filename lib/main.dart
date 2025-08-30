import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/services/dns_api_service.dart';
import 'blocs/dns/dns_bloc.dart';
import 'services/logger_service.dart';

import 'api/models/update_info.dart';
import 'api/services/api_client.dart';
import 'l10n/app_localizations.dart';
import 'routes/app_routes.dart';
import 'screens/force_update_page.dart';
import 'screens/loading_screen.dart';
import 'screens/splash_screen.dart';
import 'services/crash_reporting_service.dart';
import 'services/dns_test_settings_service.dart';
import 'services/fcm_token_manager.dart';
import 'services/firebase_messaging_service.dart';
import 'services/flutter_error_handler.dart';
import 'services/local_notification_service.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';
import 'services/notification_service_provider.dart';
import 'styles/language_manager.dart';
import 'styles/theme_manager.dart';
import 'utils/update_checker.dart';

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

  // راه‌اندازی سیستم گزارش خطاها
  FlutterErrorHandler.initialize();
  final crashReportingService = CrashReportingService();
  await crashReportingService.initialize();
  debugPrint('[BOOT] Crash reporting initialized');

  // Critical services first (parallel initialization for non-dependent services)
  await Future.wait([
    Firebase.initializeApp(),
    LocalNotificationService.initialize(),
  ]);

  debugPrint('[BOOT] Firebase and notifications initialized');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Load managers in parallel
  final managerFutures = await Future.wait([
    _initializeLanguageManager(),
    _initializeThemeManager(),
    _initializeDnsSettings(),
    _loadExistingJwtIfAvailable(),
  ]);

  final languageManager = managerFutures[0] as LanguageManager;
  final themeManager = managerFutures[1] as ThemeManager;
  final dnsTestSettingsService = managerFutures[2] as DnsTestSettingsService;

  // FCM services (can be loaded in background after app starts)
  _initializeFCMServicesInBackground();

  // ارسال لاگ‌های pending از قبل
  _sendPendingCrashesInBackground(crashReportingService);

  // گزارش موفقیت‌آمیز بودن startup
  _reportStartupSuccessInBackground(crashReportingService);

  return _BootResult(
    themeManager: themeManager,
    languageManager: languageManager,
    dnsTestSettingsService: dnsTestSettingsService,
  );
}

Future<LanguageManager> _initializeLanguageManager() async {
  final languageManager = LanguageManager();
  await languageManager.loadLanguage();
  debugPrint('[BOOT] Language loaded: ${languageManager.locale}');
  return languageManager;
}

Future<ThemeManager> _initializeThemeManager() async {
  final themeManager = ThemeManager();
  await themeManager.loadThemeMode();
  debugPrint('[BOOT] Theme mode: ${themeManager.themeMode}');
  return themeManager;
}

Future<DnsTestSettingsService> _initializeDnsSettings() async {
  final dnsTestSettingsService = DnsTestSettingsService();
  await dnsTestSettingsService.loadSettings();
  debugPrint('[BOOT] DNS test settings loaded');
  return dnsTestSettingsService;
}

Future<void> _initializeFCMServicesInBackground() async {
  try {
    final fcmService = FirebaseMessagingService();
    await fcmService.initialize();
    debugPrint('[BOOT] FCM service initialized');

    final fcmTokenManager = FcmTokenManager();
    await fcmTokenManager.checkTokenOnStartup();
    fcmTokenManager.setupTokenRefreshListener();
    debugPrint('[BOOT] FCM token manager ready');
  } catch (e) {
    debugPrint('[BOOT] FCM initialization failed: $e');

    // گزارش خطای FCM
    try {
      final crashService = CrashReportingService();
      await crashService.reportError(
        message: 'FCM initialization failed: $e',
        logType: 'fcm_error',
        metadata: {'component': 'FCM'},
      );
    } catch (reportError) {
      debugPrint('[BOOT] Failed to report FCM error: $reportError');
    }
  }
}

/// ارسال کرش‌های pending در پس‌زمینه
void _sendPendingCrashesInBackground(CrashReportingService crashService) {
  Future(() async {
    try {
      await crashService.sendPendingCrashes();
    } catch (e) {
      debugPrint('[BOOT] Failed to send pending crashes: $e');
    }
  });
}

/// گزارش startup موفق در پس‌زمینه
void _reportStartupSuccessInBackground(CrashReportingService crashService) {
  Future(() async {
    try {
      await crashService.reportInfo(
        message: 'App started successfully',
        logType: 'startup',
        metadata: {
          'startup_time': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        },
      );
    } catch (e) {
      debugPrint('[BOOT] Failed to report startup success: $e');
    }
  });
}

Future<void> main() async {
  // مدیریت خطاهای zone
  runZonedGuarded(() async {
    try {
      // نمایش splash screen سریع
      WidgetsFlutterBinding.ensureInitialized();

      runApp(const MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ));

      // انجام bootstrap در پس‌زمینه
      final boot = await _bootstrap();

      // تغییر به برنامه اصلی
      runApp(FireDNSApp(
        themeManager: boot.themeManager,
        languageManager: boot.languageManager,
        dnsTestSettingsService: boot.dnsTestSettingsService,
      ));
    } catch (error, stackTrace) {
      // گزارش خطای startup
      debugPrint('[FATAL] Bootstrap error: $error');
      debugPrint(stackTrace.toString());

      // سعی در ارسال خطا به سرور
      try {
        final crashService = CrashReportingService();
        await crashService.initialize();
        await crashService.reportCrash(
          error: error,
          stackTrace: stackTrace,
          additionalMetadata: {
            'error_location': 'main_bootstrap',
            'critical': true,
          },
        );
      } catch (reportingError) {
        debugPrint('[FATAL] Failed to report bootstrap error: $reportingError');
      }

      // نمایش صفحه خطا به کاربر
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.translate('appLoadingError', 'fa'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(AppLocalizations.translate('pleaseRestartApp', 'fa')),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // بازنشانی برنامه
                    main();
                  },
                  child: Text(AppLocalizations.translate('retry', 'fa')),
                ),
              ],
            ),
          ),
        ),
      ));
    }
  }, (error, stackTrace) {
    // مدیریت خطاهای uncaught در zone
    debugPrint('[FATAL] Uncaught zone error: $error');
    debugPrint(stackTrace.toString());

    // سعی در ارسال خطا به سرور
    try {
      final crashService = CrashReportingService();
      crashService.reportCrash(
        error: error,
        stackTrace: stackTrace,
        additionalMetadata: {
          'error_location': 'uncaught_zone_error',
          'critical': true,
        },
      );
    } catch (reportingError) {
      debugPrint('[FATAL] Failed to report zone error: $reportingError');
    }
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
  bool _showLoadingScreen = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // نمایش LoadingScreen برای 2.5 ثانیه
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _showLoadingScreen = false;
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
          lazy: true,
        ),
        ChangeNotifierProvider<DnsTestSettingsService>.value(
            value: widget.dnsTestSettingsService),
        BlocProvider<DnsBloc>(
          create: (context) => DnsBloc(
            dnsApiService: DnsApiService(),
            logger: LoggerService(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          NotificationServiceProvider.init(context);
          return Consumer2<ThemeManager, LanguageManager>(
            builder: (context, themeManager, languageManager, _) {
              final light =
                  _buildTheme(themeManager.lightTheme, languageManager);
              final dark = _buildTheme(themeManager.darkTheme, languageManager);

              return GetMaterialApp(
                title: 'Fire DNS',
                theme: light,
                darkTheme: dark,
                themeMode: themeManager.themeMode,
                locale: languageManager.locale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LanguageManager.supportedLocales,
                home: _showLoadingScreen
                    ? const LoadingScreen()
                    : _UpdateGate(
                        languageManager: languageManager,
                        child: Builder(
                          builder: (context) => Navigator(
                            initialRoute: AppRoutes.home,
                            onGenerateRoute: (settings) {
                              final route = AppRoutes.onGenerateRoute(settings);
                              if (route != null) return route;

                              final routeBuilder =
                                  AppRoutes.routes[settings.name];
                              if (routeBuilder != null) {
                                return MaterialPageRoute(
                                  builder: routeBuilder,
                                  settings: settings,
                                );
                              }
                              return null;
                            },
                          ),
                        ),
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
          return const LoadingScreen();
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
