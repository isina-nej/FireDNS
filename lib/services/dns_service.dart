import 'dart:io';

import 'package:firedns/path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// نتیجه تغییر DNS
class DnsChangeResult {
  final bool success;
  final String message;
  final String errorCode;

  DnsChangeResult({
    required this.success,
    required this.message,
    this.errorCode = '',
  });
}

/// سرویس مدیریت DNS
class DnsService {
  static Future<DnsStatus> testDnsIPv6(String dns) async {
    try {
      final result = await _platform.invokeMethod('testDnsIPv6', {'dns': dns});
      LoggerService().debug('Raw ping result (IPv6): $result');
      if (result is Map) {
        final ping = (result['ping'] as int?) ?? -1;
        final isReachable = result['isReachable'] == true;
        return DnsStatus(ping, isReachable);
      }
    } catch (e) {
      debugPrint('Error in testDnsIPv6: $e');
    }
    return const DnsStatus(-1, false);
  }

  static const _platform = MethodChannel(DnsConstants.methodChannel);

  /// تست پینگ یک DNS
  static Future<DnsStatus> testDns(String dns) async {
    try {
      if (!DnsValidator.isValidDns(dns)) {
        debugPrint('Invalid DNS address: $dns');
        return const DnsStatus(-1, false);
      }

      debugPrint('Testing DNS: $dns');
      // جدا کردن اندروید و ویندوز
      if (defaultTargetPlatform == TargetPlatform.android) {
        final result = await _platform.invokeMethod('testDns', {'dns': dns});
        debugPrint('Raw ping result: $result');
        if (result is Map) {
          final ping = (result['ping'] as int?) ?? -1;
          final isReachable = (result['isReachable'] as bool?) ?? false;
          debugPrint(
            'Parsed ping result - ping: $ping, isReachable: $isReachable',
          );
          return DnsStatus(ping, isReachable);
        }
        debugPrint('Invalid result format: $result');
        return const DnsStatus(-1, false);
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        // اجرای دستور ping در ویندوز
        try {
          final result = await Process.run('ping', ['-n', '1', dns]);
          final output = result.stdout.toString();
          final reachable = output.contains('TTL=') || output.contains('ttl=');
          final pingMatch = RegExp(
            r'Time[=<]\s*(\d+)ms',
            caseSensitive: false,
          ).firstMatch(output);
          final ping = pingMatch != null ? int.parse(pingMatch.group(1)!) : -1;
          debugPrint('Windows ping output: $output');
          return DnsStatus(ping, reachable);
        } catch (e) {
          debugPrint('Windows ping error: $e');
          return const DnsStatus(-1, false);
        }
      } else {
        // سایر پلتفرم‌ها
        return const DnsStatus(-1, false);
      }
    } catch (e) {
      debugPrint('Error testing DNS: $e');
      return const DnsStatus(-1, false);
    }
  }

  // کلاس DnsChangeResult در بالای فایل تعریف شده است

