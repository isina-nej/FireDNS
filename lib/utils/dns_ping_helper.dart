// // import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/material.dart';
// import '../path/path.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class DnsPingHelper {
//   static bool cancelRequested = false;
//   static int testCount = 5; // تعداد تست برای تست پیشرفته

//   /// بارگذاری کش پینگ از SharedPreferences
//   static Future<Map<String, int>> loadPingCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonStr = prefs.getString('cached_ping_cache');
//     if (jsonStr == null || jsonStr.isEmpty) return {};
//     try {
//       final Map<String, dynamic> map = jsonDecode(jsonStr);
//       return map.map(
//         (k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? -1),
//       );
//     } catch (_) {
//       return {};
//     }
//   }

//   /// بارگذاری ترتیب DNSها از SharedPreferences
//   static Future<List<String>> loadDnsOrder() async {
//     final prefs = await SharedPreferences.getInstance();
//     final list = prefs.getStringList('cached_dns_order');
//     return list ?? [];
//   }

//   /// لغو تست پینگ (در صورت نیاز)
//   static void cancelPingTest() {
//     cancelRequested = true;
//   }

//   /// تست پینگ یک IP (IPv4 یا IPv6) و بازگشت مقدار پینگ یا -1 در صورت عدم دسترسی
//   static Future<int?> ping(String ip) async {
//     try {
//       final isIPv6 = ip.contains(':') && !ip.contains('.');
//       final status = isIPv6
//           ? await DnsService.testDnsIPv6(ip)
//           : await DnsService.testDns(ip);
//       if (status.isReachable == true && status.ping > 0) {
//         return status.ping;
//       }
//       return -1;
//     } catch (_) {
//       return -1;
//     }
//   }

//   static Future<Map<String, int>> testAllDns({
//     required BuildContext context,
//     required List dnsRecords,
//     required String sortType,
//     required Function sortDnsRecords,
//     bool auto = false,
//     bool mounted = true,
//     Function? showDialogCallback,
//     Function? setTestDialogOpen,
//     Function? setCancelTest,
//   }) async {
//     cancelRequested = false;
//     Map<String, int> pingCache = {};
//     if (dnsRecords.isEmpty) return pingCache;
//     if (!auto && context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('در حال تست همه DNSها...'),
//           duration: Duration(seconds: 1),
//         ),
//       );
//     }
//     if (setTestDialogOpen != null) setTestDialogOpen(true);
//     if (setCancelTest != null) setCancelTest(false);
//     final List<String> results = [];
//     pingCache.clear();
    
//     // تست هر DNS به صورت جداگانه و به‌روزرسانی UI بعد از هر تست
//     int index = 0;
//     for (final record in dnsRecords) {
//       if (cancelRequested) break;
      
//       final ip1 = record.ip1;
//       final ip2 = record.ip2;
      
//       // Only test IPv4 addresses, skip others
//       final ipv4Regex = RegExp(
//         r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
//       );
      
//       if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
//         // برای DNS های نامعتبر
//         pingCache[record.id + '_1'] = -1;
//         pingCache[record.id + '_2'] = -1;
        
//         results.add(
//           '${index + 1}. ${record.label}\nDNS1: ❌ (پینگ: --- ms)\nDNS2: ❌ (پینگ: --- ms)',
//         );
        
//         // به‌روزرسانی UI
//         if (sortType == 'ping' && mounted) {
//           sortDnsRecords();
//         }
        
//         index++;
//         continue;
//       }
      
//       // تست DNS1
//       if (!cancelRequested) {
//         final status1 = await DnsService.testDns(ip1);
//         pingCache[record.id + '_1'] = status1.ping;
        
//         // به‌روزرسانی UI بعد از تست DNS1
//         if (sortType == 'ping' && mounted) {
//           sortDnsRecords();
//         }
//       }
      
//       // تست DNS2
//       if (!cancelRequested) {
//         final status2 = await DnsService.testDns(ip2);
//         pingCache[record.id + '_2'] = status2.ping;
        
//         // به‌روزرسانی UI بعد از تست DNS2
//         if (sortType == 'ping' && mounted) {
//           sortDnsRecords();
//         }
//       }
      
//       if (!cancelRequested) {
//         // اضافه کردن نتیجه به لیست نتایج
//         final ping1 = pingCache[record.id + '_1'] ?? -1;
//         final ping2 = pingCache[record.id + '_2'] ?? -1;
        
