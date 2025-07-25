import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DnsPingHelper {
  static bool _cancelTest = false;

  /// پینگ گرفتن از یک آی‌پی (برمی‌گرداند ms یا null اگر خطا)
  static Future<int?> ping(String ip) async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await Process.run('ping', [
        '-n',
        '1',
        ip,
      ], runInShell: true);
      stopwatch.stop();
      if (result.exitCode == 0 && result.stdout is String) {
        final out = result.stdout as String;
        final match = RegExp(r'Average = (\d+)ms').firstMatch(out);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
        // اگر خروجی معمول نبود، زمان اجرا را برگردان
        return stopwatch.elapsedMilliseconds;
      }
    } catch (_) {}
    return null;
  }

  /// تست پینگ همه DNSها و ذخیره کش
  static Future<Map<String, int>> testAllDns({
    required BuildContext context,
    required List dnsRecords,
    required String sortType,
    required Function sortDnsRecords,
    bool auto = false,
    required bool mounted,
    required Function(List<String>) showDialogCallback,
    required Function(bool) setTestDialogOpen,
  }) async {
    _cancelTest = false;
    setTestDialogOpen(true);
    Map<String, int> pingCache = {};
    List<String> results = [];

    // اجرای موازی پینگ‌ها
    final pingFutures = dnsRecords.map((record) async {
      if (!_cancelTest) {
        final ping1Future = ping(record.ip1);
        final ping2Future = ping(record.ip2);
        final ping1 = await ping1Future;
        final ping2 = await ping2Future;
        pingCache['${record.id}_1'] = ping1 ?? -1;
        pingCache['${record.id}_2'] = ping2 ?? -1;
        results.add(
          '${record.label}: ${ping1 ?? '---'} ms / ${ping2 ?? '---'} ms',
        );
        if (mounted) sortDnsRecords();
      } else {
        results.add('${record.label}: لغو شد');
      }
    }).toList();
    await Future.wait(pingFutures);

    setTestDialogOpen(false);
    showDialogCallback(results);
    await savePingCache(pingCache);
    return pingCache;
  }

  /// لغو تست پینگ
  static void cancelPingTest() {
    _cancelTest = true;
  }

  /// ذخیره کش پینگ به صورت JSON
  static Future<void> savePingCache(Map<String, int> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_ping_cache', jsonEncode(cache));
  }

  /// بارگذاری کش پینگ از JSON
  static Future<Map<String, int>> loadPingCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheStr = prefs.getString('cached_ping_cache');
    if (cacheStr != null) {
      final Map<String, dynamic> raw = jsonDecode(cacheStr);
      final Map<String, int> cache = {};
      raw.forEach((key, value) {
        cache[key] = value is int
            ? value
            : int.tryParse(value.toString()) ?? -1;
      });
      return cache;
    }
    return {};
  }

  /// بارگذاری ترتیب DNSها از کش
  static Future<List<String>> loadDnsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('cached_dns_order') ?? [];
  }
}
