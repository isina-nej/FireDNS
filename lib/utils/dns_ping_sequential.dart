import 'package:flutter/material.dart';
import '../path/path.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dns_ping_base.dart';

class DnsPingSequential {
  static Future<Map<String, int>> test({
    required BuildContext context,
    required List<DnsRecord> dnsRecords,
    required Function sortDnsRecords,
    String sortType = 'ping',
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
    Function(String, String, int)? onPingResult,
  }) async {
    DnsPingBase.cancelRequested = false;
    final pingCache = <String, int>{};
    if (dnsRecords.isEmpty) return pingCache;

    debugPrint('Starting sequential DNS test for ${dnsRecords.length} records');
    setCancelTest?.call(false);
    final results = <String>[];

    for (final record in dnsRecords) {
      if (DnsPingBase.cancelRequested) break;

      final ip1 = record.ip1;
      final ip2 = record.ip2;

      if (!DnsPingBase.ipv4Regex.hasMatch(ip1) ||
          !DnsPingBase.ipv4Regex.hasMatch(ip2)) {
        pingCache['${record.id}_1'] = -1;
        pingCache['${record.id}_2'] = -1;
        results.add('${record.label}\nDNS1: ❌ (--- ms)\nDNS2: ❌ (--- ms)');
        continue;
      }

      // Test DNS1 with optimized ping
      debugPrint('Testing DNS1: ${record.label} (${ip1})');
      final ping1 = await DnsPingBase.optimizedPing(ip1);
      if (DnsPingBase.cancelRequested) break;
      pingCache['${record.id}_1'] = ping1;

      // Notify about DNS1 result
      onPingResult?.call(record.id, "1", ping1);

      // Update UI immediately after testing DNS1
      if (mounted) {
        sortDnsRecords();
        // Save partial results
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_ping_cache', jsonEncode(pingCache));

        // Show intermediate result for DNS1
        if (showDialogCallback != null) {
          final intermediateMessage = '${record.label}\n'
              'DNS1: ${ping1 > 0 ? "✅ ($ping1 ms)" : "❌ (--- ms)"}\n'
              'DNS2: pending...';
          showDialogCallback([intermediateMessage]);
        }
      }

      // Test DNS2 with optimized ping
      debugPrint('Testing DNS2: ${record.label} (${ip2})');
      final ping2 = await DnsPingBase.optimizedPing(ip2);
      if (DnsPingBase.cancelRequested) break;
      pingCache['${record.id}_2'] = ping2;

      // Notify about DNS2 result
      onPingResult?.call(record.id, "2", ping2);

      // Update UI immediately after testing DNS2
      if (mounted) {
        sortDnsRecords();
        // Save results after DNS2
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      }

      final message = '${record.label}\n'
          'DNS1: ${ping1 > 0 ? "✅ ($ping1 ms)" : "❌ (--- ms)"}\n'
          'DNS2: ${ping2 > 0 ? "✅ ($ping2 ms)" : "❌ (--- ms)"}';
      results.add(message);
      debugPrint(
          'Result for ${record.label}: DNS1=${ping1}ms, DNS2=${ping2}ms');

      // Save results after each DNS pair
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
    }

    // Final sorting and saving
    if (!DnsPingBase.cancelRequested) {
      if (sortType == 'ping' && mounted) {
        sortDnsRecords();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      await prefs.setStringList(
          'cached_dns_order', dnsRecords.map((e) => e.id.toString()).toList());
    }

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);

    if (showDialogCallback != null && mounted) {
      showDialogCallback(results);
    }

    return pingCache;
  }
}
