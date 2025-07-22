// import 'package:flutter/material.dart';
// import 'dart:async';
// import '../models/dns_status.dart';
// import '../models/google_connectivity_result.dart';
// import '../services/dns_service.dart';
// import '../services/vpn_status_service.dart';
// import '../services/auto_ping_service.dart';
// import '../constants/dns_constants.dart';
// import 'dns_record_list_screen.dart';
// import 'dns_manager_screen.dart';
// import 'dns_api_demo_screen.dart';

// /// صفحه اصلی برنامه Fire DNS
// class FireDNSHomePage extends StatefulWidget {
//   final String title;

//   const FireDNSHomePage({Key? key, required this.title}) : super(key: key);

//   @override
//   State<FireDNSHomePage> createState() => _FireDNSHomePageState();
// }

// class _FireDNSHomePageState extends State<FireDNSHomePage>
//     with WidgetsBindingObserver, TickerProviderStateMixin {
//   // Controllers
//   late final TextEditingController _dns1Controller;
//   late final TextEditingController _dns2Controller;
//   late final AnimationController _settingsPanelController;
//   late final Animation<double> _settingsPanelAnimation;

//   // State variables
//   bool _vpnActive = false;
//   bool _autoPingEnabled = false;
//   bool _isTestingConnectivity = false;
//   bool _isPinging = false;
//   bool _autoStartOnBoot = false;
//   bool _darkTheme = false;
//   bool _isSettingsPanelVisible = false;
//   bool _isSettingsPanelLocked = false;

//   // Stream subscriptions
//   StreamSubscription<bool>? _vpnStatusSubscription;
//   StreamSubscription<Map<String, int>>? _dataUsageSubscription;
//   StreamSubscription<Map<String, DnsStatus>>? _pingResultSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//     _initializeObserver();
//     _initializeServices();
//     _initializeAnimations();
//     _checkInitialStatus();
//   }

//   @override
//   void dispose() {
//     _disposeControllers();
//     _disposeObserver();
//     _disposeServices();
//     _settingsPanelController.dispose();
//     super.dispose();
//   }

//   void _initializeControllers() {
//     _dns1Controller = TextEditingController(
//       text: DnsConstants.defaultPrimaryDns,
//     );
//     _dns2Controller = TextEditingController(
//       text: DnsConstants.defaultSecondaryDns,
//     );
//   }

//   void _initializeAnimations() {
//     _settingsPanelController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _settingsPanelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _settingsPanelController,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }

//   void _initializeObserver() {
//     WidgetsBinding.instance.addObserver(this);
//   }

//   void _initializeServices() {
//     // شروع listening به وضعیت VPN
//     VpnStatusService.startListening();

//     // اشتراک در stream ها
//     _vpnStatusSubscription = VpnStatusService.vpnStatusStream.listen((
//       isActive,
//     ) {
//       if (mounted) {
//         setState(() {
//           _vpnActive = isActive;
//         });
//       }
//     });

//     _dataUsageSubscription = VpnStatusService.dataUsageStream.listen((usage) {
//       // مصرف داده در UI جدید نیازی نیست
//     });

//     _pingResultSubscription = AutoPingService.pingResultStream.listen((
//       results,
//     ) {
//       if (mounted) {
//         setState(() {
//           // نتایج پینگ در UI جدید نیازی نیست
//           _isPinging = false;
//         });
//       }
//     });
//   }

//   void _disposeControllers() {
//     _dns1Controller.dispose();
//     _dns2Controller.dispose();
//   }

//   void _disposeObserver() {
//     WidgetsBinding.instance.removeObserver(this);
//   }

//   void _disposeServices() {
//     _vpnStatusSubscription?.cancel();
//     _dataUsageSubscription?.cancel();
//     _pingResultSubscription?.cancel();
//     VpnStatusService.stopListening();
//     AutoPingService.stop();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         if (_autoPingEnabled) {
//           _startAutoPing();
//         }
//         break;
//       case AppLifecycleState.paused:
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.detached:
//         AutoPingService.stop();
//         break;
//       default:
//         break;
//     }
//   }

//   Future<void> _checkInitialStatus() async {
//     try {
//       final status = await DnsService.getServiceStatus();
//       if (mounted) {
//         setState(() {
//           _vpnActive = status;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking initial status: $e');
//     }
//   }

//   void _startAutoPing() {
//     AutoPingService.start(
//       dns1: _dns1Controller.text.trim(),
//       dns2: _dns2Controller.text.trim(),
//     );
//   }

//   void _toggleAutoPing() {
//     setState(() {
//       _autoPingEnabled = !_autoPingEnabled;
//       if (_autoPingEnabled) {
//         _startAutoPing();
//       } else {
//         AutoPingService.stop();
//       }
//     });
//   }

