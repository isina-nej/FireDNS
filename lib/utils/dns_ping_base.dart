import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../path/path.dart';
import 'package:flutter/material.dart';

import 'dns_ping_sequential.dart';
import 'dns_ping_simultaneous.dart';
import 'dns_ping_advanced.dart';

class DnsPingBase {
  static bool cancelRequested = false;
  static int defaultTestCount = 5;
  static final _testResults = <String, int>{};
  static final _fastestResults = <String, int>{};

  static final ipv4Regex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

  static Future<Map<String, int>> runTest({
    required BuildContext context,
    required List<DnsRecord> dnsRecords,
    required Function sortDnsRecords,
    required String testType,
    int testCount = 5,
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
    Function(String, String, int)? onPingResult,
  }) async {
    switch (testType) {
      case 'sequential':
        return DnsPingSequential.test(
          context: context,
          dnsRecords: dnsRecords,
          sortDnsRecords: sortDnsRecords,
          sortType: 'ping',
          mounted: mounted,
          showDialogCallback: showDialogCallback,
          setTestDialogOpen: setTestDialogOpen,
          setCancelTest: setCancelTest,
          onPingResult: onPingResult,
        );
      case 'simultaneous':
        return DnsPingSimultaneous.test(
          context: context,
          dnsRecords: dnsRecords,
          sortDnsRecords: sortDnsRecords,
          sortType: 'ping',
          mounted: mounted,
          showDialogCallback: showDialogCallback,
          setTestDialogOpen: setTestDialogOpen,
          setCancelTest: setCancelTest,
          onPingResult: onPingResult,
        );
      case 'advanced':
        final result = await DnsPingAdvanced.test(
          context: context,
          dnsRecords: dnsRecords,
          sortDnsRecords: sortDnsRecords,
          testCount: testCount,
          sortType: 'ping',
          mounted: mounted,
          showDialogCallback: showDialogCallback,
          setTestDialogOpen: setTestDialogOpen,
          setCancelTest: setCancelTest,
          onPingResult: onPingResult,
        );
        return result['pingCache'] as Map<String, int>;
      default:
        return {};
    }
  }

  /// تست DNS با بهینه‌سازی برای سرعت
  static Future<int> optimizedPing(String ip) async {
    // تلاش برای بازیابی از کش سریع
    if (_fastestResults.containsKey(ip)) {
      return _fastestResults[ip]!;
    }

    // اولین پینگ
    final initialPing = await ping(ip);
    if (initialPing <= 0) {
      return -1;
    }

    _fastestResults[ip] = initialPing;

    // اگر پینگ خیلی خوب باشد (کمتر از 50ms)، همان را برگردان
    if (initialPing < 50) {
      return initialPing;
    }

    // در غیر این صورت، دو تست دیگر انجام بده و بهترین را برگردان
    final results = await Future.wait([
      ping(ip),
      ping(ip),
    ]);

    final validResults = results.where((p) => p > 0).toList();
    if (validResults.isEmpty) {
      return initialPing;
    }

    final bestPing = validResults.reduce((min, p) => p < min ? p : min);
    if (bestPing < _fastestResults[ip]!) {
      _fastestResults[ip] = bestPing;
    }

    return _fastestResults[ip]!;
  }

  /// پاک کردن نتایج کش شده
  static void clearCache() {
    _testResults.clear();
    _fastestResults.clear();
  }

  /// Loads the ping cache from SharedPreferences.
  static Future<Map<String, int>> loadPingCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_ping_cache');
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map((k, v) =>
          MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? -1));
    } catch (_) {
      return {};
    }
  }

  /// Loads the DNS order from SharedPreferences.
  static Future<List<String>> loadDnsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('cached_dns_order');
    return list ?? [];
  }

  /// Cancels the ongoing ping test.
  static void cancelPingTest() {
    cancelRequested = true;
  }

  /// Pings a single IP (IPv4 or IPv6) and returns the ping time or -1 if unreachable.
  static Future<int> ping(String ip) async {
    try {
      final isIPv6 = ip.contains(':') && !ip.contains('.');
      final status = isIPv6
          ? await DnsService.testDnsIPv6(ip)
          : await DnsService.testDns(ip);
      return status.isReachable && status.ping > 0 ? status.ping : -1;
    } catch (_) {
      return -1;
    }
  }
}