//         results.add(
//           '${index + 1}. ${record.label}\nDNS1: ${ping1 > 0 ? '✅' : '❌'}  (پینگ: ${ping1 > 0 ? ping1 : '---'} ms)\nDNS2: ${ping2 > 0 ? '✅' : '❌'}  (پینگ: ${ping2 > 0 ? ping2 : '---'} ms)',
//         );
//       }
      
//       index++;
//     }
    
//     // ذخیره نتایج در SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setString('cached_ping_cache', jsonEncode(pingCache));
//     prefs.setStringList(
//       'cached_dns_order',
//       dnsRecords.map((e) => e.id.toString()).toList().cast<String>(),
//     );
    
//     if (!mounted) {
//       if (setTestDialogOpen != null) setTestDialogOpen(false);
//       if (setCancelTest != null) setCancelTest(false);
//       return pingCache;
//     }
    
//     if (!auto && showDialogCallback != null) {
//       showDialogCallback(results);
//     }
    
//     if (setTestDialogOpen != null) setTestDialogOpen(false);
//     if (setCancelTest != null) setCancelTest(false);
//     return pingCache;
//   }
  
//   /// تست ترتیبی DNS ها بر اساس کمترین پینگ در تست قبلی
//   static Future<Map<String, int>> testSequentialDns({
//     required BuildContext context,
//     required List dnsRecords,
//     required String sortType,
//     required Function sortDnsRecords,
//     required int testCount,
//     bool mounted = true,
//     Function? showDialogCallback,
//     Function? setTestDialogOpen,
//     Function? setCancelTest,
//   }) async {
//     cancelRequested = false;
//     Map<String, int> pingCache = await loadPingCache();
//     if (dnsRecords.isEmpty) return pingCache;
    
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('در حال تست ترتیبی DNSها...'),
//           duration: Duration(seconds: 1),
//         ),
//       );
//     }
    
//     if (setTestDialogOpen != null) setTestDialogOpen(true);
//     if (setCancelTest != null) setCancelTest(false);
    
//     final List<String> results = [];
    
//     // مرتب‌سازی DNS ها بر اساس پینگ قبلی
//     List sortedRecords = List.from(dnsRecords);
//     sortedRecords.sort((a, b) {
//       int pingA1 = pingCache['${a.id}_1'] ?? pingCache[a.id] ?? 999999;
//       int pingA2 = pingCache['${a.id}_2'] ?? 999999;
//       int pingB1 = pingCache['${b.id}_1'] ?? pingCache[b.id] ?? 999999;
//       int pingB2 = pingCache['${b.id}_2'] ?? 999999;

//       int sortA = pingA1 >= 0
//           ? pingA1
//           : pingA2 >= 0
//               ? pingA2
//               : 999999;
//       int sortB = pingB1 >= 0
//           ? pingB1
//           : pingB2 >= 0
//               ? pingB2
//               : 999999;
//       return sortA.compareTo(sortB);
//     });
    
//     // تست هر DNS به ترتیب
//     for (int i = 0; i < sortedRecords.length && i < testCount; i++) {
//       if (cancelRequested) break;
      
//       final record = sortedRecords[i];
//       final ip1 = record.ip1;
//       final ip2 = record.ip2;
      
//       // فقط آدرس‌های IPv4 را تست کن
//       final ipv4Regex = RegExp(
//         r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
//       );
      
//       if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
//         pingCache[record.id + '_1'] = -1;
//         pingCache[record.id + '_2'] = -1;
//         results.add(
//           '${i + 1}. ${record.label}\nDNS1: ❌ (پینگ: --- ms)\nDNS2: ❌ (پینگ: --- ms)',
//         );
        
//         // به‌روزرسانی UI
//         if (sortType == 'ping' && mounted) {
//           sortDnsRecords();
//         }
        
//         continue;
//       }
      
//       if (cancelRequested) break;
      
//       // تست DNS1 و به‌روزرسانی UI بلافاصله
//       final status1 = await DnsService.testDns(ip1);
//       pingCache[record.id + '_1'] = status1.ping;
      
//       // به‌روزرسانی UI بعد از تست DNS1
//       if (sortType == 'ping' && mounted) {
//         sortDnsRecords();
//       }
      
//       if (cancelRequested) break;
      