//   Future<void> _performManualPing() async {
//     if (_isPinging) return;

//     setState(() {
//       _isPinging = true;
//     });

//     try {
//       await AutoPingService.performManualPing(
//         _dns1Controller.text.trim(),
//         _dns2Controller.text.trim(),
//       );
//     } catch (e) {
//       debugPrint('Error performing manual ping: $e');
//       setState(() {
//         _isPinging = false;
//       });
//     }
//   }

//   Future<void> _toggleVpn(bool value) async {
//     if (value) {
//       await _activateVpn();
//     } else {
//       await _deactivateVpn();
//     }
//   }

//   Future<void> _activateVpn() async {
//     final dns1 = _dns1Controller.text.trim();
//     final dns2 = _dns2Controller.text.trim();

//     try {
//       final success = await DnsService.changeDns(dns1, dns2);
//       if (success) {
//         _showSuccessMessage(DnsConstants.errorMessages['vpnActivated']!);
//       } else {
//         _showErrorMessage(DnsConstants.errorMessages['vpnActivationError']!);
//       }
//     } catch (e) {
//       _showErrorMessage('خطا در فعال‌سازی VPN: $e');
//     }
//   }

//   Future<void> _deactivateVpn() async {
//     try {
//       final success = await DnsService.stopVpn();
//       if (success) {
//         _showSuccessMessage(DnsConstants.errorMessages['vpnDisabled']!);
//       } else {
//         _showErrorMessage(DnsConstants.errorMessages['vpnDisableError']!);
//       }
//     } catch (e) {
//       _showErrorMessage('خطا در غیرفعال‌سازی VPN: $e');
//     }
//   }

//   Future<void> _testGoogleConnectivity() async {
//     if (_isTestingConnectivity) return;

//     setState(() {
//       _isTestingConnectivity = true;
//     });

//     try {
//       final result = await DnsService.testGoogleConnectivity();
//       if (mounted) {
//         setState(() {
//           _isTestingConnectivity = false;
//         });

//         _showConnectivityResult(result);
//       }
//     } catch (e) {
//       setState(() {
//         _isTestingConnectivity = false;
//       });
//       _showErrorMessage('خطا در تست اتصال: $e');
//     }
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.green),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   void _showConnectivityResult(GoogleConnectivityResult result) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           result.overallStatus
//               ? DnsConstants.errorMessages['connectivityTestPassed']!
//               : DnsConstants.errorMessages['connectivityTestFailed']!,
//         ),
//         backgroundColor: result.overallStatus ? Colors.green : Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       body: Stack(
//         children: [
//           // محتوای اصلی
//           GestureDetector(
//             onPanUpdate: (details) {
//               if (details.delta.dy > 0 && !_isSettingsPanelVisible) {
//                 // کشیدن به پایین - نمایش پنل
//                 setState(() {
//                   _isSettingsPanelVisible = true;
//                 });
//                 _settingsPanelController.forward();
//               } else if (details.delta.dy < 0 &&
//                   _isSettingsPanelVisible &&
//                   !_isSettingsPanelLocked) {
//                 // کشیدن به بالا - مخفی کردن پنل
//                 _hideSettingsPanel();
//               }
//             },
//             onPanEnd: (details) {
//               if (_isSettingsPanelVisible &&
//                   details.velocity.pixelsPerSecond.dy < -500) {
//                 // سرعت بالا به بالا - قفل کردن پنل
//                 setState(() {
//                   _isSettingsPanelLocked = true;
//                 });
//               }
//             },
//             child: Column(
//               children: [
//                 // App Bar
//                 Container(
//                   height: 100,
//                   decoration: const BoxDecoration(color: Colors.white),
//                   child: SafeArea(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const SizedBox(width: 40), // برای تعادل
//                           const Text(
//                             'My DNS',
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 20,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.apps, color: Colors.black),
//                             onPressed: () {
//                               _showMenuOptions(context);
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),

