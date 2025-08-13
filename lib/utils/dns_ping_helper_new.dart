import 'package:flutter/material.dart';
import '../path/path.dart'; // Assuming this is where DnsService and DnsStatus are defined
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DnsPingHelper {
  static bool cancelRequested = false;
  static int defaultTestCount = 5; // Default number of tests for advanced mode

  /// Loads the ping cache from SharedPreferences.
  static Future<Map<String, int>> loadPingCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_ping_cache');
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? -1));
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
      final status = isIPv6 ? await DnsService.testDnsIPv6(ip) : await DnsService.testDns(ip);
      return status.isReachable && status.ping > 0 ? status.ping : -1;
    } catch (_) {
      return -1;
    }
  }

  /// Test 1: Ping all DNS servers simultaneously in batches.
  /// Returns a map of ping results.
  static Future<Map<String, int>> testSimultaneous({
    required BuildContext context,
    required List<DnsRecord> dnsRecords, // Assuming dnsRecords is a list of DnsRecord objects
    required Function sortDnsRecords,
    String sortType = 'ping',
    bool auto = false,
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
  }) async {
    cancelRequested = false;
    final pingCache = <String, int>{};
    if (dnsRecords.isEmpty) return pingCache;

    if (!auto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال تست همه DNSها به صورت همزمان...'), duration: Duration(seconds: 1)),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    const batchSize = 5; // Increased batch size for better concurrency, adjust based on device limits
    final ipv4Regex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    final results = <String>[];

    for (var i = 0; i < dnsRecords.length; i += batchSize) {
      if (cancelRequested) break;

      final batch = dnsRecords.skip(i).take(batchSize).toList();
      final futures = batch.map((record) async {
        if (cancelRequested) return;

        final ip1 = record.ip1;
        final ip2 = record.ip2;

        if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
          pingCache['${record.id}_1'] = -1;
          pingCache['${record.id}_2'] = -1;
          return;
        }

        // Ping both IPs concurrently
        final [ping1, ping2] = await Future.wait([
          ping(ip1).timeout(const Duration(seconds: 5), onTimeout: () => -1),
          ping(ip2).timeout(const Duration(seconds: 5), onTimeout: () => -1),
        ]);

        if (!cancelRequested) {
          pingCache['${record.id}_1'] = ping1;
          pingCache['${record.id}_2'] = ping2;

          results.add(
            '${record.label}\n'
            'DNS1: ${ping1 > 0 ? '✅ ($ping1 ms)' : '❌ (--- ms)'}\n'
            'DNS2: ${ping2 > 0 ? '✅ ($ping2 ms)' : '❌ (--- ms)'}',
          );

          if (sortType == 'ping' && mounted) {
            sortDnsRecords();
          }
        }
      }).toList();

      await Future.wait(futures);

      if (!cancelRequested) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      }
    }

    if (!cancelRequested) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      await prefs.setStringList('cached_dns_order', dnsRecords.map((e) => e.id.toString()).toList());
    }

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);

    if (!auto && showDialogCallback != null && mounted) {
      showDialogCallback(results);
    }

    return pingCache;
  }

  /// Test 2: Ping DNS servers sequentially one by one, store results, then sort by ascending ping.
  static Future<Map<String, int>> testSequential({
    required BuildContext context,
    required List<DnsRecord> dnsRecords,
    required Function sortDnsRecords,
    String sortType = 'ping',
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
  }) async {
    cancelRequested = false;
    final pingCache = <String, int>{};
    if (dnsRecords.isEmpty) return pingCache;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال تست ترتیبی DNSها...'), duration: Duration(seconds: 1)),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    final results = <String>[];
    final ipv4Regex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

    for (final record in dnsRecords) {
      if (cancelRequested) break;

      final ip1 = record.ip1;
      final ip2 = record.ip2;

      if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
        pingCache['${record.id}_1'] = -1;
        pingCache['${record.id}_2'] = -1;
        results.add('${record.label}\nDNS1: ❌ (--- ms)\nDNS2: ❌ (--- ms)');
        continue;
      }

      // Ping sequentially
      final ping1 = await ping(ip1).timeout(const Duration(seconds: 5), onTimeout: () => -1);
      if (cancelRequested) break;
      pingCache['${record.id}_1'] = ping1;

      final ping2 = await ping(ip2).timeout(const Duration(seconds: 5), onTimeout: () => -1);
      if (cancelRequested) break;
      pingCache['${record.id}_2'] = ping2;

      results.add(
        '${record.label}\n'
        'DNS1: ${ping1 > 0 ? '✅ ($ping1 ms)' : '❌ (--- ms)'}\n'
        'DNS2: ${ping2 > 0 ? '✅ ($ping2 ms)' : '❌ (--- ms)'}',
      );

      // Save after each DNS
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
    }

    if (!cancelRequested) {
      // Sort dnsRecords by min ping ascending
      dnsRecords.sort((a, b) {
        final minA = [pingCache['${a.id}_1'] ?? 9999, pingCache['${a.id}_2'] ?? 9999].reduce((x, y) => x < y ? x : y);
        final minB = [pingCache['${b.id}_1'] ?? 9999, pingCache['${b.id}_2'] ?? 9999].reduce((x, y) => x < y ? x : y);
        return minA.compareTo(minB);
      });

      if (sortType == 'ping' && mounted) {
        sortDnsRecords();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      await prefs.setStringList('cached_dns_order', dnsRecords.map((e) => e.id.toString()).toList());
    }

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);

    if (showDialogCallback != null && mounted) {
      showDialogCallback(results);
    }

    return pingCache;
  }

  /// Test 3: Advanced test - Ping all DNS servers simultaneously multiple times (user-specified count).
  /// Calculates average ping, packet loss, and scores for each DNS.
  /// Returns pingCache and advancedResults.
  static Future<Map<String, dynamic>> testAdvanced({
    required BuildContext context,
    required List<DnsRecord> dnsRecords,
    required Function sortDnsRecords,
    required int testCount,
    String sortType = 'ping',
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
  }) async {
    cancelRequested = false;
    final pingCache = <String, int>{};
    final advancedResults = <String, Map<String, dynamic>>{};
    if (dnsRecords.isEmpty) return {'pingCache': pingCache, 'advancedResults': advancedResults};

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('در حال تست پیشرفته DNSها ($testCount بار)...'), duration: const Duration(seconds: 1)),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    final results = <String>[];
    final ipv4Regex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

    // Initialize data structures
    final testData = <String, Map<String, dynamic>>{};
    for (final record in dnsRecords) {
      final ip1 = record.ip1;
      final ip2 = record.ip2;

      if (!ipv4Regex.hasMatch(ip1) || !ipv4Regex.hasMatch(ip2)) {
        pingCache['${record.id}_1'] = -1;
        pingCache['${record.id}_2'] = -1;
        advancedResults[record.id.toString()] = {
          'label': record.label,
          'ip1': ip1,
          'ip2': ip2,
          'avgPing1': -1.0,
          'avgPing2': -1.0,
          'packetLoss1': 100.0,
          'packetLoss2': 100.0,
          'score1': 0.0,
          'score2': 0.0,
          'allPings1': <int>[],
          'allPings2': <int>[],
        };
        continue;
      }

      testData[record.id.toString()] = {
        'label': record.label,
        'ip1': ip1,
        'ip2': ip2,
        'pings1': <int>[],
        'pings2': <int>[],
        'successCount1': 0,
        'successCount2': 0,
      };
    }

    // Perform testCount rounds, pinging all DNS simultaneously each round
    for (var round = 0; round < testCount; round++) {
      if (cancelRequested) break;

      final futures = dnsRecords.map((record) async {
        final data = testData[record.id.toString()];
        if (data == null) return;

        // Ping both IPs concurrently per DNS
        final [ping1, ping2] = await Future.wait([
          ping(data['ip1']).timeout(const Duration(seconds: 5), onTimeout: () => -1),
          ping(data['ip2']).timeout(const Duration(seconds: 5), onTimeout: () => -1),
        ]);

        if (!cancelRequested) {
          if (ping1 > 0) {
            data['pings1'].add(ping1);
            data['successCount1'] += 1;
          }
          if (ping2 > 0) {
            data['pings2'].add(ping2);
            data['successCount2'] += 1;
          }

          // Update average temporarily for UI
          if (data['pings1'].isNotEmpty) {
            pingCache['${record.id}_1'] = (data['pings1'].reduce((a, b) => a + b) / data['pings1'].length).round();
          }
          if (data['pings2'].isNotEmpty) {
            pingCache['${record.id}_2'] = (data['pings2'].reduce((a, b) => a + b) / data['pings2'].length).round();
          }

          if (sortType == 'ping' && mounted) {
            sortDnsRecords();
          }
        }
      }).toList();

      await Future.wait(futures);

      // Save periodically
      if (round % 2 == 1 && !cancelRequested) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      }
    }

    if (!cancelRequested) {
      // Compute final results
      for (final entry in testData.entries) {
        final id = entry.key;
        final data = entry.value;

        final pings1 = data['pings1'] as List<int>;
        final pings2 = data['pings2'] as List<int>;
        final success1 = data['successCount1'] as int;
        final success2 = data['successCount2'] as int;

        final avgPing1 = pings1.isEmpty ? -1.0 : pings1.reduce((a, b) => a + b) / pings1.length;
        final avgPing2 = pings2.isEmpty ? -1.0 : pings2.reduce((a, b) => a + b) / pings2.length;

        final packetLoss1 = ((testCount - success1) / testCount) * 100;
        final packetLoss2 = ((testCount - success2) / testCount) * 100;

        // Scoring algorithm: 70% ping (linear from 70 at <50ms to 0 at >=500ms), 30% packet loss (linear from 30 at 0% to 0 at 100%)
        final pingScore1 = avgPing1 <= 0 ? 0.0 : (avgPing1 < 50 ? 70.0 : (avgPing1 >= 500 ? 0.0 : 70 - (avgPing1 - 50) * 70 / 450));
        final pingScore2 = avgPing2 <= 0 ? 0.0 : (avgPing2 < 50 ? 70.0 : (avgPing2 >= 500 ? 0.0 : 70 - (avgPing2 - 50) * 70 / 450));

        final lossScore1 = 30 - (packetLoss1 * 30 / 100);
        final lossScore2 = 30 - (packetLoss2 * 30 / 100);

        final score1 = pingScore1 + lossScore1;
        final score2 = pingScore2 + lossScore2;

        pingCache['${id}_1'] = avgPing1.round();
        pingCache['${id}_2'] = avgPing2.round();

        advancedResults[id] = {
          'label': data['label'],
          'ip1': data['ip1'],
          'ip2': data['ip2'],
          'avgPing1': avgPing1,
          'avgPing2': avgPing2,
          'packetLoss1': packetLoss1,
          'packetLoss2': packetLoss2,
          'score1': score1,
          'score2': score2,
          'allPings1': pings1,
          'allPings2': pings2,
        };

        results.add(
          '${data['label']}\n'
          'DNS1: ${avgPing1 > 0 ? avgPing1.toStringAsFixed(1) : '---'} ms, '
          'Packet Loss: ${packetLoss1.toStringAsFixed(1)}%, Score: ${score1.toStringAsFixed(1)}\n'
          'DNS2: ${avgPing2 > 0 ? avgPing2.toStringAsFixed(1) : '---'} ms, '
          'Packet Loss: ${packetLoss2.toStringAsFixed(1)}%, Score: ${score2.toStringAsFixed(1)}',
        );
      }

      if (sortType == 'ping' && mounted) {
        sortDnsRecords();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      await prefs.setString('advanced_dns_results', jsonEncode(advancedResults));
    }

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);

    if (showDialogCallback != null && mounted) {
      showDialogCallback(results);
    }

    return {'pingCache': pingCache, 'advancedResults': advancedResults};
  }
}