  /// تغییر DNS سیستم
  static Future<DnsChangeResult> changeDns(String dns1, String dns2) async {
    try {
      // اعتبارسنجی DNS ها
      if (!DnsValidator.isValidDns(dns1)) {
        debugPrint('Invalid primary DNS: $dns1');
        return DnsChangeResult(
          success: false,
          message: DnsConstants.errorMessages['invalidDns1']!,
          errorCode: 'INVALID_PRIMARY_DNS',
        );
      }

      if (dns2.isNotEmpty && !DnsValidator.isValidDns(dns2)) {
        debugPrint('Invalid secondary DNS: $dns2');
        return DnsChangeResult(
          success: false,
          message: DnsConstants.errorMessages['invalidDns2']!,
          errorCode: 'INVALID_SECONDARY_DNS',
        );
      }

      // تست دسترسی DNS ها - اما اجازه ادامه بده حتی اگر در دسترس نباشند
      bool dns1Reachable = false;
      bool dns2Reachable = false;

      try {
        final dns1Status = await testDns(dns1);
        dns1Reachable = dns1Status.isReachable;
        if (!dns1Reachable) {
          debugPrint(
              'Warning: Primary DNS is not reachable: $dns1 (continuing anyway)');
        }

        if (dns2.isNotEmpty) {
          final dns2Status = await testDns(dns2);
          dns2Reachable = dns2Status.isReachable;
          if (!dns2Reachable) {
            debugPrint(
                'Warning: Secondary DNS is not reachable: $dns2 (continuing anyway)');
          }
        }
      } catch (e) {
        debugPrint('Error testing DNS reachability: $e (continuing anyway)');
      }

      // تغییر DNS - حتی اگر DNS ها در دسترس نباشند
      await _platform.invokeMethod('setDns', {'dns1': dns1, 'dns2': dns2});
      debugPrint('DNS changed successfully: $dns1, $dns2');

      // اگر DNS ها در دسترس نبودند، پیام هشدار نمایش بده
      if (!dns1Reachable || (dns2.isNotEmpty && !dns2Reachable)) {
        return DnsChangeResult(
          success: true,
          message: DnsConstants.errorMessages['vpnActivatedWithWarning'] ??
              "VPN activated, but DNS servers might not be reachable. Connection might be limited.",
        );
      } else {
        return DnsChangeResult(
          success: true,
          message: DnsConstants.errorMessages['vpnActivated']!,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Platform error changing DNS: ${e.message}');
      return DnsChangeResult(
        success: false,
        message: DnsConstants.errorMessages['vpnActivationError']!,
        errorCode: 'PLATFORM_ERROR',
      );
    } catch (e) {
      debugPrint('Error changing DNS: $e');
      return DnsChangeResult(
        success: false,
        message: DnsConstants.errorMessages['vpnActivationError']!,
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// توقف VPN
  static Future<bool> stopVpn() async {
    try {
      debugPrint('Stopping VPN...');
      await _platform.invokeMethod('stopDnsVpn');
      debugPrint('VPN stopped successfully');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Platform error stopping VPN: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error stopping VPN: $e');
      return false;
    }
  }

  /// دریافت وضعیت سرویس
  static Future<bool> getServiceStatus() async {
    try {
      final result = await _platform.invokeMethod('getServiceStatus');
      return result == true;
    } catch (e) {
      debugPrint('Error getting service status: $e');
      return false;
    }
  }

  /// تست اتصال Google
  static Future<GoogleConnectivityResult> testGoogleConnectivity() async {
    try {
      debugPrint('Testing Google connectivity...');
      final result = await _platform.invokeMethod('testGoogleConnectivity');
      debugPrint('Google connectivity result: $result');

      if (result is Map) {
        return GoogleConnectivityResult.fromMap(
          Map<String, dynamic>.from(result),
        );
      }

      return const GoogleConnectivityResult(
        googlePing: false,
        dnsResolution: false,
        httpsConnectivity: false,
        overallStatus: false,
        message: 'Invalid response format',
      );
    } catch (e) {
      debugPrint('Error testing Google connectivity: $e');
      return GoogleConnectivityResult(
        googlePing: false,
        dnsResolution: false,
        httpsConnectivity: false,
        overallStatus: false,
        message: 'Error: $e',
      );
    }
  }

  /// بررسی آماده بودن سرویس
  static Future<bool> isServiceReady() async {
    try {
      // تست ساده برای بررسی آماده بودن platform channel
      await _platform.invokeMethod('getServiceStatus');
      return true;
    } catch (e) {
      debugPrint('Service not ready: $e');
      return false;
    }
  }

  /// تست پینگ یک دامنه با دی‌ان‌اس سفارشی (برای نمایش در لیست)
  static Future<DnsStatus> testDnsWithDns(String domain, String dns) async {
    try {
      // فراخوانی متد native جدید (باید در اندروید پیاده‌سازی شود)
      final result = await _platform.invokeMethod('testDnsWithDns', {
        'domain': domain,
        'dns': dns,
      });
      if (result is Map) {
        final ping = (result['ping'] as int?) ?? -1;
        final isReachable = (result['isReachable'] as bool?) ?? false;
        return DnsStatus(ping, isReachable);
      }
      return const DnsStatus(-1, false);
    } catch (e) {
      return const DnsStatus(-1, false);
    }
  }
}
