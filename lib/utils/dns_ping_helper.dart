import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:isolate';
import '../path/path.dart'; // Assuming DnsService and DnsStatus are defined here

class DnsPingHelper {
  static bool cancelRequested = false;
  static int testCount = 5; // تعداد تست برای تست پیشرفته

  // ساختار داده برای انتقال به Isolate
  static Map<String, dynamic> _createIsolateData(
    List<dynamic> dnsRecords,
    Map<String, int> initialPingCache,
  ) {
    return {
      'dnsRecords': dnsRecords
          .map((r) => {
                'id': r.id,
                'label': r.label,
                'ip1': r.ip1,
                'ip2': r.ip2,
              })
          .toList(),
      'pingCache': initialPingCache,
    };
  }

  // تابع اصلی تست پینگ در Isolate
  static Future<Map<String, dynamic>> _isolatePingTest(
      Map<String, dynamic> data) async {
    final records = data['dnsRecords'] as List;
    final pingCache = Map<String, int>.from(data['pingCache'] as Map);
    final results = <String>[];
    final futures = <Future>[];

    for (int index = 0; index < records.length; index++) {
      final record = records[index];
      final ip1 = record['ip1'];
      final ip2 = record['ip2'];

      futures.add(Future(() async {
        try {
          final dnsResults = await Future.wait([
            DnsService.testDns(ip1).timeout(const Duration(seconds: 2)),
            DnsService.testDns(ip2).timeout(const Duration(seconds: 2)),
          ]);

          pingCache['${record["id"]}_1'] = dnsResults[0].ping;
          pingCache['${record["id"]}_2'] = dnsResults[1].ping;

          return {
            'index': index,
            'label': record['label'],
            'status1': dnsResults[0],
            'status2': dnsResults[1],
          };
        } catch (e) {
          pingCache['${record["id"]}_1'] = -1;
          pingCache['${record["id"]}_2'] = -1;
          return {
            'index': index,
            'label': record['label'],
            'error': true,
          };
        }
      }));
    }

    final responses = await Future.wait(futures);
    responses.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    for (final response in responses) {
      if (response['error'] == true) {
        results.add(
          '${response["index"] + 1}. ${response["label"]}\n'
          'DNS1: ❌ (پینگ: --- ms)\nDNS2: ❌ (پینگ: --- ms)',
        );
      } else {
        final status1 = response['status1'];
        final status2 = response['status2'];
        results.add(
          '${response["index"] + 1}. ${response["label"]}\n'
          'DNS1: ${status1.isReachable ? '✅' : '❌'} (پینگ: ${status1.ping > 0 ? status1.ping : "---"} ms)\n'
          'DNS2: ${status2.isReachable ? '✅' : '❌'} (پینگ: ${status2.ping > 0 ? status2.ping : "---"} ms)',
        );
      }
    }

    return {
      'pingCache': pingCache,
      'results': results,
    };
  }

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

  /// لغو تست پینگ
  static void cancelPingTest() {
    cancelRequested = true;
  }

  /// تست پینگ یک IP (IPv4 یا IPv6) و بازگشت مقدار پینگ یا -1 در صورت عدم دسترسی
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

  static Future<Map<String, int>> testAllDns({
    required BuildContext context,
    required List dnsRecords,
    required String sortType,
    required Function sortDnsRecords,
    bool auto = false,
    required bool mounted,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
  }) async {
    cancelRequested = false;
    Map<String, int> pingCache = await loadPingCache(); // Load existing cache

    if (dnsRecords.isEmpty) return pingCache;

    if (!auto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('در حال تست همه DNSها...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    // راه‌اندازی Isolate برای تست پینگ
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      (SendPort sendPort) async {
        final data = _createIsolateData(dnsRecords, pingCache);
        final result = await _isolatePingTest(data);
        sendPort.send(result);
      },
      receivePort.sendPort,
    );

    // دریافت نتایج از Isolate
    final response = await receivePort.first as Map<String, dynamic>;
    final List<String> results = List<String>.from(response['results']);
    pingCache = Map<String, int>.from(response['pingCache']);

    // پایان دادن به Isolate
    receivePort.close();
    isolate.kill();

    // ذخیره نتایج در SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_ping_cache', jsonEncode(pingCache));
    prefs.setStringList(
      'cached_dns_order',
      dnsRecords.map((e) => e.id.toString()).toList(),
    );

    if (sortType == 'ping' && mounted) {
      sortDnsRecords();
    }

    if (!mounted) {
      setTestDialogOpen?.call(false);
      setCancelTest?.call(false);
      return pingCache;
    }

    if (!auto && showDialogCallback != null) {
      showDialogCallback(results);
    }

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);
    return pingCache;
  }