//       // تست DNS2 و به‌روزرسانی UI بلافاصله
//       final status2 = await DnsService.testDns(ip2);
//       pingCache[record.id + '_2'] = status2.ping;
      
//       results.add(
//         '${i + 1}. ${record.label}\nDNS1: ${status1.isReachable ? '✅' : '❌'} (پینگ: ${status1.ping > 0 ? status1.ping : '---'} ms)\nDNS2: ${status2.isReachable ? '✅' : '❌'} (پینگ: ${status2.ping > 0 ? status2.ping : '---'} ms)',
//       );
      
//       // به‌روزرسانی UI بعد از تست DNS2
//       if (sortType == 'ping' && mounted) {
//         sortDnsRecords();
//       }
      
//       // ذخیره موقت نتایج در SharedPreferences بعد از هر DNS
//       final prefs = await SharedPreferences.getInstance();
//       prefs.setString('cached_ping_cache', jsonEncode(pingCache));
//     }
    
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setString('cached_ping_cache', jsonEncode(pingCache));
    
//     if (!mounted) {
//       if (setTestDialogOpen != null) setTestDialogOpen(false);
//       if (setCancelTest != null) setCancelTest(false);
//       return pingCache;
//     }
    
//     if (showDialogCallback != null) {
//       showDialogCallback(results);
//     }
    
//     if (setTestDialogOpen != null) setTestDialogOpen(false);
//     if (setCancelTest != null) setCancelTest(false);
    
//     return pingCache;
//   }
  
//   /// تست پیشرفته DNS با محاسبه میانگین پینگ، پکت از دست رفته و امتیازدهی
//   /// این نسخه از تست پیشرفته، هر DNS را به صورت جداگانه تست می‌کند و UI را به‌روز می‌کند
//   static Future<Map<String, dynamic>> testAdvancedDns({
//     required BuildContext context,
//     required List dnsRecords,
//     required String sortType,
//     required Function sortDnsRecords,
//     required int testCount,
//     bool mounted = true,
//     Function? showDialogCallback,
//     Function? setTestDialogOpen,
//     Function? setCancelTest,
//   }) async {
//     cancelRequested = false;
//     Map<String, int> pingCache = {};
//     Map<String, dynamic> advancedResults = {};
    
//     if (dnsRecords.isEmpty) return {'pingCache': pingCache, 'advancedResults': advancedResults};
    
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(context.tr('advancedTestInProgress')),
//           duration: const Duration(seconds: 1),
//         ),
//       );
//     }
    
//     if (setTestDialogOpen != null) setTestDialogOpen(true);
//     if (setCancelTest != null) setCancelTest(false);
    
//     final List<String> results = [];
//     pingCache.clear();
    
//     // ساختار داده برای نگهداری نتایج تست‌ها
//     Map<String, Map<String, dynamic>> testData = {};
    
//     // آماده‌سازی ساختار داده برای هر DNS
//     for (final record in dnsRecords) {
//       final ip1 = record.ip1;
//       final ip2 = record.ip2;
      
//       // فقط آدرس‌های IPv4 را تست کن
//       final ipv4Regex = RegExp(
//         r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
//       );
      
//       if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
//         pingCache[record.id + '_1'] = -1;
//         pingCache[record.id + '_2'] = -1;
//         advancedResults[record.id] = {
//           'label': record.label,
//           'ip1': ip1,
//           'ip2': ip2,
//           'avgPing1': -1,
//           'avgPing2': -1,
//           'packetLoss1': 100,
//           'packetLoss2': 100,
//           'score1': 0,
//           'score2': 0,
//         };
        
//         // به‌روزرسانی UI
//         if (sortType == 'ping' && mounted) {
//           sortDnsRecords();
//         }
        
//         continue;
//       }
      
//       testData[record.id] = {
//         'label': record.label,
//         'ip1': ip1,
//         'ip2': ip2,
//         'pings1': <int>[],
//         'pings2': <int>[],
//         'successCount1': 0,
//         'successCount2': 0,
//       };
//     }
    
//     // تست هر DNS به صورت جداگانه
//     for (final recordId in testData.keys) {
//       if (cancelRequested) break;
      
//       final data = testData[recordId]!;
      
//       // انجام تست‌های متعدد برای هر DNS
//       for (int testIndex = 0; testIndex < testCount; testIndex++) {
//         if (cancelRequested) break;
        
