import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/dns_status.dart';
import '../models/google_connectivity_result.dart';
import '../constants/dns_constants.dart';
import '../utils/dns_validator.dart';

/// سرویس مدیریت DNS
class DnsService {
  static const _platform = MethodChannel(DnsConstants.methodChannel);

  /// تست پینگ یک DNS
  static Future<DnsStatus> testDns(String dns) async {
    try {
      if (!DnsValidator.isValidDns(dns)) {
        debugPrint('Invalid DNS address: $dns');
        return const DnsStatus(-1, false);
      }

      debugPrint('Testing DNS: $dns');
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
    } catch (e) {
      debugPrint('Error testing DNS: $e');
      return const DnsStatus(-1, false);
    }
  }

  /// تغییر DNS سیستم
  static Future<bool> changeDns(String dns1, String dns2) async {
    try {
      // اعتبارسنجی DNS ها
      if (!DnsValidator.isValidDns(dns1)) {
        debugPrint('Invalid primary DNS: $dns1');
        return false;
      }

      if (dns2.isNotEmpty && !DnsValidator.isValidDns(dns2)) {
        debugPrint('Invalid secondary DNS: $dns2');
        return false;
      }

      // تست دسترسی DNS ها
      final dns1Status = await testDns(dns1);
      if (!dns1Status.isReachable) {
        debugPrint('Primary DNS is not reachable: $dns1');
        return false;
      }

      if (dns2.isNotEmpty) {
        final dns2Status = await testDns(dns2);
        if (!dns2Status.isReachable) {
          debugPrint('Secondary DNS is not reachable: $dns2');
          return false;
        }
      }

      // تغییر DNS
      await _platform.invokeMethod('setDns', {'dns1': dns1, 'dns2': dns2});
      debugPrint('DNS changed successfully: $dns1, $dns2');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Platform error changing DNS: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error changing DNS: $e');
      return false;
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

  /// دریافت لیست DNS های محبوب
  static List<Map<String, String>> getPopularDnsServers() {
    return DnsConstants.popularDnsServers.entries
        .map(
          (entry) => {
            'name': entry.key,
            'primary': entry.value['primary']!,
            'secondary': entry.value['secondary']!,
          },
        )
        .toList();
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
