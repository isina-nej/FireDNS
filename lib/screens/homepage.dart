// lib/pages/fire_dns_home_page.dart

// import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firedns/blocs/dns/dns_bloc.dart';
import 'package:firedns/blocs/dns/dns_state.dart';
import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FireDNSHomePage extends StatefulWidget {
  final String title;

  const FireDNSHomePage({super.key, required this.title});

  @override
  State<FireDNSHomePage> createState() => _FireDNSHomePageState();
}

class _FireDNSHomePageState extends State<FireDNSHomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final ThemeController _themeController;
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
  final bool _autoPingEnabled = false;

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
    _themeController = Get.find<ThemeController>();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
      upperBound: 1,
      lowerBound: 0,
    );
    _initializeControllers();
    _initializeObserver();
    _initializeServices();
    _themeController.loadThemeMode();
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

    // Initialize VPN status subscription
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
            // Only set loading to false if we're not in a loading state that should be managed by _toggleVpn
            if (!_vpnLoading) {
              _vpnLoading = false;
            }
          });

          debugPrint(
              '📡 Stream listener - Updated state: vpnActive=$isActive, vpnLoading=${_vpnLoading ? _vpnLoading : false}');

          // Lottie animation optimization
          if (isActive && !wasActive) {
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
          } else if (!isActive && wasActive) {
            // Stop animation more efficiently
            _lottieController.stop();
            _lottieController.reset();
          }
        } else {
          debugPrint('Status unchanged, just updating loading state');
          // Only update loading state if we're not currently in a toggle operation
          if (_vpnLoading && mounted) {
            setState(() {
              _vpnLoading = false;
            });
            debugPrint(
                '📡 Stream listener - Set vpnLoading=false due to unchanged status');
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
            _vpnLoading = false;
            _vpnActive = status;
          });

          VpnStatusService.notifyVpnStatus(status);
        }
      } catch (e) {
        debugPrint('Error checking initial status: $e');
        setState(() {
          _vpnLoading = false;
          _vpnActive = false;
        });
      }
    } else {
      setState(() {
        _vpnLoading = false;
        _vpnActive = false;
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
        _vpnLoading = false;
        _vpnActive = newStatus;
      });

      debugPrint(
          '🔄 _toggleVpn - Final state: vpnActive=$newStatus, vpnLoading=false');

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
      final dnsUsageService = DnsUsageApiService();

      final connectivity = await Connectivity().checkConnectivity();
      String? ipAddress;
      try {
        final response = await http.get(Uri.parse('https://api.ipify.org'));
        ipAddress = response.statusCode == 200 ? response.body : null;
      } catch (_) {}

      // تشخیص نوع اتصال و اپراتور واقعی
      String connectionType = 'WIFI';
      String? carrierName;
      String? mobileNetworkType;

      if (connectivity.contains(ConnectivityResult.mobile)) {
        // استفاده از اطلاعات پیش‌فرض برای اتصال موبایل
        connectionType = 'MOBILE';
        carrierName = 'Unknown';
        mobileNetworkType = 'Unknown';
      }

      final networkInfoData = NetworkInfo(
        connectionType: connectionType,
        carrierName: carrierName,
        ipAddress: ipAddress,
        mobileNetworkType: mobileNetworkType,
      );

      final request = DnsUsageRequest(
        dns: DnsInfo(
          label: _selectedDnsLabel ?? 'Google DNS',
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
      debugPrint('Network Info: ${networkInfoData.toJson()}');
      debugPrint('DNS Info: ${request.dns.toJson()}');
      debugPrint('Connection Type: ${request.connectionType}');
      debugPrint('Timestamp: ${request.timestamp}');

      // ارسال کل جیسون اولیه به سرور
      final response = await dnsUsageService.recordDnsUsage(
        body: request.toJson(),
      );
      debugPrint('=== پاسخ کامل سرور ===');
      debugPrint('Response Status: ${response.status}');
      debugPrint('Response Message: ${response.message}');
      debugPrint('Response Error Code: ${response.errorCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('Response toString: ${response.toString()}');
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
          isDarkModeActive: () => _themeController.isDarkModeActive(context),
        );

        setState(() {
          _vpnLoading = false;
          _vpnActive = actualStatus;
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
          isDarkModeActive: () => _themeController.isDarkModeActive(context),
        );
        setState(() {
          _vpnLoading = false;
          _vpnActive = false;
        });

        // ارسال گزارش خطا در فعال‌سازی DNS
        await _reportDnsUsage(false);
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
        isDarkModeActive: () => _themeController.isDarkModeActive(context),
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
          isDarkModeActive: () => _themeController.isDarkModeActive(context),
        );

        setState(() {
          _vpnActive = actualStatus;
          _vpnLoading = false;
        });

        // ارسال گزارش تغییر وضعیت DNS به سرور
        await _reportDnsUsage(actualStatus);
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
          isDarkModeActive: () => _themeController.isDarkModeActive(context),
        );

        try {
          final actualStatus = await DnsService.getServiceStatus();
          setState(() {
            _vpnLoading = false;
            _vpnActive = actualStatus;
          });

          // ارسال گزارش تغییر وضعیت DNS به سرور
          await _reportDnsUsage(actualStatus);
        } catch (_) {
          setState(() {
            _vpnLoading = false;
            _vpnActive = false;
          });

          // ارسال گزارش خطا به سرور
          await _reportDnsUsage(false);
        }
      }
    } else {
      setState(() {
        _vpnLoading = false;
        _vpnActive = false;
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
      isDarkModeActive: () => _themeController.isDarkModeActive(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DnsBloc, DnsState>(
      builder: (context, dnsState) {
        return Obx(() {
          final isDark = _themeController.isDarkModeActive(context);
          return AnimatedTheme(
            data: isDark
                ? _themeController.darkTheme
                : _themeController.lightTheme,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: PopScope(
              canPop: false, // Prevent automatic pop on homepage
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
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
                  } else {
                    // خروج از برنامه
                    SystemNavigator.pop();
                  }
                }
              },
              child: Scaffold(
                key: _scaffoldKey,
                drawer: const CustomDrawer(),
                backgroundColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.backgroundLight,
                appBar: AppBar(
                  backgroundColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.backgroundLight,
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
                          size: MediaQuery.of(context).size.width * 0.05,
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
                      final minCardHeight =
                          MediaQuery.of(context).size.height * 0.2;
                      const totalSpacing = 24.0;
                      final availableHeight =
                          constraints.maxHeight - totalSpacing;
                      double cardHeight = availableHeight / 3;
                      if (cardHeight < minCardHeight) {
                        cardHeight = minCardHeight;
                      }
                      const cardPadding = EdgeInsets.all(12);
                      return Padding(
                        padding: cardPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              flex: 12,
                              child: (() {
                                AppLogger.debug(
                                    '🏠 HomePage build - vpnActive: $_vpnActive, vpnLoading: $_vpnLoading');
                                return ConnectionStatusCard(
                                  height: cardHeight,
                                  themeController: _themeController,
                                  vpnActive: _vpnActive,
                                  vpnLoading: _vpnLoading,
                                  lottieController: _lottieController,
                                  onToggleVpn: () => _toggleVpn(!_vpnActive),
                                  selectedDnsLabel: _selectedDnsLabel,
                                  selectedDnsIp: _selectedDnsIp,
                                  dns1Controller: _dns1Controller,
                                  dns2Controller: _dns2Controller,
                                );
                              })(),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.01),
                            Expanded(
                              flex: 10,
                              child: SpeedTestCard(
                                height: cardHeight,
                                themeController: _themeController,
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.01),
                            Expanded(
                              flex: 10,
                              child: ConfigurationCard(
                                height: cardHeight,
                                themeController: _themeController,
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
              ),
            ),
          );
        });
      },
    );
  }
}
