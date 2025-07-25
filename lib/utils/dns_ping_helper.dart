import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../path/path.dart';
import 'dart:convert';

class DnsPingHelper {
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
    // اجرای موازی تست پینگ برای همه DNSها
    final futures = dnsRecords.map((record) async {
      final ip1 = record.ip1;
      final ip2 = record.ip2;
      // Simple check for IPv6: contains ':' and not '.'
      final isIPv6_1 = ip1.contains(':') && !ip1.contains('.');
      final isIPv6_2 = ip2.contains(':') && !ip2.contains('.');
      final status1 = isIPv6_1
          ? await DnsService.testDnsIPv6(ip1)
          : await DnsService.testDns(ip1);
      final status2 = isIPv6_2
          ? await DnsService.testDnsIPv6(ip2)
          : await DnsService.testDns(ip2);
      return {
        'id': record.id,
        'label': record.label,
        'ping1': status1.ping,
        'isReachable1': status1.isReachable,
        'ping2': status2.ping,
        'isReachable2': status2.isReachable,
      };
    }).toList();

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
