import 'package:flutter/material.dart';
import 'dart:async';
import '../models/dns_status.dart';
import '../models/google_connectivity_result.dart';
import '../services/dns_service.dart';
import '../services/vpn_status_service.dart';
import '../services/auto_ping_service.dart';
import '../constants/dns_constants.dart';
import '../widgets/settings_drawer.dart';
import 'red_settings_screen.dart';
import 'personal_screen.dart';
import 'config_screen.dart';
import 'dns_record_list_screen.dart';
import 'dns_manager_screen.dart';
import 'dns_api_demo_screen.dart';

/// صفحه اصلی برنامه DNS Changer
class DnsChangerHomePage extends StatefulWidget {
  final String title;

  const DnsChangerHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<DnsChangerHomePage> createState() => _DnsChangerHomePageState();
}

class _DnsChangerHomePageState extends State<DnsChangerHomePage>
    with WidgetsBindingObserver {
  // Controllers
  late final TextEditingController _dns1Controller;
  late final TextEditingController _dns2Controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  bool _vpnActive = false;
  bool _autoPingEnabled = false;
  bool _isTestingConnectivity = false;
  bool _autoStartOnBoot = true;
  bool _darkTheme = false;
  bool _notificationsEnabled = true;

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
    _checkInitialStatus();
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

    _dataUsageSubscription = VpnStatusService.dataUsageStream.listen((usage) {
      // مصرف داده در UI جدید نیازی نیست
    });

    _pingResultSubscription = AutoPingService.pingResultStream.listen((
      results,
    ) {
      if (mounted) {
        setState(() {
          // Ping results received - can be used for updating UI if needed
        });
      }
    });
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
    AutoPingService.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_autoPingEnabled) {
          _startAutoPing();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        AutoPingService.stop();
        break;
      default:
        break;
    }
  }

  Future<void> _checkInitialStatus() async {
    try {
      final status = await DnsService.getServiceStatus();
      if (mounted) {
        setState(() {
          _vpnActive = status;
        });
      }
    } catch (e) {
      debugPrint('Error checking initial status: $e');
    }
  }

  void _startAutoPing() {
    AutoPingService.start(
      dns1: _dns1Controller.text.trim(),
      dns2: _dns2Controller.text.trim(),
    );
  }

  Future<void> _toggleVpn(bool value) async {
    if (value) {
      await _activateVpn();
    } else {
      await _deactivateVpn();
    }
  }

  Future<void> _activateVpn() async {
    final dns1 = _dns1Controller.text.trim();
    final dns2 = _dns2Controller.text.trim();

    try {
      final success = await DnsService.changeDns(dns1, dns2);
      if (success) {
        _showSuccessMessage(DnsConstants.errorMessages['vpnActivated']!);
      } else {
        _showErrorMessage(DnsConstants.errorMessages['vpnActivationError']!);
      }
    } catch (e) {
      _showErrorMessage('خطا در فعال‌سازی VPN: $e');
    }
  }

  Future<void> _deactivateVpn() async {
    try {
      final success = await DnsService.stopVpn();
      if (success) {
        _showSuccessMessage(DnsConstants.errorMessages['vpnDisabled']!);
      } else {
        _showErrorMessage(DnsConstants.errorMessages['vpnDisableError']!);
      }
    } catch (e) {
      _showErrorMessage('خطا در غیرفعال‌سازی VPN: $e');
    }
  }

  Future<void> _testGoogleConnectivity() async {
    if (_isTestingConnectivity) return;

    setState(() {
      _isTestingConnectivity = true;
    });

    try {
      final result = await DnsService.testGoogleConnectivity();
      if (mounted) {
        setState(() {
          _isTestingConnectivity = false;
        });
        _showConnectivityResult(result);
      }
    } catch (e) {
      setState(() {
        _isTestingConnectivity = false;
      });
      _showErrorMessage('خطا در تست اتصال: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showConnectivityResult(GoogleConnectivityResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.overallStatus
              ? DnsConstants.errorMessages['connectivityTestPassed']!
              : DnsConstants.errorMessages['connectivityTestFailed']!,
        ),
        backgroundColor: result.overallStatus ? Colors.green : Colors.red,
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('لیست DNS'),
              subtitle: const Text('مدیریت ساده رکوردها'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DnsRecordListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dns),
              title: const Text('مدیریت کامل DNS'),
              subtitle: const Text('مدیریت پیشرفته با آمار'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DnsManagerScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('نمونه API'),
              subtitle: const Text('مثال‌های استفاده از API'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DnsApiDemoScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About My DNS'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My DNS - Advanced DNS Manager'),
            SizedBox(height: 10),
            Text('Version: 1.0.0'),
            SizedBox(height: 10),
            Text('A powerful DNS management app with API integration.'),
            SizedBox(height: 10),
            Text('Features:'),
            Text('• DNS record management'),
            Text('• Speed testing'),
            Text('• Connection monitoring'),
            Text('• API integration'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support This App'),
        content: const Text(
          'Thank you for using My DNS! Your support helps us continue developing and improving this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // اینجا می‌توانید لینک پرداخت یا rate app اضافه کنید
            },
            child: const Text('Support'),
          ),
        ],
      ),
    );
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
          'My DNS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.apps, color: Colors.black),
            onPressed: () => _showMenuOptions(context),
          ),
        ],
      ),
      drawer: SettingsDrawer(
        autoStartOnBoot: _autoStartOnBoot,
        darkTheme: _darkTheme,
        notificationsEnabled: _notificationsEnabled,
        currentDns1: _dns1Controller.text.isEmpty
            ? '10.10.14.1'
            : _dns1Controller.text,
        currentDns2: _dns2Controller.text.isEmpty
            ? 'Unknown'
            : _dns2Controller.text,
        currentIpv4: '1.1.1.1',
        onAutoStartChanged: (value) {
          setState(() {
            _autoStartOnBoot = value;
          });
        },
        onDarkThemeChanged: (value) {
          setState(() {
            _darkTheme = value;
          });
        },
        onNotificationsChanged: (value) {
          setState(() {
            _notificationsEnabled = value;
          });
        },
        onAboutPressed: _showAboutDialog,
        onSupportPressed: _showSupportDialog,
        onChangeServerPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DnsManagerScreen()),
          );
        },
      ),
      body: GestureDetector(
        onPanEnd: (details) {
          const double threshold = 100.0;

          // کشیدن به پایین - صفحه تنظیمات قرمز
          if (details.velocity.pixelsPerSecond.dy > threshold) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RedSettingsScreen(
                  autoStartOnBoot: _autoStartOnBoot,
                  darkTheme: _darkTheme,
                  onAutoStartChanged: (value) {
                    setState(() {
                      _autoStartOnBoot = value;
                    });
                  },
                  onDarkThemeChanged: (value) {
                    setState(() {
                      _darkTheme = value;
                    });
                  },
                  onAboutPressed: _showAboutDialog,
                  onSupportPressed: _showSupportDialog,
                ),
              ),
            );
          }
          // کشیدن به چپ - صفحه Personal
          else if (details.velocity.pixelsPerSecond.dx < -threshold) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalScreen(
                  notificationsEnabled: _notificationsEnabled,
                  currentDns1: _dns1Controller.text.isEmpty
                      ? '10.10.14.1'
                      : _dns1Controller.text,
                  currentDns2: _dns2Controller.text.isEmpty
                      ? 'Unknown'
                      : _dns2Controller.text,
                  currentIpv4: '1.1.1.1',
                  onNotificationsChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  onChangeServerPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DnsManagerScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          }
          // کشیدن به راست - صفحه Config
          else if (details.velocity.pixelsPerSecond.dx > threshold) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfigScreen(
                  onDnsManagerPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DnsManagerScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // DNS Connection Status Card
              _buildConnectionStatusCard(),

              const SizedBox(height: 20),

              // Speed Test Card
              _buildSpeedTestCard(),

              const SizedBox(height: 20),

              // Configuration Card
              _buildConfigurationCard(),
            ],
          ),
        ), // پایان GestureDetector
      ),
    );
  }

  /// کارت وضعیت اتصال DNS
  Widget _buildConnectionStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // آیکون و لپ تاپ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // آیکون power
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _vpnActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.power_settings_new,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              // آیکون لپ تاپ
              Container(
                width: 100,
                height: 80,
                child: Stack(
                  children: [
                    // لپ تاپ
                    Positioned(
                      bottom: 0,
                      right: 10,
                      child: Container(
                        width: 70,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    // کیبورد
                    Positioned(
                      bottom: -5,
                      right: 5,
                      child: Container(
                        width: 80,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // نقطه قرمز
                    Positioned(
                      top: 20,
                      left: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // متن وضعیت
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                _vpnActive ? 'CONNECTED' : 'DISCONNECTED',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // متن وضعیت جلسه
          Text(
            _vpnActive
                ? 'Your session is private'
                : 'Your session is not private',
            style: TextStyle(
              fontSize: 16,
              color: _vpnActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// کارت تست سرعت
  Widget _buildSpeedTestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              // دکمه Run
              GestureDetector(
                onTap: _testGoogleConnectivity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    _isTestingConnectivity ? 'Testing...' : 'Run',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // آیکون سرعت
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTestingConnectivity ? Icons.sync : Icons.speed,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // عنوان
          const Text(
            'SpeedTest',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          // توضیحات
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              children: [
                TextSpan(
                  text: 'Speedtest',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' measures the speed between your '),
                TextSpan(
                  text: 'device',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      ' and a test server, using your device\'s internet connection.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// کارت پیکربندی
  Widget _buildConfigurationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              // دکمه Switch
              GestureDetector(
                onTap: () => _toggleVpn(!_vpnActive),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Switch',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              // آیکون تنظیمات
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.settings, color: Colors.white, size: 20),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
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

          const SizedBox(height: 20),

          // عنوان
          const Text(
            'Configuration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          // توضیحات
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              children: [
                TextSpan(text: 'Customize your '),
                TextSpan(
                  text: 'network preferences',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' and choose the '),
                TextSpan(
                  text: 'configuration',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' that best suits your connection needs.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
