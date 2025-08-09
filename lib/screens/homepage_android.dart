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
    with WidgetsBindingObserver {
  late ThemeManager _themeManager;

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

  // Stream subscriptions
  StreamSubscription<bool>? _vpnStatusSubscription;
  StreamSubscription<Map<String, int>>? _dataUsageSubscription;
  StreamSubscription<Map<String, DnsStatus>>? _pingResultSubscription;

  @override
  void initState() {
    super.initState();
    _themeManager = Provider.of<ThemeManager>(context, listen: false);
    _initializeControllers();
    _initializeObserver();
    _initializeServices();
    _themeManager.loadThemeMode();
    setState(() {
      _vpnLoading = true;
    });
    _checkInitialStatus();
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
        setState(() {
          _selectedDnsLabel = selected?.label;
          _selectedDnsIp = selected != null
              ? (selected.ip1.isNotEmpty ? selected.ip1 : selected.ip2)
              : null;
        });
      } catch (_) {
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
        setState(() {
          _vpnActive = isActive;
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
      _updateVpnState(active: status, loading: false);
    } catch (e) {
      _updateVpnState(loading: false);
      debugPrint('Error checking initial status: $e');
    }
  }

  Future<void> _toggleVpn(bool value) async {
    if (_vpnLoading) return;
    _updateVpnState(loading: true);
    value ? await _activateVpn() : await _deactivateVpn();
    _updateVpnState(loading: false);

    // گزارش وضعیت اتصال به سرور
    await _reportDnsUsage(value);
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
      final result = await DnsService.changeDns(dns1, dns2);
      _showMessage(
        result.message,
        result.success ? AppColors.textSuccess : AppColors.textError,
      );
      
      // اگر تغییر DNS موفقیت‌آمیز نبود، وضعیت VPN را به‌روز نکن
      if (!result.success) {
        _updateVpnState(active: false, loading: false);
      }
    } catch (e) {
      _showMessage('خطا در فعال‌سازی VPN: $e', AppColors.textError);
      _updateVpnState(active: false, loading: false);
    }
  }

  Future<void> _deactivateVpn() async {
    try {
      final success = await DnsService.stopVpn();
      _showMessage(
        success
            ? DnsConstants.errorMessages['vpnDisabled']!
            : DnsConstants.errorMessages['vpnDisableError']!,
        success ? AppColors.textSuccess : AppColors.textError,
      );
    } catch (e) {
      _showMessage('خطا در غیرفعال‌سازی VPN: $e', AppColors.textError);
    }
  }

  void _updateVpnState({bool? active, bool? loading}) {
    if (!mounted) return;
    setState(() {
      if (active != null) _vpnActive = active;
      if (loading != null) _vpnLoading = loading;
    });
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
                  color: isDark ? AppColors.darkIconPrimary : AppColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('profileComingSoon')),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
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
                    alignment: Alignment.centerRight, // تغییر موقعیت به سمت راست
                    child: OverflowBox(
                      maxWidth: constraints.maxWidth * factor,
                      maxHeight: constraints.maxHeight * factor,
                      alignment: Alignment.centerRight,
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
                          alignment: Alignment.centerRight,
                          repeat: true,
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
                      child: Container(
                        width: responsiveSize(
                          70, // کاهش اندازه دکمه
                          context,
                          min: 40,
                          max: 90,
                          scaleByHeight: true,
                        ),
                        height: responsiveSize(
                          70, // کاهش اندازه دکمه
                          context,
                          min: 40,
                          max: 90,
                          scaleByHeight: true,
                        ),
                        decoration: BoxDecoration(
                          color: _vpnActive
                              ? AppColors.textSuccess
                              : AppColors.textError,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_vpnActive ? AppColors.textSuccess : AppColors.textError).withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _vpnLoading
                            ? Center(
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.pureWhite,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new,
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
                      text: _vpnActive ? context.tr('connected') : context.tr('disconnected'),
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
                      backgroundColor: _vpnActive ? AppColors.textSuccess : AppColors.textError,
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
                            SemiTransparentText(
                              text: '${_selectedDnsLabel!}',
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
                            SizedBox(height: 4),
                            SemiTransparentText(
                              text: context.tr('nameLabel'),
                              style: TextStyle(
                                fontSize: responsiveSize(
                                  14,
                                  context,
                                  min: 10,
                                  max: 24,
                                  scaleByHeight: true,
                                ),
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                              backgroundColor: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              opacity: 0.1,
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                            // نمایش آدرس‌های IP در یک ردیف برای صرفه‌جویی در فضا
                            Row(
                              children: [
                                Expanded(
                                  child: SemiTransparentText(
                                    text: "${_dns1Controller.text} / ${_dns2Controller.text}",
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
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  ),
                                ),
                              ],
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
              color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withOpacity(0.05),
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DnsListPage(),
                    ),
                  );
                  // پس از بازگشت، دی‌ان‌اس انتخابی را مجدداً بارگذاری کن
                  await _loadSelectedDnsLabel();
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
              color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withOpacity(0.05),
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
