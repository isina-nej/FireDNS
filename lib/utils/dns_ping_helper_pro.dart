import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../path/path.dart';
import 'dart:convert';

class DnsPingHelperPro {
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
      final ip = record.ip1;
      // Simple check for IPv6: contains ':' and not '.'
      final isIPv6 = ip.contains(':') && !ip.contains('.');
      final status = isIPv6
          ? await DnsService.testDnsIPv6(ip)
          : await DnsService.testDns(ip);
      return {
        'id': record.id,
        'label': record.label,
        'ping': status.ping,
        'isReachable': status.isReachable,
      };
    }).toList();

    final pingResults = await Future.wait(futures);

    for (int i = 0; i < pingResults.length; i++) {
      final r = pingResults[i];
      pingCache[r['id']] = r['ping'];
      results.add(
        '${i + 1}. ${r['label']}: ${r['isReachable'] ? '✅' : '❌'}  (پینگ: ${r['ping'] > 0 ? r['ping'] : '---'} ms)',
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