  /// تست ترتیبی DNS ها بر اساس کمترین پینگ در تست قبلی
  static Future<Map<String, int>> testSequentialDns({
    required BuildContext context,
    required List dnsRecords,
    required String sortType,
    required Function sortDnsRecords,
    required int testCount,
    required bool mounted,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
  }) async {
    cancelRequested = false;
    Map<String, int> pingCache = await loadPingCache();
    if (dnsRecords.isEmpty) return pingCache;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('در حال تست ترتیبی DNSها...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    final List<String> results = [];

    // مرتب‌سازی DNS ها بر اساس پینگ قبلی
    List sortedRecords = List.from(dnsRecords);
    sortedRecords.sort((a, b) {
      int pingA1 = pingCache['${a.id}_1'] ?? 999999;
      int pingA2 = pingCache['${a.id}_2'] ?? 999999;
      int pingB1 = pingCache['${b.id}_1'] ?? 999999;
      int pingB2 = pingCache['${b.id}_2'] ?? 999999;

      int sortA = pingA1 >= 0 ? pingA1 : pingA2 >= 0 ? pingA2 : 999999;
      int sortB = pingB1 >= 0 ? pingB1 : pingB2 >= 0 ? pingB2 : 999999;
      return sortA.compareTo(sortB);
    });

    final ipv4Regex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    final futures = <Future>[];

    // تست هر DNS به ترتیب اما به صورت موازی برای سرعت بیشتر
    for (int i = 0; i < sortedRecords.length && i < testCount; i++) {
      if (cancelRequested) break;

      final record = sortedRecords[i];
      final ip1 = record.ip1;
      final ip2 = record.ip2;
      final index = i;

      futures.add(Future(() async {
        if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
          pingCache['${record.id}_1'] = -1;
          pingCache['${record.id}_2'] = -1;
          results.add(
            '${index + 1}. ${record.label}\nDNS1: ❌ (پینگ: --- ms)\nDNS2: ❌ (پینگ: --- ms)',
          );
          if (sortType == 'ping' && mounted) sortDnsRecords();
          return;
        }

        // تست DNS1 و DNS2 به صورت همزمان
        final [status1, status2] = await Future.wait([
          DnsService.testDns(ip1).timeout(
            const Duration(seconds: 2),
            onTimeout: () => DnsStatus(-1, false),
          ),
          DnsService.testDns(ip2).timeout(
            const Duration(seconds: 2),
            onTimeout: () => DnsStatus(-1, false),
          ),
        ]);

        pingCache['${record.id}_1'] = status1.ping;
        pingCache['${record.id}_2'] = status2.ping;

        results.add(
          '${index + 1}. ${record.label}\nDNS1: ${status1.isReachable ? '✅' : '❌'} (پینگ: ${status1.ping > 0 ? status1.ping : '---'} ms)\nDNS2: ${status2.isReachable ? '✅' : '❌'} (پینگ: ${status2.ping > 0 ? status2.ping : '---'} ms)',
        );

        if (sortType == 'ping' && mounted) sortDnsRecords();

        // ذخیره موقت نتایج
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      }));
    }

    await Future.wait(futures);

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_ping_cache', jsonEncode(pingCache));

    if (!mounted) {
      setTestDialogOpen?.call(false);
      setCancelTest?.call(false);
      return pingCache;
    }

    showDialogCallback?.call(results);

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);

    return pingCache;
  }
}