//                 // محتوای اصلی
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       children: [
//                         // DNS Connection Status Card
//                         _buildConnectionStatusCard(),

//                         const SizedBox(height: 20),

//                         // Speed Test Card
//                         _buildSpeedTestCard(),

//                         const SizedBox(height: 20),

//                         // Configuration Card
//                         _buildConfigurationCard(),

//                         const SizedBox(height: 100),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // پنل تنظیمات کشویی
//           AnimatedBuilder(
//             animation: _settingsPanelAnimation,
//             builder: (context, child) {
//               return Transform.translate(
//                 offset: Offset(0, -300 * (1 - _settingsPanelAnimation.value)),
//                 child: Opacity(
//                   opacity: _settingsPanelAnimation.value,
//                   child: _isSettingsPanelVisible
//                       ? _buildSettingsPanel()
//                       : const SizedBox.shrink(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   /// مخفی کردن پنل تنظیمات
//   void _hideSettingsPanel() {
//     _settingsPanelController.reverse().then((_) {
//       setState(() {
//         _isSettingsPanelVisible = false;
//         _isSettingsPanelLocked = false;
//       });
//     });
//   }

//   /// نمایش/مخفی کردن پنل تنظیمات
//   void _toggleSettingsPanel() {
//     if (_isSettingsPanelVisible) {
//       _hideSettingsPanel();
//     } else {
//       setState(() {
//         _isSettingsPanelVisible = true;
//       });
//       _settingsPanelController.forward();
//     }
//   }

//   /// نمایش منوی گزینه‌ها
//   void _showMenuOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.list),
//               title: const Text('لیست DNS'),
//               subtitle: const Text('مدیریت ساده رکوردها'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const DnsRecordListScreen(),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.dns),
//               title: const Text('مدیریت کامل DNS'),
//               subtitle: const Text('مدیریت پیشرفته با آمار'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const DnsManagerScreen(),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.code),
//               title: const Text('نمونه API'),
//               subtitle: const Text('مثال‌های استفاده از API'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const DnsApiDemoScreen(),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// کارت وضعیت اتصال DNS
//   Widget _buildConnectionStatusCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(30),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE8E8E8),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         children: [
//           // آیکون و لپ تاپ
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // آیکون power
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: _vpnActive ? Colors.green : Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.power_settings_new,
//                   color: Colors.white,
//                   size: 40,
//                 ),
//               ),
//               // آیکون لپ تاپ
//               Container(
//                 width: 100,
//                 height: 80,
//                 child: Stack(
//                   children: [
//                     // لپ تاپ
//                     Positioned(
//                       bottom: 0,
//                       right: 10,
//                       child: Container(
//                         width: 70,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(5),
//                           border: Border.all(color: Colors.grey.shade300),
//                         ),
//                         child: Container(
//                           margin: const EdgeInsets.all(3),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(3),
//                           ),
//                         ),
//                       ),
//                     ),
//                     // کیبورد
//                     Positioned(
//                       bottom: -5,
//                       right: 5,
//                       child: Container(
//                         width: 80,
//                         height: 8,
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade400,
//                           borderRadius: BorderRadius.circular(3),
//                         ),
//                       ),
//                     ),
//                     // نقطه قرمز
//                     Positioned(
//                       top: 20,
//                       left: 0,
//                       child: Container(
//                         width: 12,
//                         height: 12,
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 30),

//           // متن وضعیت
//           Row(
//             children: [
//               const Icon(Icons.info_outline, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 _vpnActive ? 'CONNECTED' : 'DISCONNECTED',
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 8),

