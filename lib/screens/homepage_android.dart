import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../path/path.dart';
import 'dns_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
// ...existing code...

/// صفحه اصلی برنامه Fire DNS
class FireDNSHomePage extends StatefulWidget {
  final String title;

  const FireDNSHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<FireDNSHomePage> createState() => _FireDNSHomePageState();
}

class _FireDNSHomePageState extends State<FireDNSHomePage>
    with WidgetsBindingObserver {
  // وضعیت موفقیت ست شدن DNS برای انیمیشن دکمه
  // ...existing code...
  // ...existing code...

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
    _initializeControllers();
    _initializeObserver();
    _initializeServices();
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
  }

  Future<void> _activateVpn() async {
    final dns1 = _dns1Controller.text.trim();
    final dns2 = _dns2Controller.text.trim();
    try {
      final success = await DnsService.changeDns(dns1, dns2);
      _showMessage(
        success
            ? DnsConstants.errorMessages['vpnActivated']!
            : DnsConstants.errorMessages['vpnActivationError']!,
        success ? Colors.green : Colors.red,
      );
    } catch (e) {
      _showMessage('خطا در فعال‌سازی VPN: $e', Colors.red);
    }
  }

  // ...existing code...

  Future<void> _deactivateVpn() async {
    try {
      final success = await DnsService.stopVpn();
      _showMessage(
        success
            ? DnsConstants.errorMessages['vpnDisabled']!
            : DnsConstants.errorMessages['vpnDisableError']!,
        success ? Colors.green : Colors.red,
      );
    } catch (e) {
      _showMessage('خطا در غیرفعال‌سازی VPN: $e', Colors.red);
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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Fire DNS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        toolbarHeight: kToolbarHeight,
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
    );
  }

  /// کارت وضعیت اتصال DNS
  Widget _buildConnectionStatusCard(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(24, context, min: 10, max: 28, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(
          responsiveSize(14, context, min: 6, max: 20, scaleByHeight: true),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double factor = 1.55;
                return Opacity(
                  opacity: 0.88,
                  child: Center(
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
                          repeat: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            child: Column(
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
                          80,
                          context,
                          min: 40,
                          max: 100,
                          scaleByHeight: true,
                        ),
                        height: responsiveSize(
                          80,
                          context,
                          min: 40,
                          max: 100,
                          scaleByHeight: true,
                        ),
                        decoration: BoxDecoration(
                          color: _vpnActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
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
                                      Colors.white,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new,
                                color: Colors.white,
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
                    30,
                    context,
                    min: 12,
                    max: 40,
                    scaleByHeight: true,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap:
                          (_selectedDnsLabel != null &&
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
                        color:
                            (_selectedDnsLabel != null &&
                                _selectedDnsIp != null &&
                                _selectedDnsIp!.isNotEmpty)
                            ? Colors.blue
                            : Colors.grey,
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
                    Text(
                      _vpnActive ? 'متصل شد' : 'قطع اتصال',
                      style: TextStyle(
                        fontSize: responsiveSize(
                          24,
                          context,
                          min: 16,
                          max: 48,
                          scaleByHeight: true,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: responsiveSize(
                    8,
                    context,
                    min: 4,
                    max: 16,
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
                        color: _vpnActive ? Colors.green : Colors.blue,
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
                        child: Text(
                          'DNS انتخابی: ${_selectedDnsLabel!}' +
                              (_selectedDnsIp != null &&
                                      _selectedDnsIp!.isNotEmpty
                                  ? ' (${_selectedDnsIp!})'
                                  : ''),
                          style: TextStyle(
                            fontSize: responsiveSize(
                              16,
                              context,
                              min: 12,
                              max: 30,
                              scaleByHeight: true,
                            ),
                            color: _vpnActive ? Colors.green : Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (!_vpnActive) ...[
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
                          color: _vpnActive ? Colors.green : Colors.blue,
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
                          child: Text(
                            'DNS انتخابی: ${_selectedDnsLabel!}' +
                                (_selectedDnsIp != null &&
                                        _selectedDnsIp!.isNotEmpty
                                    ? ' (${_selectedDnsIp!})'
                                    : ''),
                            style: TextStyle(
                              fontSize: responsiveSize(
                                16,
                                context,
                                min: 12,
                                max: 30,
                                scaleByHeight: true,
                              ),
                              color: _vpnActive ? Colors.green : Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// کارت تست سرعت
  Widget _buildSpeedTestCard(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(12, context, min: 6, max: 18, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsiveSize(12, context, min: 6, max: 16, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: const Color(0xFF1976D2), // Strong blue
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
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'شروع تست',
                    style: TextStyle(
                      fontSize: responsiveSize(
                        14,
                        context,
                        min: 12,
                        max: 30,
                        scaleByHeight: true,
                      ),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // آیکون سرعت
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
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.speed,
                  color: Colors.white,
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
              12,
              context,
              min: 4,
              max: 20,
              scaleByHeight: true,
            ),
          ),

          Text(
            'تست سرعت اینترنت',
            style: TextStyle(
              fontSize: responsiveSize(
                18,
                context,
                min: 14,
                max: 48,
                scaleByHeight: true,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(
            height: responsiveSize(
              8,
              context,
              min: 2,
              max: 10,
              scaleByHeight: true,
            ),
          ),

          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: responsiveSize(
                  15,
                  context,
                  min: 10,
                  max: 30,
                  scaleByHeight: true,
                ),
                color: Colors.grey,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: 'تست سرعت',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' سرعت اینترنت شما را بین '),
                TextSpan(
                  text: 'دستگاه',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      ' و سرور تست اندازه‌گیری می‌کند و از اتصال اینترنت فعلی شما استفاده می‌کند.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// کارت پیکربندی
  Widget _buildConfigurationCard(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(12, context, min: 6, max: 18, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsiveSize(12, context, min: 6, max: 16, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: const Color(0xFF1976D2), // Strong blue
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
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'تغییر DNS',
                    style: TextStyle(
                      fontSize: responsiveSize(
                        14,
                        context,
                        min: 12,
                        max: 30,
                        scaleByHeight: true,
                      ),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // آیکون تنظیمات
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
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.white,
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
                          color: Colors.green,
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
              12,
              context,
              min: 4,
              max: 20,
              scaleByHeight: true,
            ),
          ),

          Text(
            'پیکربندی شبکه',
            style: TextStyle(
              fontSize: responsiveSize(
                18,
                context,
                min: 14,
                max: 48,
                scaleByHeight: true,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(
            height: responsiveSize(
              8,
              context,
              min: 2,
              max: 10,
              scaleByHeight: true,
            ),
          ),

          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: responsiveSize(
                  15,
                  context,
                  min: 10,
                  max: 30,
                  scaleByHeight: true,
                ),
                color: Colors.grey,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'در این بخش می‌توانید '),
                TextSpan(
                  text: 'تنظیمات شبکه',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' خود را شخصی‌سازی کنید و '),
                TextSpan(
                  text: 'پیکربندی',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' مناسب با نیاز اتصال خود را انتخاب نمایید.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
