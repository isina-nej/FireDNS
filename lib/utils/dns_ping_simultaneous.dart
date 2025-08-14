import 'package:flutter/material.dart';
import '../path/path.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dns_ping_base.dart';

class DnsPingSimultaneous {
  static Future<Map<String, int>> test({
    required BuildContext context,
    required List<DnsRecord> dnsRecords,
    required Function sortDnsRecords,
    String sortType = 'ping',
    bool auto = false,
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
    Function(String, String, int)? onPingResult,
  }) async {
    DnsPingBase.cancelRequested = false;
    final pingCache = <String, int>{};
    if (dnsRecords.isEmpty) return pingCache;

    if (!auto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('در حال تست همه DNSها به صورت همزمان...'),
            duration: Duration(seconds: 1)),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    final results = <String>[];

    // تست همه DNS ها به صورت همزمان
    final futures = dnsRecords.map((record) async {
      if (DnsPingBase.cancelRequested) return;

      final ip1 = record.ip1;
      final ip2 = record.ip2;

      if (!DnsPingBase.ipv4Regex.hasMatch(ip1) ||
          !DnsPingBase.ipv4Regex.hasMatch(ip2)) {
        pingCache['${record.id}_1'] = -1;
        pingCache['${record.id}_2'] = -1;
        return;
      }

      // تست همزمان هر دو IP با optimizedPing
      final [ping1, ping2] = await Future.wait([
        DnsPingBase.optimizedPing(ip1),
        DnsPingBase.optimizedPing(ip2),
      ]);

      if (!DnsPingBase.cancelRequested) {
        pingCache['${record.id}_1'] = ping1;
        pingCache['${record.id}_2'] = ping2;

        // Notify about results
        onPingResult?.call(record.id, "1", ping1);
        onPingResult?.call(record.id, "2", ping2);

        results.add(
          '${record.label}\n'
          'DNS1: ${ping1 > 0 ? "✅ ($ping1 ms)" : "❌ (--- ms)"}\n'
          'DNS2: ${ping2 > 0 ? "✅ ($ping2 ms)" : "❌ (--- ms)"}',
        );

        if (sortType == 'ping' && mounted) {
          sortDnsRecords();
        }
      }
    }).toList();

    await Future.wait(futures);

    if (!DnsPingBase.cancelRequested) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
    }
    // }

    if (!DnsPingBase.cancelRequested) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      await prefs.setStringList(
          'cached_dns_order', dnsRecords.map((e) => e.id.toString()).toList());
    }

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);

    if (!auto && showDialogCallback != null && mounted) {
      showDialogCallback(results);
    }

    return pingCache;
  }
}
