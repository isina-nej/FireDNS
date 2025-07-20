import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/dns_status.dart';
import '../services/dns_service.dart';
import '../constants/dns_constants.dart';

/// سرویس مدیریت پینگ خودکار
class AutoPingService {
  static Timer? _pingTimer;
  static bool _isEnabled = false;
  static int _intervalSeconds = DnsConstants.defaultPingInterval;

  // Stream controller برای نتایج پینگ
  static final _pingResultController =
      StreamController<Map<String, DnsStatus>>.broadcast();

  /// Stream نتایج پینگ
  static Stream<Map<String, DnsStatus>> get pingResultStream =>
      _pingResultController.stream;

  /// وضعیت فعال بودن پینگ اتوماتیک
  static bool get isEnabled => _isEnabled;

  /// فاصله زمانی پینگ (ثانیه)
  static int get intervalSeconds => _intervalSeconds;

  /// شروع پینگ خودکار
  static void start({
    required String dns1,
    required String dns2,
    int? intervalSeconds,
  }) {
    if (_isEnabled) {
      debugPrint('Auto ping is already running');
      return;
    }

    _intervalSeconds = intervalSeconds ?? DnsConstants.defaultPingInterval;
    _isEnabled = true;

    debugPrint('Starting auto ping with interval: ${_intervalSeconds}s');

    // پینگ فوری
    _performPing(dns1, dns2);

    // تنظیم تایمر
    _pingTimer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => _performPing(dns1, dns2),
    );
  }

  /// توقف پینگ خودکار
  static void stop() {
    if (!_isEnabled) {
      debugPrint('Auto ping is not running');
      return;
    }

    debugPrint('Stopping auto ping');
    _pingTimer?.cancel();
    _pingTimer = null;
    _isEnabled = false;
  }

  /// تغییر فاصله زمانی پینگ
  static void changeInterval(int newIntervalSeconds, String dns1, String dns2) {
    if (newIntervalSeconds < 5) {
      debugPrint(
        'Invalid interval: $newIntervalSeconds (minimum is 5 seconds)',
      );
      return;
    }

    _intervalSeconds = newIntervalSeconds;

    if (_isEnabled) {
      // راه‌اندازی مجدد با فاصله جدید
      stop();
      start(dns1: dns1, dns2: dns2, intervalSeconds: newIntervalSeconds);
    }
  }

  /// انجام پینگ
  static Future<void> _performPing(String dns1, String dns2) async {
    try {
      debugPrint('Performing auto ping: $dns1, $dns2');

      final List<Future<DnsStatus>> futures = [];
      final List<String> dnsAddresses = [];

      if (dns1.isNotEmpty) {
        futures.add(DnsService.testDns(dns1));
        dnsAddresses.add(dns1);
      }

      if (dns2.isNotEmpty) {
        futures.add(DnsService.testDns(dns2));
        dnsAddresses.add(dns2);
      }

      if (futures.isEmpty) {
        debugPrint('No valid DNS addresses for ping');
        return;
      }

      final results = await Future.wait(futures);
      final pingResults = <String, DnsStatus>{};

      for (int i = 0; i < results.length; i++) {
        pingResults[dnsAddresses[i]] = results[i];
      }

      debugPrint('Auto ping results: $pingResults');

      if (!_pingResultController.isClosed) {
        _pingResultController.add(pingResults);
      }
    } catch (e) {
      debugPrint('Error in auto ping: $e');
      if (!_pingResultController.isClosed) {
        _pingResultController.addError(e);
      }
    }
  }

  /// پینگ دستی
  static Future<Map<String, DnsStatus>> performManualPing(
    String dns1,
    String dns2,
  ) async {
    debugPrint('Performing manual ping: $dns1, $dns2');

    final List<Future<DnsStatus>> futures = [];
    final List<String> dnsAddresses = [];

    if (dns1.isNotEmpty) {
      futures.add(DnsService.testDns(dns1));
      dnsAddresses.add(dns1);
    }

    if (dns2.isNotEmpty) {
      futures.add(DnsService.testDns(dns2));
      dnsAddresses.add(dns2);
    }

    if (futures.isEmpty) {
      return {};
    }

    final results = await Future.wait(futures);
    final pingResults = <String, DnsStatus>{};

    for (int i = 0; i < results.length; i++) {
      pingResults[dnsAddresses[i]] = results[i];
    }

    debugPrint('Manual ping results: $pingResults');

    // ارسال نتیجه به stream
    if (!_pingResultController.isClosed) {
      _pingResultController.add(pingResults);
    }

    return pingResults;
  }

  /// بستن سرویس
  static Future<void> dispose() async {
    debugPrint('Disposing auto ping service');
    stop();
    await _pingResultController.close();
  }

  /// تنظیم مجدد سرویس
  static void reset() {
    stop();
    _intervalSeconds = DnsConstants.defaultPingInterval;
  }
}
