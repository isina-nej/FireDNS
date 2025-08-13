import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../path/path.dart';
import 'dns_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/services/dns_usage_api_service.dart';
import '../api/models/dns_usage_request.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../widgets/notification_bell.dart';
import '../widgets/custom_drawer.dart';

// SnackBar enhancements
enum SnackBarType { success, error, warning, info }

class SnackBarStyle {
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  SnackBarStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

/// ویجت متن با پس‌زمینه نیمه‌شفاف
class SemiTransparentText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color backgroundColor;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const SemiTransparentText({
    Key? key,
    required this.text,
    required this.style,
    this.backgroundColor = Colors.black,
    this.opacity = 0.15,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: style,
      ),
    );
  }
}

// Responsive size utility for Android
double responsiveSize(
  double base,
  BuildContext context, {
  double min = 12,
  double max = 40,
  bool scaleByHeight = false,
}) {
  // On Android, just return base (no scaling), but keep API for consistency
  return base;
}

/// صفحه اصلی برنامه Fire DNS
class FireDNSHomePage extends StatefulWidget {
  final String title;

  const FireDNSHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<FireDNSHomePage> createState() => _FireDNSHomePageState();
}

class _FireDNSHomePageState extends State<FireDNSHomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late ThemeManager _themeManager;
  late final AnimationController _lottieController;

  String? _selectedDnsLabel;
  String? _selectedDnsIp;
  // Controllers
  late final TextEditingController _dns1Controller;
  late final TextEditingController _dns2Controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  bool _vpnActive = false;
  bool _vpnLoading = false;
  bool _autoPingEnabled = false;

  // SnackBar management
  DateTime? _lastSnackBarTime;
  String? _lastSnackBarMessage;

  // Stream subscriptions
  StreamSubscription<bool>? _vpnStatusSubscription;
  StreamSubscription<Map<String, int>>? _dataUsageSubscription;
  StreamSubscription<Map<String, DnsStatus>>? _pingResultSubscription;

  @override
  void initState() {
    super.initState();
    _themeManager = Provider.of<ThemeManager>(context, listen: false);
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
      upperBound: 1,
      lowerBound: 0,
    );
    _initializeControllers();
    _initializeObserver();
    _initializeServices();
    _themeManager.loadThemeMode();
    setState(() {
      _vpnLoading = false;
      _vpnActive = false;
    });
    _loadSelectedDnsLabel();
  }

  Future<void> _loadSelectedDnsLabel() async {
    // خواندن دی‌ان‌اس انتخابی از کش
    final prefs = await SharedPreferences.getInstance();
    final cachedDnsList = prefs.getString('cached_dns_list');
    final selectedId = prefs.getString('cached_selected_dns');
    if (cachedDnsList != null && selectedId != null) {
      try {
        final List<dynamic> jsonList = List.from(jsonDecode(cachedDnsList));
        final records = jsonList.map((e) => DnsRecord.fromJson(e)).toList();
        DnsRecord? selected;
        try {
          selected = records.firstWhere((r) => r.id == selectedId);
        } catch (_) {
          selected = records.isNotEmpty ? records.first : null;
        }

        if (selected != null) {
          setState(() {
            _selectedDnsLabel = selected!.label;
            _selectedDnsIp =
                selected.ip1.isNotEmpty ? selected.ip1 : selected.ip2;
            // مهم: به‌روزرسانی DNS controllers با مقادیر جدید
            _dns1Controller.text = selected.ip1;
            _dns2Controller.text = selected.ip2;
          });

          debugPrint('DNS loaded from cache: ${selected.label}');
          debugPrint('DNS1: ${selected.ip1}, DNS2: ${selected.ip2}');
        } else {
          setState(() {
            _selectedDnsLabel = null;
            _selectedDnsIp = null;
          });
        }
      } catch (e) {
        debugPrint('Error loading selected DNS: $e');
        setState(() {
          _selectedDnsLabel = null;
          _selectedDnsIp = null;
        });
      }
    } else {
      setState(() {
        _selectedDnsLabel = null;
        _selectedDnsIp = null;
      });
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeObserver();
    _disposeServices();
    _themeManager.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _dns1Controller = TextEditingController(
      text: DnsConstants.defaultPrimaryDns,
    );
    _dns2Controller = TextEditingController(
      text: DnsConstants.defaultSecondaryDns,
    );
  }

  void _initializeObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeServices() {
    VpnStatusService.startListening();

    _vpnStatusSubscription = VpnStatusService.vpnStatusStream.listen((
      isActive,
    ) {
      if (mounted) {
        debugPrint('📡 VPN status changed via stream: $isActive');

        // بررسی کن که آیا این تغییر واقعی است یا فقط یک به‌روزرسانی
        if (_vpnActive != isActive) {
          debugPrint('Status actually changed: $_vpnActive -> $isActive');
          final wasActive = _vpnActive;

          setState(() {
            _vpnActive = isActive;
            _vpnLoading = false;
          });

          // کنترل انیمیشن بر اساس وضعیت VPN با تغییر نرم
          if (isActive) {
            // روشن شدن با انیمیشن نرم
            _lottieController
                .animateTo(
              0.1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
            )
                .then((_) {
              if (_vpnActive) {
                // دوباره چک کنیم که هنوز فعال است
                _lottieController.repeat();
              }
            });
          } else {
            // خاموش شدن با انیمیشن نرم
            if (_lottieController.isAnimating) {
              // اول سرعت را کم می‌کنیم
              _lottieController
                  .animateTo(
                _lottieController.value,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              )
                  .then((_) {
                // بعد به آرامی به فریم صفر برمی‌گردیم
                final remaining = 1.0 - (_lottieController.value % 1.0);
                _lottieController
                    .animateTo(
                      _lottieController.value + remaining,
                      duration: Duration(
                          milliseconds: (remaining * 1500)
                              .round()), // زمان بیشتر برای نرم‌تر شدن
                      curve: Curves.easeInOut,
                    )
                    .then((_) => _lottieController.stop());
              });
            }
          }

          // فقط در صورتی که در حال بارگذاری نیستیم و تغییر واقعی رخ داده، پیام نمایش بده
          if (!_vpnLoading && wasActive != isActive) {
            // کمی تاخیر برای اطمینان از اینکه UI به‌روز شده
            // VPN status listener updates only handle UI state
            // SnackBar notifications are handled by the action functions (_toggleVpn, _deactivateVpn)
          }
        } else {
          debugPrint('Status unchanged, just updating loading state');
          if (_vpnLoading) {
            setState(() {
              _vpnLoading = false;
            });
          }
        }
      }
    }, onError: (error) {
      debugPrint('❌ Error in VPN status stream: $error');
      if (mounted) {
        setState(() {
          _vpnLoading = false;
        });
      }
    });

    _dataUsageSubscription = VpnStatusService.dataUsageStream.listen(
      (usage) {},
    );
  }

  void _disposeControllers() {
    _dns1Controller.dispose();
    _dns2Controller.dispose();
  }

  void _disposeObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void _disposeServices() {
    _vpnStatusSubscription?.cancel();
    _dataUsageSubscription?.cancel();
    _pingResultSubscription?.cancel();
    VpnStatusService.stopListening();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        if (_vpnActive) {
          // Only check status if VPN was previously active
          _checkInitialStatus();
        }
        if (_autoPingEnabled) {}
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
      default:
        break;
    }
  }

  Future<void> _checkInitialStatus() async {
    try {
      final status = await DnsService.getServiceStatus();
      debugPrint('Initial VPN status check from service: $status');

      // Only update UI state if VPN was previously active
      if (_vpnActive || status) {
        setState(() {
          _vpnActive = status;
          _vpnLoading = false;
        });

        VpnStatusService.notifyVpnStatus(status);
      }
    } catch (e) {
      debugPrint('Error checking initial status: $e');
      setState(() {
        _vpnActive = false;
        _vpnLoading = false;
      });
    }
  }

  Future<void> _toggleVpn(bool value) async {
    if (_vpnLoading) return;

    debugPrint('=== Toggle VPN requested ===');
    debugPrint('Requested value: $value');
    debugPrint('Current UI state: $_vpnActive');

    // ابتدا وضعیت واقعی سرویس را بررسی کن
    try {
      final actualStatus = await DnsService.getServiceStatus();
      debugPrint('Actual service status: $actualStatus');

      // اگر وضعیت UI با وضعیت واقعی متفاوت است، ابتدا UI را اصلاح کن
      if (_vpnActive != actualStatus) {
        debugPrint('⚠️ UI state mismatch detected!');
        debugPrint('Correcting UI state: $_vpnActive -> $actualStatus');
        setState(() {
          _vpnActive = actualStatus;
        });

        // اگر وضعیت درخواستی با وضعیت واقعی یکی است، نیازی به تغییر نیست
        if (value == actualStatus) {
          debugPrint('Requested state matches actual state, no action needed');
          return;
        }
      }

      // حالا می‌توانیم toggle را انجام دهیم
      setState(() {
        _vpnLoading = true;
      });

      // بر اساس وضعیت فعلی، عملیات مناسب را انجام بده
      if (actualStatus) {
        // VPN فعال است، باید غیرفعال شود
        debugPrint('Deactivating VPN...');
        await _deactivateVpn();
      } else {
        // VPN غیرفعال است، باید فعال شود
        debugPrint('Activating VPN...');
        await _activateVpn();
      }

      // بعد از عملیات، وضعیت جدید را بررسی کن
      final newStatus = await DnsService.getServiceStatus();
      debugPrint('New service status after toggle: $newStatus');

      setState(() {
        _vpnActive = newStatus;
        _vpnLoading = false;
      });

      // گزارش وضعیت اتصال به سرور
      await _reportDnsUsage(newStatus);
    } catch (e) {
      debugPrint('❌ Error in _toggleVpn: $e');
      setState(() {
        _vpnLoading = false;
      });

      // در صورت خطا، وضعیت واقعی را دوباره بررسی کن
      try {
        final actualStatus = await DnsService.getServiceStatus();
        setState(() {
          _vpnActive = actualStatus;
        });
      } catch (_) {
        // در صورت خطا در بررسی وضعیت، فرض کن VPN غیرفعال است
        setState(() {
          _vpnActive = false;
        });
      }
    }
  }

  Future<void> _reportDnsUsage(bool isConnected) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      final dnsUsageService = DnsUsageApiService();

      // دریافت اطلاعات دستگاه
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final deviceInfoData = DeviceInfo(
        deviceType: 'android',
        brand: deviceInfo.brand,
        model: deviceInfo.model,
        osVersion: deviceInfo.version.release,
      );

      // دریافت اطلاعات شبکه
      final connectivity = await Connectivity().checkConnectivity();
      String? ipAddress;
      try {
        final response = await http.get(Uri.parse('https://api.ipify.org'));
        ipAddress = response.statusCode == 200 ? response.body : null;
      } catch (_) {}

      final networkInfoData = NetworkInfo(
        connectionType:
            connectivity == ConnectivityResult.mobile ? 'mobile' : 'wifi',
        carrierName:
            connectivity == ConnectivityResult.mobile ? 'Unknown' : null,
        ipAddress: ipAddress,
        mobileNetworkType:
            connectivity == ConnectivityResult.mobile ? 'Unknown' : null,
      );

      // ساخت درخواست
      final request = DnsUsageRequest(
        fcmToken: fcmToken,
        dns: DnsInfo(
          label: _selectedDnsLabel ?? '',
          ip1: _dns1Controller.text.trim(),
          ip2: _dns2Controller.text.trim(),
        ),
        timestamp: DateTime.now(),
        connectionType: isConnected
            ? ConnectionType.connected
            : ConnectionType.disconnected,
        networkInfo: networkInfoData,
      );

      // ارسال به سرور
      debugPrint('=== ارسال اطلاعات DNS به سرور ===');
      debugPrint('Device Info: ${deviceInfoData.toJson()}');
      debugPrint('Network Info: ${networkInfoData.toJson()}');
      debugPrint('DNS Info: ${request.dns.toJson()}');
      debugPrint('Connection Type: ${request.connectionType}');
      debugPrint('Timestamp: ${request.timestamp}');

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      debugPrint('User ID: $userId');

      final response = await dnsUsageService.recordDnsUsage(
        userDnsId: request.dns.label,
        internetTag: request.networkInfo.connectionType,
        userId: userId,
      );
      if (!response.status) {
        debugPrint('خطا در ارسال وضعیت اتصال به سرور: ${response.message}');
      }
    } catch (e) {
      debugPrint('خطا در ارسال وضعیت اتصال: $e');
    }
  }

  Future<void> _activateVpn() async {
    final dns1 = _dns1Controller.text.trim();
    final dns2 = _dns2Controller.text.trim();
    try {
      debugPrint('Activating VPN with DNS1: $dns1, DNS2: $dns2');
      final result = await DnsService.changeDns(dns1, dns2);

      // بعد از تلاش برای فعال‌سازی، وضعیت واقعی را بررسی کن
      await Future.delayed(const Duration(
          milliseconds: 500)); // کمی صبر کن تا سرویس راه‌اندازی شود
      final actualStatus = await DnsService.getServiceStatus();
      debugPrint(
          'VPN activation result: ${result.success}, actual status: $actualStatus');

      showEnhancedSnackBar(
        message: result.message,
        type: result.success ? SnackBarType.success : SnackBarType.error,
      );

      // وضعیت UI را بر اساس وضعیت واقعی سرویس تنظیم کن
      setState(() {
        _vpnActive = actualStatus;
        _vpnLoading = false;
      });
    } catch (e) {
      debugPrint('Error activating VPN: $e');
      showEnhancedSnackBar(
        message: 'خطا در فعال‌سازی VPN: $e',
        type: SnackBarType.error,
      );
      setState(() {
        _vpnActive = false;
        _vpnLoading = false;
      });
    }
  }

  Future<void> _deactivateVpn() async {
    try {
      debugPrint('Deactivating VPN...');
      final success = await DnsService.stopVpn();

      // بعد از تلاش برای غیرفعال‌سازی، وضعیت واقعی را بررسی کن
      await Future.delayed(
          const Duration(milliseconds: 500)); // کمی صبر کن تا سرویس متوقف شود
      final actualStatus = await DnsService.getServiceStatus();
      debugPrint(
          'VPN deactivation success: $success, actual status: $actualStatus');

      showEnhancedSnackBar(
        message: success
            ? DnsConstants.errorMessages['vpnDisabled']!
            : DnsConstants.errorMessages['vpnDisableError']!,
        type: success ? SnackBarType.success : SnackBarType.error,
      );

      // وضعیت UI را بر اساس وضعیت واقعی سرویس تنظیم کن
      setState(() {
        _vpnActive = actualStatus;
        _vpnLoading = false;
      });
    } catch (e) {
      debugPrint('Error deactivating VPN: $e');
      showEnhancedSnackBar(
        message: 'خطا در غیرفعال‌سازی VPN: $e',
        type: SnackBarType.error,
      );

      // در صورت خطا هم وضعیت واقعی را بررسی کن
      try {
        final actualStatus = await DnsService.getServiceStatus();
        setState(() {
          _vpnActive = actualStatus;
          _vpnLoading = false;
        });
      } catch (_) {
        setState(() {
          _vpnActive = false;
          _vpnLoading = false;
        });
      }
    }
  }

  /// Enhanced SnackBar system with animations and better styling
  /// This replaces both _showMessage and _showOptimizedMessage with a unified system
  void showEnhancedSnackBar({
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    bool dismissible = true,
    VoidCallback? onTap,
  }) {
    if (!mounted) return;

    final now = DateTime.now();

    // Anti-spam protection
    if (_lastSnackBarMessage == message &&
        _lastSnackBarTime != null &&
        now.difference(_lastSnackBarTime!).inSeconds < 2) {
      return;
    }

    // Rate limiting
    if (_lastSnackBarTime != null &&
        now.difference(_lastSnackBarTime!).inMilliseconds < 800) {
      return;
    }

    _lastSnackBarMessage = message;
    _lastSnackBarTime = now;

    // Clear any existing SnackBars to prevent stacking
    ScaffoldMessenger.of(context).clearSnackBars();

    // Get appropriate colors and icon based on type
    final isDark = _themeManager.isDarkModeActive(context);
    final snackBarStyle = _getSnackBarStyle(type, isDark);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon with subtle animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Icon(
                      snackBarStyle.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Message with fade-in animation
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Optional close button
            if (dismissible)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
              ),
          ],
        ),
        backgroundColor: snackBarStyle.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: snackBarStyle.borderColor,
            width: 1,
          ),
        ),
        elevation: 6,
      ),
    );
  }

  /// Helper method to get SnackBar style based on type
  SnackBarStyle _getSnackBarStyle(SnackBarType type, bool isDark) {
    switch (type) {
      case SnackBarType.success:
        return SnackBarStyle(
          backgroundColor: const Color(0xFF2E7D32), // Dark green
          borderColor: const Color(0xFF4CAF50).withOpacity(0.5),
          icon: Icons.check_circle,
        );
      case SnackBarType.error:
        return SnackBarStyle(
          backgroundColor: const Color(0xFFD32F2F), // Dark red
          borderColor: const Color(0xFFE57373).withOpacity(0.5),
          icon: Icons.error,
        );
      case SnackBarType.warning:
        return SnackBarStyle(
          backgroundColor: const Color(0xFFEF6C00), // Dark orange
          borderColor: const Color(0xFFFFB74D).withOpacity(0.5),
          icon: Icons.warning,
        );
      case SnackBarType.info:
        return SnackBarStyle(
          backgroundColor: const Color(0xFF1976D2), // Dark blue
          borderColor: const Color(0xFF64B5F6).withOpacity(0.5),
          icon: Icons.info,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) => Scaffold(
        key: _scaffoldKey,
        drawer: const CustomDrawer(),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.menu,
              color: isDark ? AppColors.darkIconPrimary : AppColors.textPrimary,
            ),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            context.tr('appTitle'),
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          toolbarHeight: kToolbarHeight,
          actions: [
            const NotificationBell(),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: AppColors.backgroundGrey,
                child: Icon(
                  Icons.person_outline,
                  color: isDark
                      ? AppColors.darkIconPrimary
                      : AppColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () {
                showEnhancedSnackBar(
                  message: context.tr('profileComingSoon'),
                  type: SnackBarType.info,
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const minCardHeight = 170.0;
              const totalSpacing = 24.0;
              final availableHeight = constraints.maxHeight - totalSpacing;
              double cardHeight = availableHeight / 3;
              if (cardHeight < minCardHeight) cardHeight = minCardHeight;
              const cardPadding = EdgeInsets.all(12);
              return Padding(
                padding: cardPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: 12,
                      child: _buildConnectionStatusCard(cardHeight),
                    ),
                    const SizedBox(height: 8),
                    Expanded(flex: 10, child: _buildSpeedTestCard(cardHeight)),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 10,
                      child: _buildConfigurationCard(cardHeight),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// کارت وضعیت اتصال DNS
  Widget _buildConnectionStatusCard(double height) {
    final isDark = _themeManager.isDarkModeActive(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(24, context, min: 10, max: 28, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(
          responsiveSize(14, context, min: 6, max: 20, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // بهبود انیمیشن با کاهش اندازه و تنظیم موقعیت
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double factor = 1.2; // کاهش اندازه انیمیشن
                return Opacity(
                  opacity: 0.45, // کاهش شفافیت برای وضوح بیشتر متن‌ها
                  child: Align(
                    alignment: Alignment.center, // تنظیم در مرکز
                    child: OverflowBox(
                      maxWidth: constraints.maxWidth * factor,
                      maxHeight: constraints.maxHeight * factor,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          responsiveSize(
                            24,
                            context,
                            min: 10,
                            max: 40,
                            scaleByHeight: true,
                          ),
                        ),
                        child: Lottie.asset(
                          'assets/icone/laptop.json',
                          width: constraints.maxWidth * factor,
                          height: constraints.maxHeight * factor,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          controller: _lottieController,
                          animate: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // استفاده از SingleChildScrollView برای جلوگیری از سرریز
          SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(), // غیرفعال کردن اسکرول دستی
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: responsiveSize(
                        120,
                        context,
                        min: 60,
                        max: 160,
                        scaleByHeight: true,
                      ),
                      height: responsiveSize(
                        90,
                        context,
                        min: 40,
                        max: 120,
                        scaleByHeight: true,
                      ),
                    ),
                    GestureDetector(
                      onTap: _vpnLoading ? null : () => _toggleVpn(!_vpnActive),
                      child: TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 500),
                        tween: ColorTween(
                          begin: _vpnLoading
                              ? AppColors.textSuccess
                              : (_vpnActive
                                  ? AppColors.textSuccess
                                  : AppColors.statusDisconnected),
                          end: _vpnActive
                              ? AppColors.textSuccess
                              : AppColors.statusDisconnected,
                        ),
                        builder: (context, color, _) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: responsiveSize(
                              70,
                              context,
                              min: 40,
                              max: 90,
                              scaleByHeight: true,
                            ),
                            height: responsiveSize(
                              70,
                              context,
                              min: 40,
                              max: 90,
                              scaleByHeight: true,
                            ),
                            decoration: BoxDecoration(
                              color: color ?? AppColors.statusDisconnected,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (color ?? AppColors.statusDisconnected)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _vpnLoading
                                  ? Center(
                                      key: const ValueKey('loading'),
                                      child: SizedBox(
                                        width: responsiveSize(
                                          36,
                                          context,
                                          min: 20,
                                          max: 40,
                                          scaleByHeight: true,
                                        ),
                                        height: responsiveSize(
                                          36,
                                          context,
                                          min: 20,
                                          max: 40,
                                          scaleByHeight: true,
                                        ),
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.pureWhite,
                                          ),
                                          strokeWidth: 4,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.power_settings_new,
                                      key: const ValueKey('power'),
                                      color: AppColors.pureWhite,
                                      size: responsiveSize(
                                        40,
                                        context,
                                        min: 24,
                                        max: 48,
                                        scaleByHeight: true,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    // ...existing code...
                  ],
                ),
                SizedBox(
                  height: responsiveSize(
                    16, // کاهش فاصله عمودی
                    context,
                    min: 8,
                    max: 24,
                    scaleByHeight: true,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: (_selectedDnsLabel != null &&
                              _selectedDnsIp != null &&
                              _selectedDnsIp!.isNotEmpty)
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => DnsInfoPopup(
                                  label: _selectedDnsLabel!,
                                  ip: _selectedDnsIp!,
                                  ping: null,
                                ),
                              );
                            }
                          : null,
                      child: Icon(
                        Icons.info_outline,
                        size: responsiveSize(
                          20,
                          context,
                          min: 14,
                          max: 28,
                          scaleByHeight: true,
                        ),
                        color: (_selectedDnsLabel != null &&
                                _selectedDnsIp != null &&
                                _selectedDnsIp!.isNotEmpty)
                            ? AppColors.brightBlue
                            : AppColors.textLight,
                      ),
                    ),
                    SizedBox(
                      width: responsiveSize(
                        8,
                        context,
                        min: 4,
                        max: 16,
                        scaleByHeight: true,
                      ),
                    ),
                    SemiTransparentText(
                      text: _vpnActive
                          ? context.tr('connected')
                          : context.tr('disconnected'),
                      style: TextStyle(
                        fontSize: responsiveSize(
                          24,
                          context,
                          min: 16,
                          max: 48,
                          scaleByHeight: true,
                        ),
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      backgroundColor: _vpnActive
                          ? AppColors.textSuccess
                          : Colors.red, // Bright red for disconnected state
                      opacity: 0.15,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                SizedBox(
                  height: responsiveSize(
                    4, // کاهش فاصله عمودی
                    context,
                    min: 2,
                    max: 8,
                    scaleByHeight: true,
                  ),
                ),
                if (_selectedDnsLabel != null)
                  Row(
                    children: [
                      Icon(
                        Icons.dns,
                        size: responsiveSize(
                          20,
                          context,
                          min: 14,
                          max: 28,
                          scaleByHeight: true,
                        ),
                        color: _vpnActive
                            ? AppColors.textSuccess
                            : AppColors.brightBlue,
                      ),
                      SizedBox(
                        width: responsiveSize(
                          8,
                          context,
                          min: 4,
                          max: 16,
                          scaleByHeight: true,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // نمایش نام DNS
                            SemiTransparentText(
                              text: _selectedDnsLabel ?? 'DNS',
                              style: TextStyle(
                                fontSize: responsiveSize(
                                  16,
                                  context,
                                  min: 12,
                                  max: 30,
                                  scaleByHeight: true,
                                ),
                                fontWeight: FontWeight.bold,
                                color: _vpnActive
                                    ? AppColors.textSuccess
                                    : AppColors.brightBlue,
                              ),
                              backgroundColor: _vpnActive
                                  ? AppColors.textSuccess
                                  : AppColors.brightBlue,
                              opacity: 0.1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 4),
                            // نمایش آدرس‌های IP در یک ردیف برای صرفه‌جویی در فضا
                            SemiTransparentText(
                              text:
                                  "${_dns1Controller.text} / ${_dns2Controller.text}",
                              style: TextStyle(
                                fontSize: responsiveSize(
                                  12, // کاهش اندازه فونت
                                  context,
                                  min: 8,
                                  max: 20,
                                  scaleByHeight: true,
                                ),
                                fontFamily: 'monospace',
                                color: _vpnActive
                                    ? AppColors.textSuccess
                                    : AppColors.brightBlue,
                              ),
                              backgroundColor: _vpnActive
                                  ? AppColors.textSuccess
                                  : AppColors.brightBlue,
                              opacity: 0.08,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                // حذف تکرار اطلاعات DNS
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// کارت تست سرعت
  Widget _buildSpeedTestCard(double height) {
    final isDark = _themeManager.isDarkModeActive(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(12, context, min: 6, max: 18, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(
          responsiveSize(12, context, min: 6, max: 16, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // دکمه اجرای تست سرعت
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SpeedTestPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveSize(
                      16,
                      context,
                      min: 8,
                      max: 25,
                      scaleByHeight: true,
                    ),
                    vertical: responsiveSize(
                      8,
                      context,
                      min: 4,
                      max: 12,
                      scaleByHeight: true,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brightBlue,
                    borderRadius: BorderRadius.circular(
                      responsiveSize(
                        16,
                        context,
                        min: 8,
                        max: 25,
                        scaleByHeight: true,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brightBlue.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    context.tr('startTest'),
                    style: TextStyle(
                      fontSize: responsiveSize(
                        14,
                        context,
                        min: 12,
                        max: 30,
                        scaleByHeight: true,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
              // آیکون سرعت با افکت سایه
              Container(
                width: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                height: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textSuccess,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textSuccess.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.speed,
                  color: AppColors.pureWhite,
                  size: responsiveSize(
                    18,
                    context,
                    min: 14,
                    max: 25,
                    scaleByHeight: true,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: responsiveSize(
              8, // کاهش فاصله عمودی
              context,
              min: 4,
              max: 12,
              scaleByHeight: true,
            ),
          ),
          SemiTransparentText(
            text: context.tr('internetSpeedTest'),
            style: TextStyle(
              fontSize: responsiveSize(
                18,
                context,
                min: 14,
                max: 48,
                scaleByHeight: true,
              ),
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            backgroundColor: AppColors.textSuccess,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(10),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          SizedBox(
            height: responsiveSize(
              4, // کاهش فاصله عمودی
              context,
              min: 2,
              max: 6,
              scaleByHeight: true,
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary)
                  .withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: responsiveSize(
                    15,
                    context,
                    min: 10,
                    max: 30,
                    scaleByHeight: true,
                  ),
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: context.tr('speedTest'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('yourInternetSpeedBetween'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('device'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('measuresAndUsesConnection'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// کارت پیکربندی
  Widget _buildConfigurationCard(double height) {
    final isDark = _themeManager.isDarkModeActive(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(12, context, min: 6, max: 18, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(
          responsiveSize(12, context, min: 6, max: 16, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // دکمه Switch (فعال)
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DnsListPage(),
                    ),
                  );

                  // اگر کاربر DNS جدیدی انتخاب کرده
                  if (result != null && result is DnsRecord) {
                    debugPrint('User selected DNS: ${result.label}');
                    debugPrint('IP1: ${result.ip1}, IP2: ${result.ip2}');

                    setState(() {
                      _selectedDnsLabel = result.label;
                      _selectedDnsIp =
                          result.ip1.isNotEmpty ? result.ip1 : result.ip2;
                      // مهم: به‌روزرسانی DNS controllers با مقادیر جدید
                      _dns1Controller.text = result.ip1;
                      _dns2Controller.text = result.ip2;
                    });

                    // ذخیره DNS انتخابی در SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('cached_selected_dns', result.id);

                    // اگر VPN فعال است، با DNS جدید مجدداً متصل شود
                    if (_vpnActive) {
                      showEnhancedSnackBar(
                        message: 'در حال اعمال DNS جدید...',
                        type: SnackBarType.info,
                      );

                      // ابتدا VPN را قطع کن
                      await _deactivateVpn();

                      // سپس با DNS جدید وصل کن
                      await Future.delayed(const Duration(milliseconds: 500));
                      await _activateVpn();
                    }
                  } else {
                    // اگر کاربر بدون انتخاب برگشت، DNS قبلی را بارگذاری کن
                    await _loadSelectedDnsLabel();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveSize(
                      16,
                      context,
                      min: 8,
                      max: 25,
                      scaleByHeight: true,
                    ),
                    vertical: responsiveSize(
                      8,
                      context,
                      min: 4,
                      max: 12,
                      scaleByHeight: true,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brightBlue,
                    borderRadius: BorderRadius.circular(
                      responsiveSize(
                        16,
                        context,
                        min: 8,
                        max: 25,
                        scaleByHeight: true,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brightBlue.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    context.tr('changeDns'),
                    style: TextStyle(
                      fontSize: responsiveSize(
                        14,
                        context,
                        min: 12,
                        max: 30,
                        scaleByHeight: true,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
              // آیکون تنظیمات با افکت سایه
              Container(
                width: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                height: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textSuccess,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textSuccess.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      color: AppColors.pureWhite,
                      size: responsiveSize(
                        16,
                        context,
                        min: 12,
                        max: 20,
                        scaleByHeight: true,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: responsiveSize(
                          6,
                          context,
                          min: 4,
                          max: 8,
                          scaleByHeight: true,
                        ),
                        height: responsiveSize(
                          6,
                          context,
                          min: 4,
                          max: 8,
                          scaleByHeight: true,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.textSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: responsiveSize(
              8, // کاهش فاصله عمودی
              context,
              min: 4,
              max: 12,
              scaleByHeight: true,
            ),
          ),
          SemiTransparentText(
            text: context.tr('networkConfiguration'),
            style: TextStyle(
              fontSize: responsiveSize(
                18,
                context,
                min: 14,
                max: 48,
                scaleByHeight: true,
              ),
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            backgroundColor: AppColors.brightBlue,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(10),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          SizedBox(
            height: responsiveSize(
              4, // کاهش فاصله عمودی
              context,
              min: 2,
              max: 6,
              scaleByHeight: true,
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary)
                  .withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: responsiveSize(
                    15,
                    context,
                    min: 10,
                    max: 30,
                    scaleByHeight: true,
                  ),
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: context.tr('inThisSection'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('networkSettings'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('customizeYour'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('configuration'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('chooseAccordingToNeeds'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
