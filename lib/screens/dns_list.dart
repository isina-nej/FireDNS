// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:flutter/gestures.dart';
// import 'dart:convert';
// import '../path/path.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../utils/dns_ping_base.dart';
// import 'package:provider/provider.dart';
// import '../styles/theme_manager.dart';
// import '../styles/app_colors.dart';
// import '../widgets/animated_overflow_label.dart';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;

// class DnsListPage extends StatefulWidget {
//   const DnsListPage({Key? key}) : super(key: key);

//   @override
//   State<DnsListPage> createState() => _DnsListPageState();
// }

// class _DnsListPageState extends State<DnsListPage> {
//   Set<String> _userDnsIds = {};

//   Future<void> _loadUserDnsIds() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userDnsJson = prefs.getString('user_dns_list');
//     final ids = <String>{};
//     if (userDnsJson != null) {
//       try {
//         final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
//         for (var e in userList) {
//           ids.add(e['id']);
//         }
//       } catch (_) {}
//     }
//     setState(() {
//       _userDnsIds = ids;
//     });
//   }

//   bool _isUserDns(DnsRecord record) => _userDnsIds.contains(record.id);
//   Widget _buildDnsCard(BuildContext context, DnsRecord record, int index) {
//     final themeManager = Provider.of<ThemeManager>(context);
//     final isDark = themeManager.isDarkModeActive(context);
//     final isSelected = _selectedDnsId == record.id;
//     var ping1 = _pingCache['${record.id}_1'] ?? _pingCache[record.id] ?? -1;
//     var ping2 = _pingCache['${record.id}_2'] ?? -1;
    
//     // تعیین کدام IP باید اول نمایش داده شود بر اساس پینگ
//     String displayIp1 = record.ip1;
//     String displayIp2 = record.ip2;
//     int displayPing1 = ping1;
//     int displayPing2 = ping2;
    
//     // اگر IP دوم پینگ کمتری دارد یا فقط IP دوم پینگ دارد، جابجا کن
//     if ((ping1 > 0 && ping2 > 0 && ping2 < ping1) || (ping1 <= 0 && ping2 > 0)) {
//       displayIp1 = record.ip2;
//       displayIp2 = record.ip1;
//       displayPing1 = ping2;
//       displayPing2 = ping1;
//     }
    
//     final ping = displayPing1;

//     Future<void> _rePingBoth() async {
//       setState(() {
//         _pingCache['${record.id}_1'] = -2; // انتظار (لودینگ)
//         _pingCache['${record.id}_2'] = -2;
//       });
//       final ping1 = await DnsPingBase.ping(record.ip1);
//       final ping2 = await DnsPingBase.ping(record.ip2);
//       setState(() {
//         _pingCache['${record.id}_1'] = (ping1 == null || ping1 < 0)
//             ? -1
//             : ping1;
//         _pingCache['${record.id}_2'] = (ping2 == null || ping2 < 0)
//             ? -1
//             : ping2;
//         _sortDnsRecords();
//       });
//     }

