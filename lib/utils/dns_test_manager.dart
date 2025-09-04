import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firedns/api/models/dns_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dns_ping_helper.dart';

class DnsTestManager {
  static bool _sequentialTestStopped = false;
  static const int timeout = 2; // timeout به ثانیه
  static const int maxConcurrentTests = 200; // حداکثر تست همزمان
  static const Duration cacheExpiration =
      Duration(hours: 48); // مدت اعتبار کش (هر 48 ساعت)
  static const Duration throttleInterval =
      Duration(seconds: 5); // حداقل فاصله بین تست‌ها

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
        return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
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
    // کش قبلی را بارگذاری کن
    final oldCacheJson = prefs.getString('ping_cache');
    Map<String, dynamic> oldCache = {};
    if (oldCacheJson != null) {
      try {
        oldCache = Map<String, dynamic>.from(json.decode(oldCacheJson));
      } catch (_) {}
    }
    // فقط مقادیر جدید را جایگزین کن، بقیه را نگه دار
    oldCache.addAll(cache);
    await prefs.setString('ping_cache', json.encode(oldCache));
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
        final result = await DnsPingHelper.ping(ip)
            .timeout(const Duration(seconds: timeout));
        if (result >= 0) {
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
  static void stopSequentialTest() {
    _sequentialTestStopped = true;
  }

  static void resetSequentialTest() {
    _sequentialTestStopped = false;
  }

  static Future<Map<String, int>> testMultipleDns(
    List<DnsRecord> records, {
    bool showProgress = true,
    Function(double)? onProgress,
  }) async {
    _sequentialTestStopped = false;
    if (!await checkNetworkStatus()) {
      throw Exception('No internet connection');
    }

    if (!canRunTest()) {
      throw Exception('Please wait before running another test');
    }

    _lastTestTime = DateTime.now();
    final results = <String, int>{};
    final chunks = <List<DnsRecord>>[];

    // تقسیم DNS ها به chunk های کوچکتر برای بهبود عملکرد
    for (var i = 0; i < records.length; i += maxConcurrentTests) {
      chunks.add(records.sublist(
          i,
          i + maxConcurrentTests > records.length
              ? records.length
              : i + maxConcurrentTests));
    }

    int completedTests = 0;
    final total = records.length * 2; // هر DNS دو آدرس دارد

    for (final chunk in chunks) {
      if (_sequentialTestStopped) break;

      final futures = <Future<void>>[];

      // تست DNS1 برای هر رکورد در chunk
      for (final record in chunk) {
        if (_sequentialTestStopped) break;

        futures.add(testSingleDns(record.ip1).then((ping) {
          results['${record.id}_1'] = ping ?? -1;
          completedTests++;
          if (showProgress && onProgress != null) {
            onProgress(completedTests / total);
          }
        }));

        // تست DNS2 اگر وجود داشته باشد
        if (record.ip2 != null && record.ip2!.isNotEmpty) {
          futures.add(testSingleDns(record.ip2!).then((ping) {
            results['${record.id}_2'] = ping ?? -1;
            completedTests++;
            if (showProgress && onProgress != null) {
              onProgress(completedTests / total);
            }
          }));
        } else {
          // اگر DNS2 وجود نداشته باشد، کامل شده حساب کن
          completedTests++;
          if (showProgress && onProgress != null) {
            onProgress(completedTests / total);
          }
        }
      }

      // منتظر تکمیل همه تست های این chunk باش
      await Future.wait(futures);

      // کمی استراحت بین chunk ها برای جلوگیری از فشار زیاد روی شبکه
      if (chunks.last != chunk && !_sequentialTestStopped) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    await savePingCache(results);
    return results;
  }
}