//         // تست DNS1
//         final status1 = await DnsService.testDns(data['ip1']);
//         if (status1.isReachable && status1.ping > 0) {
//           data['pings1'].add(status1.ping);
//           data['successCount1'] = data['successCount1'] + 1;
          
//           // محاسبه میانگین موقت و به‌روزرسانی pingCache
//           if (data['pings1'].isNotEmpty) {
//             double avgPing1 = data['pings1'].reduce((a, b) => a + b) / data['pings1'].length;
//             pingCache[recordId + '_1'] = avgPing1.round();
            
//             // به‌روزرسانی UI بعد از هر تست
//             if (sortType == 'ping' && mounted) {
//               sortDnsRecords();
//             }
//           }
//         }
        
//         // تست DNS2
//         final status2 = await DnsService.testDns(data['ip2']);
//         if (status2.isReachable && status2.ping > 0) {
//           data['pings2'].add(status2.ping);
//           data['successCount2'] = data['successCount2'] + 1;
          
//           // محاسبه میانگین موقت و به‌روزرسانی pingCache
//           if (data['pings2'].isNotEmpty) {
//             double avgPing2 = data['pings2'].reduce((a, b) => a + b) / data['pings2'].length;
//             pingCache[recordId + '_2'] = avgPing2.round();
            
//             // به‌روزرسانی UI بعد از هر تست
//             if (sortType == 'ping' && mounted) {
//               sortDnsRecords();
//             }
//           }
//         }
        
//         // ذخیره موقت نتایج در SharedPreferences بعد از هر دور تست
//         if (testIndex % 2 == 1) { // هر دو تست یکبار ذخیره کن
//           final prefs = await SharedPreferences.getInstance();
//           prefs.setString('cached_ping_cache', jsonEncode(pingCache));
//         }
//       }
      
//       // محاسبه نتایج نهایی برای این DNS
//       List<int> pings1 = data['pings1'];
//       List<int> pings2 = data['pings2'];
//       int successCount1 = data['successCount1'];
//       int successCount2 = data['successCount2'];
      
//       double avgPing1 = pings1.isEmpty ? -1 : pings1.reduce((a, b) => a + b) / pings1.length;
//       double avgPing2 = pings2.isEmpty ? -1 : pings2.reduce((a, b) => a + b) / pings2.length;
      
//       // محاسبه پکت از دست رفته
//       double packetLoss1 = (testCount - successCount1) / testCount * 100;
//       double packetLoss2 = (testCount - successCount2) / testCount * 100;
      
//       // محاسبه امتیاز
//       double pingScore1 = avgPing1 <= 0 ? 0 : (avgPing1 < 50 ? 70 : (avgPing1 >= 500 ? 0 : 70 - (avgPing1 - 50) * 70 / 450));
//       double pingScore2 = avgPing2 <= 0 ? 0 : (avgPing2 < 50 ? 70 : (avgPing2 >= 500 ? 0 : 70 - (avgPing2 - 50) * 70 / 450));
      
//       double packetLossScore1 = 30 - (packetLoss1 * 30 / 100);
//       double packetLossScore2 = 30 - (packetLoss2 * 30 / 100);
      
//       double score1 = pingScore1 + packetLossScore1;
//       double score2 = pingScore2 + packetLossScore2;
      
//       // ذخیره نتایج
//       pingCache[recordId + '_1'] = avgPing1.round();
//       pingCache[recordId + '_2'] = avgPing2.round();
      
//       advancedResults[recordId] = {
//         'label': data['label'],
//         'ip1': data['ip1'],
//         'ip2': data['ip2'],
//         'avgPing1': avgPing1,
//         'avgPing2': avgPing2,
//         'packetLoss1': packetLoss1,
//         'packetLoss2': packetLoss2,
//         'score1': score1,
//         'score2': score2,
//         'allPings1': pings1,
//         'allPings2': pings2,
//       };
      
//       results.add(
//         '${data['label']}\n'
//         'DNS1: ${avgPing1 > 0 ? avgPing1.toStringAsFixed(1) : '---'} ms, '
//         '${context.tr('packetLoss')}: ${packetLoss1.toStringAsFixed(1)}%, '
//         '${context.tr('score')}: ${score1.toStringAsFixed(1)}\n'
//         'DNS2: ${avgPing2 > 0 ? avgPing2.toStringAsFixed(1) : '---'} ms, '
//         '${context.tr('packetLoss')}: ${packetLoss2.toStringAsFixed(1)}%, '
//         '${context.tr('score')}: ${score2.toStringAsFixed(1)}',
//       );
      
