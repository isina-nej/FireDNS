// import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../path/path.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DnsPingHelper {
  static bool cancelRequested = false;

  /// بارگذاری کش پینگ از SharedPreferences
  static Future<Map<String, int>> loadPingCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_ping_cache');
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map(
        (k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? -1),
      );
    } catch (_) {
      return {};
    }
  }

  /// بارگذاری ترتیب DNSها از SharedPreferences
  static Future<List<String>> loadDnsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('cached_dns_order');
    return list ?? [];
  }

  /// لغو تست پینگ (در صورت نیاز)
  static void cancelPingTest() {
    cancelRequested = true;
  }

  /// تست پینگ یک IP (IPv4 یا IPv6) و بازگشت مقدار پینگ یا -1 در صورت عدم دسترسی
  static Future<int?> ping(String ip) async {
    try {
      final isIPv6 = ip.contains(':') && !ip.contains('.');
      final status = isIPv6
          ? await DnsService.testDnsIPv6(ip)
          : await DnsService.testDns(ip);
      if (status != null && status.isReachable == true && status.ping > 0) {
        return status.ping;
      }
      return -1;
    } catch (_) {
      return -1;
    }
  }

  static Future<Map<String, int>> testAllDns({
    required BuildContext context,
    required List dnsRecords,
    required String sortType,
    required Function sortDnsRecords,
    bool auto = false,
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
  }) async {
    cancelRequested = false;
    Map<String, int> pingCache = {};
    if (dnsRecords.isEmpty) return pingCache;
    if (!auto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('در حال تست همه DNSها...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    if (setTestDialogOpen != null) setTestDialogOpen(true);
    if (setCancelTest != null) setCancelTest(false);
    final List<String> results = [];
    pingCache.clear();
    final List<Future<Map<String, dynamic>>> futures = [];
    for (final record in dnsRecords) {
      if (cancelRequested) break;
      final ip1 = record.ip1;
      final ip2 = record.ip2;
      // Only test IPv4 addresses, skip others
      final ipv4Regex = RegExp(
        r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      );
      if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
        futures.add(
          Future.value({
            'id': record.id,
            'label': record.label,
            'ping1': -1,
            'isReachable1': false,
            'ping2': -1,
            'isReachable2': false,
          }),
        );
        continue;
      }
      futures.add(
        (() async {
          if (cancelRequested)
            return {
              'id': record.id,
              'label': record.label,
              'ping1': -1,
              'isReachable1': false,
              'ping2': -1,
              'isReachable2': false,
            };
          final status1 = await DnsService.testDns(ip1);
          final status2 = await DnsService.testDns(ip2);
          return {
            'id': record.id,
            'label': record.label,
            'ping1': status1.ping,
            'isReachable1': status1.isReachable,
            'ping2': status2.ping,
            'isReachable2': status2.isReachable,
          };
        })(),
      );
    }
    final pingResults = await Future.wait(futures);
    for (int i = 0; i < pingResults.length; i++) {
      final r = pingResults[i];
      pingCache[r['id'] + '_1'] = r['ping1'];
      pingCache[r['id'] + '_2'] = r['ping2'];
      results.add(
        '${i + 1}. ${r['label']}\nDNS1: ${r['isReachable1'] ? '✅' : '❌'}  (پینگ: ${r['ping1'] > 0 ? r['ping1'] : '---'} ms)\nDNS2: ${r['isReachable2'] ? '✅' : '❌'}  (پینگ: ${r['ping2'] > 0 ? r['ping2'] : '---'} ms)',
      );
    }
    if (sortType == 'ping') {
      sortDnsRecords();
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_ping_cache', jsonEncode(pingCache));
    prefs.setStringList(
      'cached_dns_order',
      dnsRecords.map((e) => e.id.toString()).toList().cast<String>(),
    );
    if (!mounted) {
      if (setTestDialogOpen != null) setTestDialogOpen(false);
      if (setCancelTest != null) setCancelTest(false);
      return pingCache;
    }
    if (!auto && showDialogCallback != null) {
      showDialogCallback(results);
    }
    if (setTestDialogOpen != null) setTestDialogOpen(false);
    if (setCancelTest != null) setCancelTest(false);
    return pingCache;
  }
}
