import 'package:flutter/material.dart';
import '../path/path.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dns_ping_base.dart';

class DnsPingAdvanced {
  static Future<Map<String, dynamic>> test({
    required BuildContext context,
    required List<DnsRecord> dnsRecords,
    required Function sortDnsRecords,
    required int testCount,
    String sortType = 'ping',
    bool mounted = true,
    Function? showDialogCallback,
    Function? setTestDialogOpen,
    Function? setCancelTest,
    Function(String, String, int)? onPingResult,
  }) async {
    DnsPingBase.cancelRequested = false;
    final pingCache = <String, int>{};
    final advancedResults = <String, Map<String, dynamic>>{};
    if (dnsRecords.isEmpty)
      return {'pingCache': pingCache, 'advancedResults': advancedResults};

    debugPrint(
        'Starting advanced DNS test with count: $testCount for ${dnsRecords.length} DNS servers');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('در حال تست پیشرفته DNSها ($testCount بار)...'),
            duration: const Duration(seconds: 1)),
      );
    }

    setTestDialogOpen?.call(true);
    setCancelTest?.call(false);

    final results = <String>[];

    // Initialize test data structures
    final testData = <String, Map<String, dynamic>>{};
    for (final record in dnsRecords) {
      final ip1 = record.ip1;
      final ip2 = record.ip2;

      if (!DnsPingBase.ipv4Regex.hasMatch(ip1) ||
          !DnsPingBase.ipv4Regex.hasMatch(ip2)) {
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

    // Run test rounds
    for (var round = 0; round < testCount; round++) {
      debugPrint('Starting round ${round + 1} of $testCount');
      if (DnsPingBase.cancelRequested) break;

      final futures = testData.entries.map((entry) async {
        final data = entry.value;
        final ip1 = data['ip1'] as String;
        final ip2 = data['ip2'] as String;

        final [ping1, ping2] = await Future.wait([
          DnsPingBase.ping(ip1),
          DnsPingBase.ping(ip2),
        ]);

        if (!DnsPingBase.cancelRequested) {
          if (ping1 > 0) {
            data['pings1'].add(ping1);
            data['successCount1']++;
          }
          if (ping2 > 0) {
            data['pings2'].add(ping2);
            data['successCount2']++;
          }

          // Update average for UI updates
          if (mounted && sortType == 'ping') {
            if (data['pings1'].isNotEmpty) {
              final avgPing1 = data['pings1'].reduce((a, b) => a + b) /
                  data['pings1'].length;
              final roundedPing1 = avgPing1.round();
              pingCache['${entry.key}_1'] = roundedPing1;
              onPingResult?.call(entry.key, "1", roundedPing1);
            }
            if (data['pings2'].isNotEmpty) {
              final avgPing2 = data['pings2'].reduce((a, b) => a + b) /
                  data['pings2'].length;
              final roundedPing2 = avgPing2.round();
              pingCache['${entry.key}_2'] = roundedPing2;
              onPingResult?.call(entry.key, "2", roundedPing2);
            }
            sortDnsRecords();
          }
        }
      }).toList();

      await Future.wait(futures);

      // Save intermediate results
      if (round % 2 == 1 && !DnsPingBase.cancelRequested) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_ping_cache', jsonEncode(pingCache));
      }
    }

    // Calculate and save final results
    if (!DnsPingBase.cancelRequested) {
      for (final entry in testData.entries) {
        final id = entry.key;
        final data = entry.value;

        final pings1 = data['pings1'] as List<int>;
        final pings2 = data['pings2'] as List<int>;
        final success1 = data['successCount1'] as int;
        final success2 = data['successCount2'] as int;

        final avgPing1 = pings1.isEmpty
            ? -1.0
            : pings1.reduce((a, b) => a + b) / pings1.length;
        final avgPing2 = pings2.isEmpty
            ? -1.0
            : pings2.reduce((a, b) => a + b) / pings2.length;

        final packetLoss1 = ((testCount - success1) / testCount) * 100;
        final packetLoss2 = ((testCount - success2) / testCount) * 100;

        // Scoring algorithm
        final pingScore1 = avgPing1 <= 0
            ? 0.0
            : (avgPing1 < 50
                ? 70.0
                : (avgPing1 >= 500 ? 0.0 : 70 - (avgPing1 - 50) * 70 / 450));
        final pingScore2 = avgPing2 <= 0
            ? 0.0
            : (avgPing2 < 50
                ? 70.0
                : (avgPing2 >= 500 ? 0.0 : 70 - (avgPing2 - 50) * 70 / 450));

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
      await prefs.setString(
          'advanced_dns_results', jsonEncode(advancedResults));
    }

    setTestDialogOpen?.call(false);
    setCancelTest?.call(false);

    if (showDialogCallback != null && mounted) {
      showDialogCallback(results);
    }

    return {'pingCache': pingCache, 'advancedResults': advancedResults};
  }
}