//           // متن وضعیت جلسه
//           Text(
//             _vpnActive
//                 ? 'Your session is private'
//                 : 'Your session is not private',
//             style: TextStyle(
//               fontSize: 16,
//               color: _vpnActive ? Colors.green : Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// کارت تست سرعت
//   Widget _buildSpeedTestCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(25),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // دکمه Run
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 25,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: const Text(
//                   'Run',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//               ),
//               // آیکون سرعت
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: const BoxDecoration(
//                   color: Colors.green,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.speed, color: Colors.white, size: 25),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // عنوان
//           const Text(
//             'SpeedTest',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),

//           const SizedBox(height: 10),

//           // توضیحات
//           RichText(
//             text: const TextSpan(
//               style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
//               children: [
//                 TextSpan(
//                   text: 'Speedtest',
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 TextSpan(text: ' measures the speed between your '),
//                 TextSpan(
//                   text: 'device',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 TextSpan(
//                   text:
//                       ' and a test server, using your device\'s internet connection.',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// کارت پیکربندی
//   Widget _buildConfigurationCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(25),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // دکمه Switch
//               GestureDetector(
//                 onTap: () => _toggleVpn(!_vpnActive),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 25,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: const Text(
//                     'Switch',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                 ),
//               ),
//               // آیکون تنظیمات
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: const BoxDecoration(
//                   color: Colors.green,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     const Icon(Icons.settings, color: Colors.white, size: 20),
//                     Positioned(
//                       right: 8,
//                       top: 8,
//                       child: Container(
//                         width: 8,
//                         height: 8,
//                         decoration: const BoxDecoration(
//                           color: Colors.green,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // عنوان
//           const Text(
//             'Configuration',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),

//           const SizedBox(height: 10),

//           // توضیحات
//           RichText(
//             text: const TextSpan(
//               style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
//               children: [
//                 TextSpan(text: 'Customize your '),
//                 TextSpan(
//                   text: 'network preferences',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 TextSpan(text: ' and choose the '),
//                 TextSpan(
//                   text: 'configuration',
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 TextSpan(text: ' that best suits your connection needs.'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ساخت پنل تنظیمات (کشویی)
//   Widget _buildSettingsPanel() {
//     return GestureDetector(
//       onPanUpdate: (details) {
//         // اگر پنل قفل باشد، فقط با دکمه بسته شود
//         if (_isSettingsPanelLocked) return;

//         // بررسی جهت حرکت
//         if (details.delta.dy > 5) {
//           // حرکت به پایین - بستن پنل
//           _hideSettingsPanel();
//         } else if (details.delta.dy < -10) {
//           // حرکت سریع به بالا - قفل کردن پنل
//           setState(() {
//             _isSettingsPanelLocked = true;
//           });
//         }
//       },
//       child: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF6B6B), // قرمز روشن
//               Color(0xFFFF5252), // قرمز کمی تیره‌تر
//             ],
//           ),
//           borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(30),
//             bottomRight: Radius.circular(30),
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
//             child: Column(
//               children: [
//                 // Handle indicator or header
//                 if (_isSettingsPanelLocked)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Settings',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close, color: Colors.white),
//                         onPressed: _hideSettingsPanel,
//                       ),
//                     ],
//                   )
//                 else
//                   Container(
//                     width: 40,
//                     height: 4,
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),

//                 // Auto start on boot
//                 _buildSettingsItem(
//                   title: 'Auto start on boot',
//                   value: _autoStartOnBoot,
//                   onChanged: (value) {
//                     setState(() {
//                       _autoStartOnBoot = value;
//                     });
//                   },
//                   icon: Icons.shield_outlined,
//                 ),

//                 const SizedBox(height: 20),

//                 // Dark theme
//                 _buildSettingsItem(
//                   title: 'Dark theme',
//                   value: _darkTheme,
//                   onChanged: (value) {
//                     setState(() {
//                       _darkTheme = value;
//                     });
//                   },
//                   icon: Icons.nightlight_round,
//                 ),

//                 const SizedBox(height: 20),

//                 // About My DNS
//                 _buildSettingsButton(
//                   title: 'About My DNS',
//                   icon: Icons.info_outline,
//                   onTap: () {
//                     _showAboutDialog();
//                   },
//                 ),

//                 const SizedBox(height: 30),

//                 // Support this app button
//                 GestureDetector(
//                   onTap: () {
//                     // اقدام پشتیبانی از برنامه
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Thank you for your support!'),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.favorite, color: Colors.red, size: 20),
//                         const SizedBox(width: 10),
//                         const Text(
//                           'Support this app',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Icon(
//                           Icons.shield,
//                           color: Colors.grey.shade600,
//                           size: 20,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // راهنمای استفاده
//                 if (!_isSettingsPanelLocked)
//                   const Padding(
//                     padding: EdgeInsets.only(top: 20),
//                     child: Text(
//                       'Swipe down: Close • Swipe up: Lock',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.white70, fontSize: 12),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// ساخت آیتم تنظیمات با سوییچ
//   Widget _buildSettingsItem({
//     required String title,
//     required bool value,
//     required Function(bool) onChanged,
//     required IconData icon,
//   }) {
//     return Row(
//       children: [
//         // سوییچ
//         Transform.scale(
//           scale: 1.2,
//           child: Switch(
//             value: value,
//             onChanged: onChanged,
//             activeColor: Colors.white,
//             activeTrackColor: Colors.green,
//             inactiveThumbColor: Colors.white,
//             inactiveTrackColor: Colors.white.withOpacity(0.3),
//           ),
//         ),

//         const SizedBox(width: 20),

//         // متن
//         Expanded(
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.white,
//             ),
//           ),
//         ),

//         // آیکون
//         Icon(icon, color: Colors.white, size: 24),
//       ],
//     );
//   }

//   /// ساخت دکمه تنظیمات
//   Widget _buildSettingsButton({
//     required String title,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Row(
//         children: [
//           // فضای خالی برای تراز کردن با سوییچ‌ها
//           const SizedBox(width: 60),

//           // متن
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.white,
//               ),
//             ),
//           ),

//           // آیکون
//           Icon(icon, color: Colors.white, size: 24),
//         ],
//       ),
//     );
//   }

//   /// نمایش دیالوگ درباره برنامه
//   void _showAboutDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('About My DNS'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('My DNS - Advanced DNS Manager'),
//             SizedBox(height: 10),
//             Text('Version: 1.0.0'),
//             SizedBox(height: 10),
//             Text('A powerful DNS management app with API integration.'),
//             SizedBox(height: 10),
//             Text('Features:'),
//             Text('• DNS record management'),
//             Text('• Speed testing'),
//             Text('• Connection monitoring'),
//             Text('• API integration'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }
