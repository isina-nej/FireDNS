import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/models/dns_record.dart';
import 'dns_ping_helper.dart';

class DnsTestManager {
  static const int timeout = 5; // timeout به ثانیه
  static const int maxConcurrentTests = 200; // حداکثر تست همزمان
  static const Duration cacheExpiration = Duration(hours: 1); // مدت اعتبار کش
  static const Duration throttleInterval =
      Duration(seconds: 30); // حداقل فاصله بین تست‌ها

  static DateTime? _lastTestTime;

  // بررسی وضعیت شبکه
  static Future<bool> checkNetworkStatus() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return false;
      }

      // تست اتصال به اینترنت
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      } on TimeoutException catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  // مدیریت کش نتایج
  static Future<Map<String, dynamic>> loadPingCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString('ping_cache');
    final lastUpdateStr = prefs.getString('ping_cache_update');

    if (cacheJson != null && lastUpdateStr != null) {
      try {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        if (DateTime.now().difference(lastUpdate) < cacheExpiration) {
          return Map<String, dynamic>.from(json.decode(cacheJson));
        }
      } catch (_) {}
    }
    return {};
  }

  static Future<void> savePingCache(Map<String, dynamic> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ping_cache', json.encode(cache));
    await prefs.setString(
        'ping_cache_update', DateTime.now().toIso8601String());
  }

  // مدیریت throttling
  static bool canRunTest() {
    if (_lastTestTime == null) return true;

    final timeSinceLastTest = DateTime.now().difference(_lastTestTime!);
    return timeSinceLastTest >= throttleInterval;
  }

  // تست DNS با مدیریت timeout و خطا
  static Future<int?> testSingleDns(String ip, {int retries = 2}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final result =
            await DnsPingHelper.ping(ip).timeout(Duration(seconds: timeout));
        if (result != null && result >= 0) {
          return result;
        }
      } catch (e) {
        if (i == retries - 1) return -1;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return -1;
  }

  // تست گروهی DNS‌ها با مدیریت تعداد همزمان
  static Future<Map<String, int>> testMultipleDns(
    List<DnsRecord> records, {
    bool showProgress = true,
    Function(double)? onProgress,
  }) async {
    if (!await checkNetworkStatus()) {
      throw Exception('No internet connection');
    }

    if (!canRunTest()) {
      throw Exception('Please wait before running another test');
    }

    _lastTestTime = DateTime.now();
    final results = <String, int>{};
    final chunks = <List<DnsRecord>>[];

    // تقسیم رکوردها به گروه‌های کوچکتر
    for (var i = 0; i < records.length; i += maxConcurrentTests) {
      chunks.add(records.sublist(
          i,
          i + maxConcurrentTests > records.length
              ? records.length
              : i + maxConcurrentTests));
    }

    int completedTests = 0;
    final total = records.length * 2; // برای هر رکورد دو IP تست می‌شود

    // تست هر گروه
    for (final chunk in chunks) {
      final futures = <Future<void>>[];

      for (final record in chunk) {
        // تست IP اول
        futures.add(testSingleDns(record.ip1).then((ping) {
          results['${record.id}_1'] = ping ?? -1;
          completedTests++;
          if (showProgress && onProgress != null) {
            onProgress(completedTests / total);
          }
        }));

        // تست IP دوم
        if (record.ip2.isNotEmpty) {
          futures.add(testSingleDns(record.ip2).then((ping) {
            results['${record.id}_2'] = ping ?? -1;
            completedTests++;
            if (showProgress && onProgress != null) {
              onProgress(completedTests / total);
            }
          }));
        }
      }

      // انتظار برای تکمیل تست‌های این گروه
      await Future.wait(futures);

      // مکث کوتاه بین گروه‌ها
      if (chunks.last != chunk) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // ذخیره نتایج در کش
    await savePingCache(results);

    return results;
  }
}
