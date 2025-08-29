import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:isolate';
import '../path/path.dart'; // Assuming DnsService and DnsStatus are defined here
import '../constants/dns_constants.dart'; // برای DnsConstants.methodChannel
import '../l10n/localization_extension.dart';

class DnsPingHelper {
  static const platform =
      MethodChannel(DnsConstants.methodChannel); // استفاده از channel موجود
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

  // تابع پینگ با Method Channel
  static Future<int> ping(String ip) async {
    try {
      final result = await platform.invokeMethod('ping', {'ip': ip});
      return result is int && result >= 0 ? result : -1;
    } catch (_) {
      return -1;
    }
  }

  // تابع اصلی تست پینگ در Isolate
  static Future<Map<String, dynamic>> _isolatePingTest(
      Map<String, dynamic> data) async {
    final records = data['dnsRecords'] as List;
    final pingCache = Map<String, int>.from(data['pingCache'] as Map);
    final results = <String>[];
    final allFutures = <Future<Map<String, dynamic>>>[];

    for (int index = 0; index < records.length; index++) {
      final record = records[index];
      final id = record['id'];
      final label = record['label'];
      final ip1 = record['ip1'];
      final ip2 = record['ip2'];

      allFutures.add(ping(ip1)
          .timeout(const Duration(seconds: 1))
          .then((ping1) => {
                'id': id,
                'which': 1,
                'ping': ping1,
                'index': index,
                'label': label,
              })
          .catchError((e) => {
                'id': id,
                'which': 1,
                'ping': -1,
                'index': index,
                'label': label,
              }));

      allFutures.add(ping(ip2)
          .timeout(const Duration(seconds: 1))
          .then((ping2) => {
                'id': id,
                'which': 2,
                'ping': ping2,
                'index': index,
                'label': label,
              })
          .catchError((e) => {
                'id': id,
                'which': 2,
                'ping': -1,
                'index': index,
                'label': label,
              }));
    }

    final allResponses = await Future.wait(allFutures);

    // گروه‌بندی نتایج بر اساس id
    final pingsPerId = <String, Map<int, int>>{};

    for (final resp in allResponses) {
      final id = resp['id'] as String;
      final which = resp['which'] as int;
      final ping = resp['ping'] as int;
      pingsPerId.putIfAbsent(id, () => {});
      pingsPerId[id]![which] = ping;
      pingCache['${id}_$which'] = ping;
    }

    // ساخت نتایج بر اساس ترتیب اصلی
    final sortedResponses = <Map<String, dynamic>>[];
    for (int index = 0; index < records.length; index++) {
      final record = records[index];
      final id = record['id'] as String;
      final pings = pingsPerId[id] ?? {1: -1, 2: -1};
      final ping1 = pings[1] ?? -1;
      final ping2 = pings[2] ?? -1;
      sortedResponses.add({
        'index': index,
        'label': record['label'],
        'ping1': ping1,
        'ping2': ping2,
        'isReachable1': ping1 >= 0,
        'isReachable2': ping2 >= 0,
        'error': ping1 == -1 && ping2 == -1,
      });
    }

    for (final response in sortedResponses) {
      if (response['error'] == true) {
        results.add(
          '${response["index"] + 1}. ${response["label"]}\n'
          'DNS1: ❌ (پینگ: --- ms)\nDNS2: ❌ (پینگ: --- ms)',
        );
      } else {
        final ping1 = response['ping1'] as int;
        final ping2 = response['ping2'] as int;
        final isReachable1 = response['isReachable1'] as bool;
        final isReachable2 = response['isReachable2'] as bool;
        results.add(
          '${response["index"] + 1}. ${response["label"]}\n'
          'DNS1: ${isReachable1 ? '✅' : '❌'} (پینگ: ${ping1 >= 0 ? ping1 : "---"} ms)\n'
          'DNS2: ${isReachable2 ? '✅' : '❌'} (پینگ: ${ping2 >= 0 ? ping2 : "---"} ms)',
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

  /// ریست کردن حالت لغو
  static void resetCancelState() {
    cancelRequested = false;
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
    Map<String, int> pingCache = await loadPingCache();

    if (dnsRecords.isEmpty) return pingCache;

    if (!auto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('testingAllDns')),
          duration: const Duration(seconds: 1),
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
        SnackBar(
          content: Text(context.tr('testingSequentialDns')),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    final List<String> results = [];
    final futures = <Future>[];

    // مرتب‌سازی DNS ها بر اساس پینگ قبلی
    List sortedRecords = List.from(dnsRecords);
    sortedRecords.sort((a, b) {
      int pingA1 = pingCache['${a.id}_1'] ?? 999999;
      int pingA2 = pingCache['${a.id}_2'] ?? 999999;
      int pingB1 = pingCache['${b.id}_1'] ?? 999999;
      int pingB2 = pingCache['${b.id}_2'] ?? 999999;

      int sortA = pingA1 >= 0
          ? pingA1
          : pingA2 >= 0
              ? pingA2
              : 999999;
      int sortB = pingB1 >= 0
          ? pingB1
          : pingB2 >= 0
              ? pingB2
              : 999999;
      return sortA.compareTo(sortB);
    });

    final ipv4Regex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

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

        final [ping1, ping2] = await Future.wait([
          ping(ip1).timeout(
            const Duration(seconds: 1),
            onTimeout: () => -1,
          ),
          ping(ip2).timeout(
            const Duration(seconds: 1),
            onTimeout: () => -1,
          ),
        ]);

        pingCache['${record.id}_1'] = ping1;
        pingCache['${record.id}_2'] = ping2;

        results.add(
          '${index + 1}. ${record.label}\nDNS1: ${ping1 >= 0 ? '✅' : '❌'} (پینگ: ${ping1 >= 0 ? ping1 : '---'} ms)\nDNS2: ${ping2 >= 0 ? '✅' : '❌'} (پینگ: ${ping2 >= 0 ? ping2 : '---'} ms)',
        );

        if (sortType == 'ping' && mounted) sortDnsRecords();

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