//       // به‌روزرسانی UI بعد از تکمیل هر DNS
//       if (sortType == 'ping' && mounted) {
//         sortDnsRecords();
//       }
//     }
    
//     // پردازش نتایج و محاسبه آمار
//     for (final recordId in testData.keys) {
//       final data = testData[recordId]!;
      
//       // محاسبه میانگین پینگ
//       List<int> pings1 = data['pings1'];
//       List<int> pings2 = data['pings2'];
//       int successCount1 = data['successCount1'];
//       int successCount2 = data['successCount2'];
      
//       double avgPing1 = pings1.isEmpty ? -1 : pings1.reduce((a, b) => a + b) / pings1.length;
//       double avgPing2 = pings2.isEmpty ? -1 : pings2.reduce((a, b) => a + b) / pings2.length;
      
//       // محاسبه پکت از دست رفته
//       double packetLoss1 = (testCount - successCount1) / testCount * 100;
//       double packetLoss2 = (testCount - successCount2) / testCount * 100;
      
//       // محاسبه امتیاز (100 امتیاز کامل)
//       // فرمول: 70 درصد بر اساس پینگ (کمتر از 50ms = 70، بیشتر از 500ms = 0)
//       //        30 درصد بر اساس پکت از دست رفته (0% = 30، 100% = 0)
//       double pingScore1 = avgPing1 <= 0 ? 0 : (avgPing1 < 50 ? 70 : (avgPing1 >= 500 ? 0 : 70 - (avgPing1 - 50) * 70 / 450));
//       double pingScore2 = avgPing2 <= 0 ? 0 : (avgPing2 < 50 ? 70 : (avgPing2 >= 500 ? 0 : 70 - (avgPing2 - 50) * 70 / 450));
      
//       double packetLossScore1 = 30 - (packetLoss1 * 30 / 100);
//       double packetLossScore2 = 30 - (packetLoss2 * 30 / 100);
      
//       double score1 = pingScore1 + packetLossScore1;
//       double score2 = pingScore2 + packetLossScore2;
      
//       // ذخیره نتایج
//       pingCache[recordId + '_1'] = avgPing1.round();
//       pingCache[recordId + '_2'] = avgPing2.round();
      
//       advancedResults[recordId] = {
//         'label': data['label'],
//         'ip1': data['ip1'],
//         'ip2': data['ip2'],
//         'avgPing1': avgPing1,
//         'avgPing2': avgPing2,
//         'packetLoss1': packetLoss1,
//         'packetLoss2': packetLoss2,
//         'score1': score1,
//         'score2': score2,
//         'allPings1': pings1,  // ذخیره همه پینگ‌ها برای تحلیل بیشتر
//         'allPings2': pings2,
//       };
      
//       results.add(
//         '${data['label']}\n'
//         'DNS1: ${avgPing1 > 0 ? avgPing1.toStringAsFixed(1) : '---'} ms, '
//         '${context.tr('packetLoss')}: ${packetLoss1.toStringAsFixed(1)}%, '
//         '${context.tr('score')}: ${score1.toStringAsFixed(1)}\n'
//         'DNS2: ${avgPing2 > 0 ? avgPing2.toStringAsFixed(1) : '---'} ms, '
//         '${context.tr('packetLoss')}: ${packetLoss2.toStringAsFixed(1)}%, '
//         '${context.tr('score')}: ${score2.toStringAsFixed(1)}',
//       );
//     }
    
//     if (sortType == 'ping') {
//       sortDnsRecords();
//     }
    
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setString('cached_ping_cache', jsonEncode(pingCache));
//     prefs.setString('advanced_dns_results', jsonEncode(advancedResults));
    
//     if (!mounted) {
//       if (setTestDialogOpen != null) setTestDialogOpen(false);
//       if (setCancelTest != null) setCancelTest(false);
//       return {'pingCache': pingCache, 'advancedResults': advancedResults};
//     }
    
//     if (showDialogCallback != null) {
//       showDialogCallback(results);
//     }
    
//     if (setTestDialogOpen != null) setTestDialogOpen(false);
//     if (setCancelTest != null) setCancelTest(false);
    
//     return {'pingCache': pingCache, 'advancedResults': advancedResults};
//   }
// }