//     Color pingColor;
//     if (ping < 0) {
//       pingColor = Colors.grey.shade400;
//     } else if (ping < 50) {
//       pingColor = AppColors.pingExcellent;
//     } else if (ping < 120) {
//       pingColor = AppColors.pingGood;
//     } else if (ping < 250) {
//       pingColor = AppColors.pingMedium;
//     } else if (ping < 500) {
//       pingColor = AppColors.pingPoor;
//     } else {
//       pingColor = AppColors.pingBad;
//     }
//     Color pingColor2;
//     if (displayPing2 < 0) {
//       pingColor2 = Colors.grey.shade400;
//     } else if (displayPing2 < 50) {
//       pingColor2 = AppColors.pingExcellent;
//     } else if (displayPing2 < 120) {
//       pingColor2 = AppColors.pingGood;
//     } else if (displayPing2 < 250) {
//       pingColor2 = AppColors.pingMedium;
//     } else if (displayPing2 < 500) {
//       pingColor2 = AppColors.pingPoor;
//     } else {
//       pingColor2 = AppColors.pingBad;
//     }
//     final isUserDns = _isUserDns(record);
//     return ClipRect(
//       child: SizedBox(
//         height: 140,
//         child: Card(
//           elevation: isSelected ? 4 : 1,
//           color: isDark
//               ? (isSelected
//                     ? AppColors.darkCardBackground.withOpacity(0.8)
//                     : AppColors.darkCardBackground)
//               : (isSelected ? AppColors.selectedLight : Colors.white),
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(16),
//             onTap: _isLoading ? null : () => _connectToDns(record),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               child: Row(
//                 mainAxisSize: MainAxisSize.max,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryBlue.withOpacity(0.08),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                       '${index + 1}',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : const Color(0xFF5A9CFF),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       physics: const ClampingScrollPhysics(),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: LayoutBuilder(
//                                   builder: (context, constraints) {
//                                     final text = record.label;
//                                     final textStyle = TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 16,
//                                       color: isDark
//                                           ? AppColors.darkTextPrimary
//                                           : const Color(0xFF222B45),
//                                     );
//                                     final textPainter = TextPainter(
//                                       text: TextSpan(
//                                         text: text,
//                                         style: textStyle,
//                                       ),
//                                       maxLines: 1,
//                                       textDirection: TextDirection.ltr,
//                                     )..layout(maxWidth: constraints.maxWidth);
//                                     final isOverflow =
//                                         textPainter.width >
//                                         constraints.maxWidth;
//                                     if (isOverflow) {
//                                       return AnimatedOverflowLabel(
//                                         label: text,
//                                         width: constraints.maxWidth,
//                                         style: textStyle,
//                                       );
//                                     } else {
//                                       return Text(text, style: textStyle);
//                                     }
//                                   },
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: Icon(
//                                   _likedDnsIds.contains(record.id)
//                                       ? Icons.favorite
//                                       : Icons.favorite_border,
//                                   color: _likedDnsIds.contains(record.id)
//                                       ? Colors.red
//                                       : Colors.grey.shade400,
//                                 ),
//                                 tooltip: _likedDnsIds.contains(record.id)
//                                     ? context.tr('removeFromFavorites')
//                                     : context.tr('addToFavorites'),
//                                 onPressed: () => _toggleLikeDns(record.id),
//                               ),
//                               if (isUserDns) ...[
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.edit,
//                                     color: Colors.blue,
//                                   ),
//                                   tooltip: context.tr('edit'),
//                                   onPressed: () => _editUserDns(record),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.delete,
//                                     color: Colors.red,
//                                   ),
//                                   tooltip: context.tr('delete'),
//                                   onPressed: () => _deleteUserDns(record),
//                                 ),
//                               ],
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.dns,
//                                 size: 18,
//                                 color: isDark
//                                     ? AppColors.darkIconPrimary
//                                     : const Color(0xFF5A9CFF),
//                               ),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: LayoutBuilder(
//                                   builder: (context, constraints) {
//                                     final text = displayIp1;
//                                     final textStyle = const TextStyle(
//                                       fontSize: 14,
//                                       color: Color(0xFF607D8B),
//                                     );
//                                     final textPainter = TextPainter(
//                                       text: TextSpan(
//                                         text: text,
//                                         style: textStyle,
//                                       ),
//                                       maxLines: 1,
//                                       textDirection: TextDirection.ltr,
//                                     )..layout(maxWidth: constraints.maxWidth);
//                                     final isOverflow =
//                                         textPainter.width >
//                                         constraints.maxWidth;
//                                     if (isOverflow) {
//                                       return AnimatedOverflowLabel(
//                                         label: text,
//                                         width: constraints.maxWidth,
//                                         style: textStyle,
//                                       );
//                                     } else {
//                                       return Text(text, style: textStyle);
//                                     }
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Listener(
//                                   behavior: HitTestBehavior.opaque,
//                                   onPointerDown: (event) {
//                                     if (Theme.of(context).platform ==
//                                         TargetPlatform.windows) {
//                                       if (event.kind ==
//                                           PointerDeviceKind.mouse) {
//                                         _rePingBoth();
//                                       }
//                                     }
//                                   },
//                                   child: GestureDetector(
//                                     onTap: _rePingBoth,
//                                     behavior: HitTestBehavior.opaque,
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(
//                                           Icons.speed,
//                                           size: 18,
//                                           color: pingColor,
//                                         ),
//                                         const SizedBox(width: 2),
//                                         ping == -2
//                                             ? const SizedBox(
//                                                 width: 18,
//                                                 height: 18,
//                                                 child:
//                                                     CircularProgressIndicator(
//                                                       strokeWidth: 2,
//                                                     ),
//                                               )
//                                             : (ping == -1 ||
//                                                   ping < 0 ||
//                                                   ping >= 1000)
//                                             ? Text(
//                                                 '---',
//                                                 style: TextStyle(
//                                                   color: pingColor,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13,
//                                                   decoration:
//                                                       TextDecoration.underline,
//                                                 ),
//                                               )
//                                             : Text(
//                                                 '$ping ms',
//                                                 style: TextStyle(
//                                                   color: pingColor,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13,
//                                                   decoration:
//                                                       TextDecoration.underline,
//                                                 ),
//                                               ),
//                                         if (ping > 0 && ping < 80)
//                                           Container(
//                                             margin: const EdgeInsets.only(
//                                               left: 2,
//                                             ),
//                                             width: 22,
//                                             height: 22,
//                                             child: Lottie.asset(
//                                               'assets/icone/Fire.json',
//                                               repeat: true,
//                                               animate: true,
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(height: 2),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.dns_outlined,
//                                 size: 18,
//                                 color: isDark
//                                     ? AppColors.darkIconSecondary
//                                     : const Color(0xFFB0BEC5),
//                               ),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: LayoutBuilder(
//                                   builder: (context, constraints) {
//                                     final text = displayIp2;
//                                     final textStyle = const TextStyle(
//                                       fontSize: 14,
//                                       color: Color(0xFF90A4AE),
//                                     );
//                                     final textPainter = TextPainter(
//                                       text: TextSpan(
//                                         text: text,
//                                         style: textStyle,
//                                       ),
//                                       maxLines: 1,
//                                       textDirection: TextDirection.ltr,
//                                     )..layout(maxWidth: constraints.maxWidth);
//                                     final isOverflow =
//                                         textPainter.width >
//                                         constraints.maxWidth;
//                                     if (isOverflow) {
//                                       return AnimatedOverflowLabel(
//                                         label: text,
//                                         width: constraints.maxWidth,
//                                         style: textStyle,
//                                       );
//                                     } else {
//                                       return Text(text, style: textStyle);
//                                     }
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Listener(
//                                   behavior: HitTestBehavior.opaque,
//                                   onPointerDown: (event) {
//                                     if (Theme.of(context).platform ==
//                                         TargetPlatform.windows) {
//                                       if (event.kind ==
//                                           PointerDeviceKind.mouse) {
//                                         _rePingBoth();
//                                       }
//                                     }
//                                   },
//                                   child: GestureDetector(
//                                     onTap: _rePingBoth,
//                                     behavior: HitTestBehavior.opaque,
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(
//                                           Icons.speed,
//                                           size: 18,
//                                           color: pingColor2,
//                                         ),
//                                         const SizedBox(width: 2),
//                                         displayPing2 == -2
//                                             ? const SizedBox(
//                                                 width: 18,
//                                                 height: 18,
//                                                 child:
//                                                     CircularProgressIndicator(
//                                                       strokeWidth: 2,
//                                                     ),
//                                               )
//                                             : (displayPing2 == -1 ||
//                                                   displayPing2 < 0 ||
//                                                   displayPing2 >= 1000)
//                                             ? Text(
//                                                 '---',
//                                                 style: TextStyle(
//                                                   color: pingColor2,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13,
//                                                   decoration:
//                                                       TextDecoration.underline,
//                                                 ),
//                                               )
//                                           : Text(
//                                               '$displayPing2 ms',
//                                               style: TextStyle(
//                                                   color: pingColor2,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13,
//                                                   decoration:
//                                                       TextDecoration.underline,
//                                                 ),
//                                               ),
//                                       if (displayPing2 > 0 && displayPing2 < 80)
//                                         Container(
//                                             margin: const EdgeInsets.only(
//                                               left: 2,
//                                             ),
//                                             width: 22,
//                                             height: 22,
//                                             child: Lottie.asset(
//                                               'assets/icone/Fire.json',
//                                               repeat: true,
//                                               animate: true,
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   if (isSelected && _isLoading)
//                     const Padding(
//                       padding: EdgeInsets.only(left: 8, top: 8),
//                       child: SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Set<String> _likedDnsIds = {};
//   Future<void> _loadLikedDns() async {
//     final prefs = await SharedPreferences.getInstance();
//     final liked = prefs.getStringList('liked_dns_ids') ?? [];
//     setState(() {
//       _likedDnsIds = liked.toSet();
//     });
//   }

//   Future<void> _toggleLikeDns(String dnsId) async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       if (_likedDnsIds.contains(dnsId)) {
//         _likedDnsIds.remove(dnsId);
//       } else {
//         _likedDnsIds.add(dnsId);
//       }
//     });
//     await prefs.setStringList('liked_dns_ids', _likedDnsIds.toList());
//     _sortDnsRecords();
//   }

//   final DnsApiService _dnsApiService = DnsApiService();
//   List<DnsRecord> _dnsRecords = [];
//   String? _selectedDnsId;
//   Map<String, int> _pingCache = {};
//   bool _isLoading = false;
//   // String? _message; // Removed unused field
//   bool _loadingList = true;
//   String? _loadError;

//   // Sorting
//   String _sortType = 'ping'; // 'default', 'ping', 'name'

//   void _sortDnsRecords() {
//     setState(() {
//       _dnsRecords.sort((a, b) {
//         final aLiked = _likedDnsIds.contains(a.id);
//         final bLiked = _likedDnsIds.contains(b.id);
//         if (aLiked && !bLiked) return -1;
//         if (!aLiked && bLiked) return 1;
//         if (_sortType == 'ping') {
//           int pingA1 = _pingCache['${a.id}_1'] ?? _pingCache[a.id] ?? 999999;
//           int pingA2 = _pingCache['${a.id}_2'] ?? 999999;
//           int pingB1 = _pingCache['${b.id}_1'] ?? _pingCache[b.id] ?? 999999;
//           int pingB2 = _pingCache['${b.id}_2'] ?? 999999;

//           int sortA = pingA1 >= 0
//               ? pingA1
//               : pingA2 >= 0
//               ? pingA2
//               : 999999;
//           int sortB = pingB1 >= 0
//               ? pingB1
//               : pingB2 >= 0
//               ? pingB2
//               : 999999;
//           return sortA.compareTo(sortB);
//         } else if (_sortType == 'name') {
//           return a.label.compareTo(b.label);
//         } else {
//           return 0;
//         }
//       });
//     });
//   }

//   DateTime? _lastAutoPing;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() async {
//       await DnsService.stopVpn();
//       await _loadLikedDns();
//       await _loadCachedDnsList();
//       await _loadUserDnsIds();
//       await fetchDnsListWithTimer();
//       _pingCache = await DnsPingBase.loadPingCache();
//       if (_sortType == 'ping') {
//         _sortDnsRecords();
//       }
//       // زمان آخرین پینگ خودکار را از SharedPreferences بخوان
//       final prefs = await SharedPreferences.getInstance();
//       final lastPingStr = prefs.getString('last_auto_ping');
//       if (lastPingStr != null) {
//         try {
//           _lastAutoPing = DateTime.parse(lastPingStr);
//         } catch (_) {}
//       }
//       final now = DateTime.now();
//       // اگر اولین ورود یا بیش از ۱ ساعت گذشته بود، پینگ خودکار انجام بده
//       if (_lastAutoPing == null ||
//           now.difference(_lastAutoPing!).inHours >= 1) {
//         await _testAllDns(auto: true);
//         _lastAutoPing = now;
//         await prefs.setString('last_auto_ping', now.toIso8601String());
//       }
//     });
//   }

//   // --- Place fetchDnsListWithTimer after initState and after class variables ---
//   /// دریافت لیست از API فقط هر ۶ ساعت یکبار (مگر اینکه کش خالی باشد یا force=true)
//   Future<void> fetchDnsListWithTimer({bool force = false}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final lastFetchStr = prefs.getString('last_dns_api_fetch');
//     DateTime? lastFetch;
//     if (lastFetchStr != null) {
//       try {
//         lastFetch = DateTime.parse(lastFetchStr);
//       } catch (_) {}
//     }
//     final now = DateTime.now();
//     final cachedJson = prefs.getString('cached_dns_list');
//     bool shouldFetch = force;
//     if (cachedJson == null) {
//       shouldFetch = true;
//     } else if (lastFetch == null || now.difference(lastFetch).inHours >= 6) {
//       shouldFetch = true;
//     }
//     if (shouldFetch) {
//       // دریافت لیست جدید از API
//       final response = await _dnsApiService.getAllDnsRecords();
//       List<DnsRecord> apiRecords = [];
//       if (response.status && response.data != null) {
//         apiRecords = response.data!;
//       }
//       // دریافت DNSهای دستی
//       final userDnsJson = prefs.getString('user_dns_list');
//       List<DnsRecord> userDnsRecords = [];
//       if (userDnsJson != null) {
//         try {
//           final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
//           userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
//         } catch (_) {}
//       }
//       // لیست جدید = API + DNSهای دستی
//       List<DnsRecord> newRecords = [...apiRecords, ...userDnsRecords];
//       // حذف موارد تکراری بر اساس ip1+ip2
//       final seen = <String>{};
//       newRecords = newRecords.where((r) {
//         final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
//         if (seen.contains(key)) return false;
//         seen.add(key);
//         return true;
//       }).toList();
//       setState(() {
//         _dnsRecords = newRecords;
//         _loadingList = false;
//         _sortDnsRecords();
//       });
//       // بروزرسانی کش و زمان آخرین دریافت
//       prefs.setString(
//         'cached_dns_list',
//         jsonEncode(newRecords.map((e) => e.toJson()).toList()),
//       );
//       prefs.setStringList(
//         'cached_dns_order',
//         newRecords.map((e) => e.id).toList(),
//       );
//       prefs.setString('last_dns_api_fetch', now.toIso8601String());
//     } else {
//       // فقط کش و DNSهای دستی را نمایش بده
//       List<DnsRecord> cachedRecords = [];
//       if (cachedJson != null) {
//         try {
//           final List<dynamic> jsonList = List.from(jsonDecode(cachedJson));
//           cachedRecords = jsonList.map((e) => DnsRecord.fromJson(e)).toList();
//         } catch (_) {}
//       }
//       final userDnsJson = prefs.getString('user_dns_list');
//       List<DnsRecord> userDnsRecords = [];
//       if (userDnsJson != null) {
//         try {
//           final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
//           userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
//         } catch (_) {}
//       }
//       List<DnsRecord> allRecords = [...cachedRecords, ...userDnsRecords];
//       // حذف موارد تکراری بر اساس ip1+ip2
//       final seen = <String>{};
//       allRecords = allRecords.where((r) {
//         final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
//         if (seen.contains(key)) return false;
//         seen.add(key);
//         return true;
//       }).toList();
//       setState(() {
//         _dnsRecords = allRecords;
//         _loadingList = false;
//         _sortDnsRecords();
//       });
//     }
//   }

//   Future<void> _loadCachedDnsList() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cached = prefs.getString('cached_dns_list');
//     final cachedOrder = await DnsPingBase.loadDnsOrder();
//     final cachedSelected = prefs.getString('cached_selected_dns');
//     final userDnsJson = prefs.getString('user_dns_list');
//     List<DnsRecord> userDnsRecords = [];
//     if (userDnsJson != null) {
//       try {
//         final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
//         userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
//       } catch (_) {}
//     }
//     if (cached != null) {
//       try {
//         final List<dynamic> jsonList = List.from(jsonDecode(cached));
//         List<DnsRecord> records = jsonList
//             .map((e) => DnsRecord.fromJson(e))
//             .toList();
//         // Add user DNS records (persistent)
//         records.addAll(userDnsRecords);
//         // Remove duplicates by ip1+ip2
//         final seen = <String>{};
//         records = records.where((r) {
//           final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
//           if (seen.contains(key)) return false;
//           seen.add(key);
//           return true;
//         }).toList();
//         // Restore order if available
//         if (cachedOrder.isNotEmpty) {
//           records.sort((a, b) {
//             int ia = cachedOrder.indexOf(a.id);
//             int ib = cachedOrder.indexOf(b.id);
//             if (ia == -1) ia = 9999;
//             if (ib == -1) ib = 9999;
//             return ia.compareTo(ib);
//           });
//         }
//         final pingCache = await DnsPingBase.loadPingCache();
//         setState(() {
//           _dnsRecords = records;
//           if (cachedSelected != null) _selectedDnsId = cachedSelected;
//           _pingCache = pingCache;
//         });
//       } catch (_) {}
//     } else if (userDnsRecords.isNotEmpty) {
//       // If no cached list, but user DNS exists
//       final pingCache = await DnsPingBase.loadPingCache();
//       setState(() {
//         _dnsRecords = userDnsRecords;
//         if (cachedSelected != null) _selectedDnsId = cachedSelected;
//         _pingCache = pingCache;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _dnsApiService.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchDnsList() async {
//     setState(() {
//       _loadingList = true;
//       _loadError = null;
//       _pingCache.clear();
//     });
//     final response = await _dnsApiService.getAllDnsRecords();
//     List<DnsRecord> records = [];
//     if (response.status && response.data != null) {
//       // دریافت لیست از API
//       records = response.data!;
//     }
//     // دریافت DNSهای کاربر از کش
//     final prefs = await SharedPreferences.getInstance();
//     final userDnsJson = prefs.getString('user_dns_list');
//     List<DnsRecord> userDnsRecords = [];
//     if (userDnsJson != null) {
//       try {
//         final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
//         userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
//       } catch (_) {}
//     }
//     // اضافه کردن DNSهای کاربر به لیست اصلی
//     records.addAll(userDnsRecords);
//     // حذف موارد تکراری بر اساس ip1+ip2
//     final seen = <String>{};
//     records = records.where((r) {
//       final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
//       if (seen.contains(key)) return false;
//       seen.add(key);
//       return true;
//     }).toList();
//     if (records.isNotEmpty) {
//       setState(() {
//         _dnsRecords = records;
//         _loadingList = false;
//         _sortDnsRecords();
//       });
//       // ذخیره لیست ترکیبی در کش
//       prefs.setString(
//         'cached_dns_list',
//         jsonEncode(records.map((e) => e.toJson()).toList()),
//       );
//       prefs.setStringList(
//         'cached_dns_order',
//         records.map((e) => e.id).toList(),
//       );
//       if (_selectedDnsId != null) {
//         prefs.setString('cached_selected_dns', _selectedDnsId!);
//       }
//       prefs.setString('cached_ping_cache', jsonEncode(_pingCache));
//     } else {
//       setState(() {
//         _loadError = response.message;
//         _loadingList = false;
//       });
//     }
//   }

//   bool _testDialogOpen = false;

//   Future<void> _connectToDns(DnsRecord record) async {
//     // اگر تست پینگ در حال اجراست، اجازه انتخاب نده و اسنک‌بار نمایش بده
//     if (_testDialogOpen) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(context.tr('waitForPingTest')),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//       return;
//     }
//     // توقف تست پینگ هنگام انتخاب DNS فقط روی اندروید و iOS
//     // جلوگیری از کرش روی ویندوز
//     if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
//       DnsPingBase.cancelPingTest();
//     }
//     setState(() {
//       _selectedDnsId = record.id;
//     });
//     // Persist selected DNS
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setString('cached_selected_dns', record.id);

//     // بررسی پینگ‌ها و انتخاب بهترین IP
//     final ping1 = _pingCache['${record.id}_1'] ?? -1;
//     final ping2 = _pingCache['${record.id}_2'] ?? -1;
    
//     // ایجاد رکورد جدید با IP بهینه
//     DnsRecord optimizedRecord = record;
    
//     // اگر هر دو پینگ معتبر هستند، کمترین را انتخاب کن
//     if (ping1 > 0 && ping2 > 0) {
//       if (ping2 < ping1) {
//         // IP دوم پینگ کمتری دارد، جابجا کن
//         optimizedRecord = record.copyWith(
//           ip1: record.ip2,
//           ip2: record.ip1,
//         );
//       }
//     }
//     // اگر فقط IP دوم پینگ دارد
//     else if (ping1 <= 0 && ping2 > 0) {
//       optimizedRecord = record.copyWith(
//         ip1: record.ip2,
//         ip2: record.ip1,
//       );
//     }
//     // اگر فقط IP اول پینگ دارد یا هیچکدام پینگ ندارند، تغییری نده

//     // فقط انتخاب و بازگشت به صفحه قبلی، روند اتصال در صفحه قبلی انجام شود
//     if (mounted) {
//       Navigator.pop(context, optimizedRecord);
//     }
//   }

//   // Map<String, int> _pingCache = {}; // Removed duplicate declaration

//   Future<void> _testAllDns({bool auto = false}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final pingCache = await DnsPingBase.testAllDns(
//       context: context,
//       dnsRecords: _dnsRecords,
//       sortType: _sortType,
//       sortDnsRecords: _sortDnsRecords,
//       auto: auto,
//       mounted: mounted,
//       showDialogCallback: (List<String> results) async {
//         if (!mounted) return;
//         // اگر کاربر قبلا گزینه دیگر نشان نده را زده بود، دیالوگ را نمایش نده
//         final dontShow = prefs.getBool('dont_show_dns_test_dialog') ?? false;
//         if (dontShow) return;
//         await showDialog(
//           context: context,
//           barrierDismissible: true,
//           builder: (context) => GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: () {
//               Navigator.of(context).pop();
//             },
//             child: AlertDialog(
//               title: Text(context.tr('testResultAllDns')),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: ListView(
//                   shrinkWrap: true,
//                   children: results.map((e) => Text(e)).toList(),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(context.tr('close')),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     await prefs.setBool('dont_show_dns_test_dialog', true);
//                     if (Navigator.canPop(context)) {
//                       Navigator.pop(context);
//                     }
//                   },
//                   child: Text(context.tr('dontShowAgain')),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//       setTestDialogOpen: (v) {
//         if (!mounted) return;
//         setState(() => _testDialogOpen = v);
//       },
//       // setCancelTest: (v) => setState(() => _cancelTest = v),
//     );
//     if (!mounted) return;
//     setState(() {
//       _pingCache = pingCache;
//       _sortDnsRecords();
//     });
//   }
  
//   /// تست ترتیبی DNS ها بر اساس کمترین پینگ در تست قبلی
//   Future<void> _testSequentialDns() async {
//     final prefs = await SharedPreferences.getInstance();
    
//     // دریافت تعداد تست از کاربر
//     int? testCount = await showDialog<int>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(context.tr('sequentialTest')),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(context.tr('sequentialTestDescription')),
//             const SizedBox(height: 16),
//             Text(context.tr('testCount')),
//             Slider(
//               value: 5,
//               min: 1,
//               max: 20,
//               divisions: 19,
//               label: '5',
//               onChanged: (value) {},
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(context.tr('cancel')),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, 5),
//             child: Text(context.tr('ok')),
//           ),
//         ],
//       ),
//     );
    
//     if (testCount == null) return; // کاربر لغو کرده است
    
//     final pingCache = await DnsPingBase.testSequentialDns(
//       context: context,
//       dnsRecords: _dnsRecords,
//       sortType: _sortType,
//       sortDnsRecords: _sortDnsRecords,
//       testCount: testCount,
//       mounted: mounted,
//       showDialogCallback: (List<String> results) async {
//         if (!mounted) return;
//         // اگر کاربر قبلا گزینه دیگر نشان نده را زده بود، دیالوگ را نمایش نده
//         final dontShow = prefs.getBool('dont_show_dns_test_dialog') ?? false;
//         if (dontShow) return;
//         await showDialog(
//           context: context,
//           barrierDismissible: true,
//           builder: (context) => GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: () {
//               Navigator.of(context).pop();
//             },
//             child: AlertDialog(
//               title: Text(context.tr('sequentialTest')),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: ListView(
//                   shrinkWrap: true,
//                   children: results.map((e) => Text(e)).toList(),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(context.tr('close')),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     await prefs.setBool('dont_show_dns_test_dialog', true);
//                     if (Navigator.canPop(context)) {
//                       Navigator.pop(context);
//                     }
//                   },
//                   child: Text(context.tr('dontShowAgain')),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//       setTestDialogOpen: (v) {
//         if (!mounted) return;
//         setState(() => _testDialogOpen = v);
//       },
//     );
    
//     if (!mounted) return;
//     setState(() {
//       _pingCache = pingCache;
//       _sortDnsRecords();
//     });
//   }
  
//   /// تست پیشرفته DNS با محاسبه میانگین پینگ، پکت از دست رفته و امتیازدهی
//   Future<void> _testAdvancedDns() async {
//     final prefs = await SharedPreferences.getInstance();
    
//     // دریافت تعداد تست از کاربر
//     int? testCount = await showDialog<int>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(context.tr('advancedTest')),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(context.tr('advancedTestDescription')),
//             const SizedBox(height: 16),
//             Text(context.tr('testCount')),
//             StatefulBuilder(
//               builder: (context, setState) {
//                 return Column(
//                   children: [
//                     Slider(
//                       value: DnsPingBase.testCount.toDouble(),
//                       min: 3,
//                       max: 10,
//                       divisions: 7,
//                       label: DnsPingBase.testCount.toString(),
//                       onChanged: (value) {
//                         setState(() {
//                           DnsPingBase.testCount = value.toInt();
//                         });
//                       },
//                     ),
//                     Text('${DnsPingBase.testCount}'),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(context.tr('cancel')),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, DnsPingBase.testCount),
//             child: Text(context.tr('ok')),
//           ),
//         ],
//       ),
//     );
    
//     if (testCount == null) return; // کاربر لغو کرده است
    
//     final result = await DnsPingBase.testAdvancedDns(
//       context: context,
//       dnsRecords: _dnsRecords,
//       sortType: _sortType,
//       sortDnsRecords: _sortDnsRecords,
//       testCount: testCount,
//       mounted: mounted,
//       showDialogCallback: (List<String> results) async {
//         if (!mounted) return;
//         // اگر کاربر قبلا گزینه دیگر نشان نده را زده بود، دیالوگ را نمایش نده
//         final dontShow = prefs.getBool('dont_show_dns_test_dialog') ?? false;
//         if (dontShow) return;
//         await showDialog(
//           context: context,
//           barrierDismissible: true,
//           builder: (context) => GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: () {
//               Navigator.of(context).pop();
//             },
//             child: AlertDialog(
//               title: Text(context.tr('advancedTest')),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: ListView(
//                   shrinkWrap: true,
//                   children: results.map((e) => Text(e)).toList(),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(context.tr('close')),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     await prefs.setBool('dont_show_dns_test_dialog', true);
//                     if (Navigator.canPop(context)) {
//                       Navigator.pop(context);
//                     }
//                   },
//                   child: Text(context.tr('dontShowAgain')),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//       setTestDialogOpen: (v) {
//         if (!mounted) return;
//         setState(() => _testDialogOpen = v);
//       },
//     );
    
//     if (!mounted) return;
//     setState(() {
//       _pingCache = result['pingCache'];
//       _sortDnsRecords();
//     });
//   }

//   String _searchQuery = '';
//   bool _showSearch = false;
//   final TextEditingController _searchController = TextEditingController();

//   List<DnsRecord> get _filteredDnsRecords {
//     if (_searchQuery.trim().isEmpty) return _dnsRecords;
//     // Remove all spaces from query and split by space for multi-part search
//     final parts = _searchQuery
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim()
//         .split(' ');
//     return _dnsRecords.where((r) {
//       final label = r.label.replaceAll(' ', '').toLowerCase();
//       final ip1 = r.ip1.replaceAll(' ', '').toLowerCase();
//       final ip2 = r.ip2.replaceAll(' ', '').toLowerCase();
//       // All parts must be found in any field (label, ip1, ip2)
//       return parts.every((part) {
//         final p = part.replaceAll(' ', '').toLowerCase();
//         return label.contains(p) || ip1.contains(p) || ip2.contains(p);
//       });
//     }).toList();
//   }

//   Future<void> _deleteUserDns(DnsRecord record) async {
//     final prefs = await SharedPreferences.getInstance();
//     final userDnsJson = prefs.getString('user_dns_list');
//     List<dynamic> userDnsList = [];
//     if (userDnsJson != null) {
//       try {
//         userDnsList = List.from(jsonDecode(userDnsJson));
//       } catch (_) {}
//     }
//     userDnsList.removeWhere((e) => e['id'] == record.id);
//     await prefs.setString('user_dns_list', jsonEncode(userDnsList));
//     // Remove from liked if present
//     final liked = prefs.getStringList('liked_dns_ids') ?? [];
//     liked.remove(record.id);
//     await prefs.setStringList('liked_dns_ids', liked);
//     await _loadCachedDnsList();
//     setState(() {
//       _sortDnsRecords();
//     });
//   }

//   Future<void> _editUserDns(DnsRecord record) async {
//     await showDialog(
//       context: context,
//       builder: (context) => AddDnsDialog(
//         initialRecord: record,
//         onAdd: (editedRecord) async {
//           // Replace in user_dns_list
//           final prefs = await SharedPreferences.getInstance();
//           final userDnsJson = prefs.getString('user_dns_list');
//           List<dynamic> userDnsList = [];
//           if (userDnsJson != null) {
//             try {
//               userDnsList = List.from(jsonDecode(userDnsJson));
//             } catch (_) {}
//           }
//           // Remove all previous versions by id and by ip1+ip2
//           userDnsList.removeWhere((e) {
//             final key = (e['ip1'] + '_' + e['ip2'])
//                 .replaceAll(' ', '')
//                 .toLowerCase();
//             final editedKey = (editedRecord.ip1 + '_' + editedRecord.ip2)
//                 .replaceAll(' ', '')
//                 .toLowerCase();
//             return e['id'] == record.id || key == editedKey;
//           });
//           userDnsList.add(editedRecord.toJson());
//           await prefs.setString('user_dns_list', jsonEncode(userDnsList));

//           // Add to liked_dns_ids if not already present
//           final liked = prefs.getStringList('liked_dns_ids') ?? [];
//           if (!liked.contains(editedRecord.id)) {
//             liked.add(editedRecord.id);
//             await prefs.setStringList('liked_dns_ids', liked);
//           }

//           await _loadCachedDnsList();
//           await _loadUserDnsIds();
//           setState(() {
//             _sortDnsRecords();
//           });
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeManager = Provider.of<ThemeManager>(context);
//     final isDark = themeManager.isDarkModeActive(context);

//     return WillPopScope(
//       onWillPop: () async {
//         if (_testDialogOpen) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(context.tr('waitForPingTest')),
//               duration: const Duration(seconds: 2),
//             ),
//           );
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         backgroundColor: isDark
//             ? AppColors.darkBackground
//             : const Color(0xFFF7F8FA),
//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
//           title: Text(
//             context.tr('selectDns'),
//             style: TextStyle(
//               color: isDark ? AppColors.darkTextPrimary : AppColors.primaryText,
//               fontWeight: FontWeight.bold,
//               fontSize: 22,
//               letterSpacing: 0.5,
//             ),
//           ),
//           iconTheme: IconThemeData(
//             color: isDark ? AppColors.darkIconPrimary : const Color(0xFF222B45),
//           ),
//           actions: [
//             _testDialogOpen
//                 ? IconButton(
//                     icon: const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Color(0xFF5A9CFF),
//                       ),
//                     ),
//                     tooltip: context.tr('cancelAllDnsTest'),
//                     onPressed: () {
//                       setState(() {
//                         // _cancelTest = true;
//                         _testDialogOpen = false;
//                       });
//                     },
//                   )
//                 : PopupMenuButton<String>(
//                     icon: const Icon(Icons.wifi_tethering),
//                     tooltip: context.tr('dnsTest'),
//                     color: isDark ? AppColors.darkCardBackground : Colors.white,
//                     enabled: !_loadingList && _dnsRecords.isNotEmpty,
//                     itemBuilder: (context) => [
//                       PopupMenuItem(
//                         value: 'simultaneous',
//                         child: SizedBox(
//                           width: 180,
//                           child: Text(
//                             context.tr('simultaneousTest'),
//                             style: TextStyle(
//                               color: isDark
//                                   ? AppColors.darkTextPrimary
//                                   : const Color(0xFF222B45),
//                             ),
//                           ),
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: 'sequential',
//                         child: SizedBox(
//                           width: 180,
//                           child: Text(
//                             context.tr('sequentialTest'),
//                             style: TextStyle(
//                               color: isDark
//                                   ? AppColors.darkTextPrimary
//                                   : const Color(0xFF222B45),
//                             ),
//                           ),
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: 'advanced',
//                         child: SizedBox(
//                           width: 180,
//                           child: Text(
//                             context.tr('advancedTest'),
//                             style: TextStyle(
//                               color: isDark
//                                   ? AppColors.darkTextPrimary
//                                   : const Color(0xFF222B45),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                     onSelected: (value) async {
//                       if (value == 'simultaneous') {
//                         await _testAllDns();
//                       } else if (value == 'sequential') {
//                         await _testSequentialDns();
//                       } else if (value == 'advanced') {
//                         await _testAdvancedDns();
//                       }
//                     },
//                   ),
//             PopupMenuButton<String>(
//               icon: const Icon(Icons.sort),
//               tooltip: context.tr('sort'),
//               color: isDark ? AppColors.darkCardBackground : Colors.white,
//               itemBuilder: (context) => [
//                 PopupMenuItem(
//                   value: 'default',
//                   child: SizedBox(
//                     width: 160,
//                     child: Text(
//                       context.tr('default'),
//                       style: TextStyle(
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : const Color(0xFF222B45),
//                       ),
//                     ),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 'ping',
//                   child: SizedBox(
//                     width: 160,
//                     child: Text(
//                       context.tr('lowestPing'),
//                       style: TextStyle(
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : const Color(0xFF222B45),
//                       ),
//                     ),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 'name',
//                   child: SizedBox(
//                     width: 160,
//                     child: Text(
//                       context.tr('sortByName'),
//                       style: TextStyle(
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : const Color(0xFF222B45),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//               onSelected: (value) {
//                 setState(() {
//                   _sortType = value;
//                   _sortDnsRecords();
//                 });
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.search),
//               tooltip: context.tr('search'),
//               onPressed: () {
//                 setState(() {
//                   _showSearch = !_showSearch;
//                   if (_showSearch) {
//                     _searchController.text = _searchQuery;
//                   }
//                 });
//               },
//             ),
//             PopupMenuButton<String>(
//               icon: const Icon(Icons.more_vert),
//               tooltip: context.tr('more'),
//               color: isDark ? AppColors.darkCardBackground : Colors.white,
//               itemBuilder: (context) => [
//                 PopupMenuItem(
//                   value: 'customTest',
//                   child: SizedBox(
//                     width: 180,
//                     child: Text(
//                       context.tr('testDomainWithAllDns'),
//                       style: TextStyle(
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : const Color(0xFF222B45),
//                       ),
//                     ),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 'refreshDns',
//                   child: SizedBox(
//                     width: 180,
//                     child: Text(
//                       context.tr('getNewListFromServer'),
//                       style: TextStyle(
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : const Color(0xFF222B45),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//               onSelected: (value) async {
//                 if (value == 'customTest') {
//                   showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: Text(context.tr('testDomainWithAllDns')),
//                       content: Text(context.tr('comingSoon')),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.of(context).pop(),
//                           child: Text(context.tr('close')),
//                         ),
//                       ],
//                     ),
//                   );
//                 } else if (value == 'refreshDns') {
//                   await fetchDnsListWithTimer(force: true);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(context.tr('dnsListUpdated')),
//                       duration: const Duration(seconds: 2),
//                     ),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Stack(
//             children: [
//               _loadingList
//                   ? const Center(child: CircularProgressIndicator())
//                   : _loadError != null
//                   ? Center(child: Text(_loadError!))
//                   : RefreshIndicator(
//                       onRefresh: _fetchDnsList,
//                       child: Column(
//                         children: [
//                           Expanded(
//                             child: LayoutBuilder(
//                               builder: (context, constraints) {
//                                 final isWide =
//                                     constraints.maxWidth > 600 &&
//                                     Theme.of(context).platform ==
//                                         TargetPlatform.windows;
//                                 if (isWide) {
//                                   // اگر خیلی عریض بود سه ستونه، اگر فقط عریض بود دو ستونه
//                                   int columns = constraints.maxWidth > 1050
//                                       ? 3
//                                       : 2;
//                                   return GridView.builder(
//                                     physics:
//                                         const AlwaysScrollableScrollPhysics(),
//                                     gridDelegate:
//                                         SliverGridDelegateWithFixedCrossAxisCount(
//                                           crossAxisCount: columns,
//                                           crossAxisSpacing: 8,
//                                           mainAxisSpacing: 8,
//                                           mainAxisExtent:
//                                               140, // ارتفاع ثابت برای هر آیتم
//                                         ),
//                                     itemCount: _filteredDnsRecords.length,
//                                     itemBuilder: (context, index) =>
//                                         _buildDnsCard(
//                                           context,
//                                           _filteredDnsRecords[index],
//                                           index,
//                                         ),
//                                   );
//                                 } else {
//                                   // حالت معمول لیست
//                                   return ListView.separated(
//                                     physics:
//                                         const AlwaysScrollableScrollPhysics(),
//                                     itemCount: _filteredDnsRecords.length,
//                                     separatorBuilder: (_, __) =>
//                                         const SizedBox(height: 8),
//                                     itemBuilder: (context, index) =>
//                                         _buildDnsCard(
//                                           context,
//                                           _filteredDnsRecords[index],
//                                           index,
//                                         ),
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//               if (_showSearch)
//                 Positioned.fill(
//                   child: GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _showSearch = false;
//                       });
//                     },
//                     child: Container(
//                       color: Colors.black.withOpacity(0.2),
//                       alignment: Alignment.topCenter,
//                       child: SafeArea(
//                         child: Container(
//                           margin: const EdgeInsets.all(24),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: isDark
//                                 ? AppColors.darkCardBackground
//                                 : AppColors.pureWhite,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 8,
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: TextField(
//                                   controller: _searchController,
//                                   autofocus: true,
//                                   style: TextStyle(
//                                     color: isDark
//                                         ? AppColors.textWhite
//                                         : AppColors.textPrimary,
//                                   ),
//                                   decoration: InputDecoration(
//                                     hintText: context.tr('searchByNameOrIp'),
//                                     hintStyle: TextStyle(
//                                       color: isDark
//                                           ? AppColors.textLight
//                                           : AppColors.textSecondary,
//                                     ),
//                                     border: InputBorder.none,
//                                     fillColor: isDark
//                                         ? AppColors.darkNavy
//                                         : AppColors.pureWhite,
//                                     filled: true,
//                                   ),
//                                   onChanged: (v) {
//                                     setState(() {
//                                       _searchQuery = v;
//                                     });
//                                   },
//                                   onSubmitted: (v) {
//                                     setState(() {
//                                       _searchQuery = v;
//                                       _showSearch = false;
//                                     });
//                                   },
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.close),
//                                 onPressed: () {
//                                   setState(() {
//                                     _showSearch = false;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         floatingActionButton: FloatingActionButton(
//           child: const Icon(Icons.add),
//           onPressed: () async {
//             if (_testDialogOpen) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(context.tr('waitForPingTest')),
//                   duration: const Duration(seconds: 2),
//                 ),
//               );
//               return;
//             }
//             final result = await showDialog(
//               context: context,
//               builder: (context) => AddDnsDialog(
//                 onAdd: (newRecord) async {
//                   // Like the DNS if not already liked
//                   final prefs = await SharedPreferences.getInstance();
//                   final liked = prefs.getStringList('liked_dns_ids') ?? [];
//                   if (!liked.contains(newRecord.id)) {
//                     liked.add(newRecord.id);
//                     await prefs.setStringList('liked_dns_ids', liked);
//                     setState(() {
//                       _likedDnsIds = liked.toSet();
//                     });
//                   }
//                   await fetchDnsListWithTimer(force: true);
//                 },
//               ),
//             );
//             // اگر رکوردی از دیالوگ برگشت (در حالت وصل شدن به DNS موجود)
//             if (result is DnsRecord) {
//               _connectToDns(result);
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

// class _TestDomainWithAllDnsDialog extends StatefulWidget {
//   final String domain;
//   final List<DnsRecord> dnsRecords;
//   const _TestDomainWithAllDnsDialog({
//     required this.domain,
//     required this.dnsRecords,
//   });

//   @override
//   State<_TestDomainWithAllDnsDialog> createState() =>
//       _TestDomainWithAllDnsDialogState();
// }

// class _TestDomainWithAllDnsDialogState
//     extends State<_TestDomainWithAllDnsDialog> {
//   @override
//   Widget build(BuildContext context) {
//     final themeManager = Provider.of<ThemeManager>(context);
//     final isDark = themeManager.isDarkModeActive(context);

//     return AlertDialog(
//       backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
//       title: Text(
//         '${context.tr('testDomainWithAllDns')}: "${widget.domain}"',
//         style: TextStyle(
//           color: isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
//         ),
//       ),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: ListView.builder(
//           shrinkWrap: true,
//           itemCount: widget.dnsRecords.length,
//           itemBuilder: (context, index) {
//             final record = widget.dnsRecords[index];
//             return _DnsTestTile(domain: widget.domain, record: record);
//           },
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: Text(
//             context.tr('close'),
//             style: TextStyle(
//               color: isDark
//                   ? AppColors.darkTextPrimary
//                   : const Color(0xFF222B45),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _DnsTestTile extends StatefulWidget {
//   final String domain;
//   final DnsRecord record;
//   const _DnsTestTile({required this.domain, required this.record});

//   @override
//   State<_DnsTestTile> createState() => _DnsTestTileState();
// }

// class _DnsTestTileState extends State<_DnsTestTile> {
//   dynamic status;
//   bool _loading = true;

//   late final ThemeManager themeManager;
//   late final bool isDark;

//   @override
//   void initState() {
//     themeManager = Provider.of<ThemeManager>(context, listen: false);
//     isDark = themeManager.isDarkModeActive(context);
//     super.initState();
//     _runTest();
//   }

//   Future<void> _runTest() async {
//     final result = await DnsService.testDnsWithDns(
//       widget.domain,
//       widget.record.ip1,
//     );
//     if (!mounted) return;
//     setState(() {
//       status = result;
//       _loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(
//         widget.record.label,
//         style: TextStyle(
//           color: isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
//         ),
//       ),
//       subtitle: Text(
//         widget.record.ip1,
//         style: TextStyle(
//           color: isDark ? AppColors.darkTextSecondary : Colors.grey[600],
//         ),
//       ),
//       trailing: _loading
//           ? const SizedBox(
//               width: 24,
//               height: 24,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//           : status != null
//           ? Text(
//               status.toString(),
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             )
//           : Text(context.tr('error'), style: const TextStyle(color: Colors.red)),
//     );
//   }
// }
