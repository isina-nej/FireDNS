// lib/pages/fire_dns_home_page.dart

import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
import 'dart:async';
import '../path/path.dart';
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
import 'dart:io' show Platform;

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

  DateTime? _lastBackPressTime; // زمان آخرین فشردن دکمه برگشت

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
          _setSelectedDns(selected);
        } else {
          _setSelectedDns(null);
        }
      } catch (e) {
        debugPrint('Error loading selected DNS: $e');
        _setSelectedDns(null);
      }
    } else {
      _setSelectedDns(null);
    }
  }

  void _setSelectedDns(DnsRecord? selected) {
    setState(() {
      if (selected != null) {
        _selectedDnsLabel = selected.label;
        _selectedDnsIp =
            selected.ip1.isNotEmpty ? selected.ip1 : (selected.ip2 ?? '');
        // مهم: به‌روزرسانی DNS controllers با مقادیر جدید
        _dns1Controller.text = selected.ip1;
        _dns2Controller.text = selected.ip2 ?? '';
      } else {
        _selectedDnsLabel = null;
        _selectedDnsIp = null;
      }
    });
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
    if (Platform.isAndroid) {
      VpnStatusService.startListening();
    }

    _vpnStatusSubscription = VpnStatusService.vpnStatusStream.listen((
      isActive,
    ) {
      if (mounted) {
        debugPrint('📡 VPN status changed via stream: $isActive');

        if (_vpnActive != isActive) {
          debugPrint('Status actually changed: $_vpnActive -> $isActive');
          final wasActive = _vpnActive;

          setState(() {
            _vpnActive = isActive;
            _vpnLoading = false;
          });

          if (isActive) {
            _lottieController
                .animateTo(
              0.1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
            )
                .then((_) {
              if (_vpnActive) {
                _lottieController.repeat();
              }
            });
          } else {
            if (_lottieController.isAnimating) {
              _lottieController
                  .animateTo(
                _lottieController.value,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              )
                  .then((_) {
                final remaining = 1.0 - (_lottieController.value % 1.0);
                _lottieController
                    .animateTo(
                      _lottieController.value + remaining,
                      duration:
                          Duration(milliseconds: (remaining * 1500).round()),
                      curve: Curves.easeInOut,
                    )
                    .then((_) => _lottieController.stop());
              });
            }
          }

          if (!_vpnLoading && wasActive != isActive) {
            // handled by action functions
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
    if (Platform.isAndroid) {
      VpnStatusService.stopListening();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        if (_vpnActive) {
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
    if (Platform.isAndroid) {
      try {
        final status = await DnsService.getServiceStatus();
        debugPrint('Initial VPN status check from service: $status');

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
    } else {
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

    try {
      bool actualStatus = false;
      if (Platform.isAndroid) {
        actualStatus = await DnsService.getServiceStatus();
      }
      debugPrint('Actual service status: $actualStatus');

      if (_vpnActive != actualStatus) {
        debugPrint('⚠️ UI state mismatch detected!');
        debugPrint('Correcting UI state: $_vpnActive -> $actualStatus');
        setState(() {
          _vpnActive = actualStatus;
        });

        if (value == actualStatus) {
          debugPrint('Requested state matches actual state, no action needed');
          return;
        }
      }

      setState(() {
        _vpnLoading = true;
      });

      if (actualStatus) {
        await _deactivateVpn();
      } else {
        await _activateVpn();
      }

      bool newStatus = false;
      if (Platform.isAndroid) {
        newStatus = await DnsService.getServiceStatus();
      }
      debugPrint('New service status after toggle: $newStatus');

      setState(() {
        _vpnActive = newStatus;
        _vpnLoading = false;
      });

      await _reportDnsUsage(newStatus);
    } catch (e) {
      debugPrint('❌ Error in _toggleVpn: $e');
      setState(() {
        _vpnLoading = false;
      });

      try {
        bool actualStatus = false;
        if (Platform.isAndroid) {
          actualStatus = await DnsService.getServiceStatus();
        }
        setState(() {
          _vpnActive = actualStatus;
        });
      } catch (_) {
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

      DeviceInfo deviceInfoData;
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        deviceInfoData = DeviceInfo(
          deviceType: 'android',
          brand: deviceInfo.brand,
          model: deviceInfo.model,
          osVersion: deviceInfo.version.release,
        );
      } else if (Platform.isWindows) {
        final deviceInfo = await DeviceInfoPlugin().windowsInfo;
        deviceInfoData = DeviceInfo(
          deviceType: 'windows',
          brand: deviceInfo.computerName,
          model: deviceInfo.computerName,
          osVersion: '${deviceInfo.majorVersion}.${deviceInfo.minorVersion}',
        );
      } else {
        deviceInfoData = DeviceInfo(
          deviceType: 'unknown',
          brand: 'unknown',
          model: 'unknown',
          osVersion: 'unknown',
        );
      }

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
    if (Platform.isAndroid) {
      final dns1 = _dns1Controller.text.trim();
      final dns2 = _dns2Controller.text.trim();
      try {
        debugPrint('Activating VPN with DNS1: $dns1, DNS2: $dns2');
        final result = await DnsService.changeDns(dns1, dns2);

        await Future.delayed(const Duration(milliseconds: 500));
        final actualStatus = await DnsService.getServiceStatus();
        debugPrint(
            'VPN activation result: ${result.success}, actual status: $actualStatus');

        showEnhancedSnackBar(
          context: context,
          message: result.message,
          type: result.success ? SnackBarType.success : SnackBarType.error,
          lastSnackBarTime: _lastSnackBarTime,
          lastSnackBarMessage: _lastSnackBarMessage,
          setLastSnackBarTime: (time) => _lastSnackBarTime = time,
          setLastSnackBarMessage: (msg) => _lastSnackBarMessage = msg,
          isDarkModeActive: () => _themeManager.isDarkModeActive(context),
        );

        setState(() {
          _vpnActive = actualStatus;
          _vpnLoading = false;
        });
      } catch (e) {
        debugPrint('Error activating VPN: $e');
        showEnhancedSnackBar(
          context: context,
          message: 'خطا در فعال‌سازی VPN: $e',
          type: SnackBarType.error,
          lastSnackBarTime: _lastSnackBarTime,
          lastSnackBarMessage: _lastSnackBarMessage,
          setLastSnackBarTime: (time) => _lastSnackBarTime = time,
          setLastSnackBarMessage: (msg) => _lastSnackBarMessage = msg,
          isDarkModeActive: () => _themeManager.isDarkModeActive(context),
        );
        setState(() {
          _vpnActive = false;
          _vpnLoading = false;
        });
      }
    } else {
      showEnhancedSnackBar(
        context: context,
        message: 'این قابلیت بزودی برای ویندوز فعال میشود',
        type: SnackBarType.info,
        lastSnackBarTime: _lastSnackBarTime,
        lastSnackBarMessage: _lastSnackBarMessage,
        setLastSnackBarTime: (time) => _lastSnackBarTime = time,
        setLastSnackBarMessage: (msg) => _lastSnackBarMessage = msg,
        isDarkModeActive: () => _themeManager.isDarkModeActive(context),
      );
      setState(() {
        _vpnLoading = false;
      });
    }
  }

  Future<void> _deactivateVpn() async {
    if (Platform.isAndroid) {
      try {
        debugPrint('Deactivating VPN...');
        final success = await DnsService.stopVpn();

        await Future.delayed(const Duration(milliseconds: 500));
        final actualStatus = await DnsService.getServiceStatus();
        debugPrint(
            'VPN deactivation success: $success, actual status: $actualStatus');

        showEnhancedSnackBar(
          context: context,
          message: success
              ? DnsConstants.errorMessages['vpnDisabled']!
              : DnsConstants.errorMessages['vpnDisableError']!,
          type: success ? SnackBarType.success : SnackBarType.error,
          lastSnackBarTime: _lastSnackBarTime,
          lastSnackBarMessage: _lastSnackBarMessage,
          setLastSnackBarTime: (time) => _lastSnackBarTime = time,
          setLastSnackBarMessage: (msg) => _lastSnackBarMessage = msg,
          isDarkModeActive: () => _themeManager.isDarkModeActive(context),
        );

        setState(() {
          _vpnActive = actualStatus;
          _vpnLoading = false;
        });
      } catch (e) {
        debugPrint('Error deactivating VPN: $e');
        showEnhancedSnackBar(
          context: context,
          message: 'خطا در غیرفعال‌سازی VPN: $e',
          type: SnackBarType.error,
          lastSnackBarTime: _lastSnackBarTime,
          lastSnackBarMessage: _lastSnackBarMessage,
          setLastSnackBarTime: (time) => _lastSnackBarTime = time,
          setLastSnackBarMessage: (msg) => _lastSnackBarMessage = msg,
          isDarkModeActive: () => _themeManager.isDarkModeActive(context),
        );

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
    } else {
      setState(() {
        _vpnActive = false;
        _vpnLoading = false;
      });
    }
  }

  void _handleDnsSelected(DnsRecord result) {
    setState(() {
      _selectedDnsLabel = result.label;
      _selectedDnsIp = result.ip1.isNotEmpty ? result.ip1 : (result.ip2 ?? '');
      _dns1Controller.text = result.ip1;
      _dns2Controller.text = result.ip2 ?? '';
    });
  }

  void _showSnackBar(String message) {
    showEnhancedSnackBar(
      context: context,
      message: message,
      type: SnackBarType.info,
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => _lastSnackBarTime = time,
      setLastSnackBarMessage: (msg) => _lastSnackBarMessage = msg,
      isDarkModeActive: () => _themeManager.isDarkModeActive(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) => WillPopScope(
          onWillPop: () async {
            if (_vpnActive) {
              // اگر VPN فعال است، اجازه اجرا در پس‌زمینه را بده
              return false;
            }

            // منطق double-back برای خروج
            final now = DateTime.now();
            if (_lastBackPressTime == null ||
                now.difference(_lastBackPressTime!) >
                    const Duration(seconds: 2)) {
              _lastBackPressTime = now;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('pressBackAgainToExit')),
                  duration: const Duration(seconds: 2),
                ),
              );
              return false;
            }
            return true;
          },
          child: Scaffold(
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
                  color: isDark
                      ? AppColors.darkIconPrimary
                      : AppColors.textPrimary,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                context.tr('appTitle'),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
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
                    _showSnackBar(context.tr('profileComingSoon'));
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
                          child: ConnectionStatusCard(
                            height: cardHeight,
                            themeManager: _themeManager,
                            vpnActive: _vpnActive,
                            vpnLoading: _vpnLoading,
                            lottieController: _lottieController,
                            onToggleVpn: () => _toggleVpn(!_vpnActive),
                            selectedDnsLabel: _selectedDnsLabel,
                            selectedDnsIp: _selectedDnsIp,
                            dns1Controller: _dns1Controller,
                            dns2Controller: _dns2Controller,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 10,
                          child: SpeedTestCard(
                            height: cardHeight,
                            themeManager: _themeManager,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 10,
                          child: ConfigurationCard(
                            height: cardHeight,
                            themeManager: _themeManager,
                            onDnsSelected: _handleDnsSelected,
                            vpnActive: _vpnActive,
                            deactivateVpn: _deactivateVpn,
                            activateVpn: _activateVpn,
                            loadSelectedDnsLabel: _loadSelectedDnsLabel,
                            showSnackBar: _showSnackBar,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )),
    );
  }
}
