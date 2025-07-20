/// کلاس ابزارهای اعتبارسنجی DNS
class DnsValidator {
  /// بررسی معتبر بودن آدرس IP
  static bool isValidDns(String value) {
    if (value.isEmpty) return false;

    final regex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
    if (!regex.hasMatch(value)) return false;

    // بررسی محدوده هر بخش IP
    final parts = value.split('.');
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }

    return true;
  }

  /// بررسی معتبر بودن آدرس IP (همان isValidDns)
  static bool isValidIp(String value) {
    return isValidDns(value);
  }

  /// بررسی آدرس IP خصوصی
  static bool isPrivateIp(String ip) {
    if (!isValidDns(ip)) return false;

    final parts = ip.split('.').map(int.parse).toList();
    final firstOctet = parts[0];
    final secondOctet = parts[1];

    // 10.0.0.0/8
    if (firstOctet == 10) return true;

    // 172.16.0.0/12
    if (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31)
      return true;

    // 192.168.0.0/16
    if (firstOctet == 192 && secondOctet == 168) return true;

    return false;
  }

  /// بررسی آدرس IP محلی
  static bool isLocalhost(String ip) {
    return ip == '127.0.0.1' || ip == '::1';
  }

  /// بررسی آدرس IP رزرو شده
  static bool isReservedIp(String ip) {
    if (!isValidDns(ip)) return false;

    final parts = ip.split('.').map(int.parse).toList();
    final firstOctet = parts[0];

    // 0.0.0.0/8 - Current network
    if (firstOctet == 0) return true;

    // 127.0.0.0/8 - Loopback
    if (firstOctet == 127) return true;

    // 169.254.0.0/16 - Link-local
    if (firstOctet == 169 && parts[1] == 254) return true;

    // 224.0.0.0/4 - Multicast
    if (firstOctet >= 224 && firstOctet <= 239) return true;

    // 240.0.0.0/4 - Reserved
    if (firstOctet >= 240) return true;

    return false;
  }

  /// بررسی آدرس IP قابل استفاده برای DNS
  static bool isUsableForDns(String ip) {
    if (!isValidDns(ip)) return false;
    if (isLocalhost(ip)) return false;
    if (isReservedIp(ip)) return false;

    return true;
  }

  /// تمیز کردن آدرس IP
  static String sanitizeDns(String dns) {
    return dns.trim().toLowerCase();
  }

  /// دریافت پیام خطا برای آدرس IP نامعتبر
  static String getValidationError(String dns) {
    if (dns.isEmpty) {
      return 'آدرس DNS نمی‌تواند خالی باشد';
    }

    if (!isValidDns(dns)) {
      return 'فرمت آدرس IP صحیح نیست';
    }

    if (isLocalhost(dns)) {
      return 'آدرس localhost برای DNS مناسب نیست';
    }

    if (isReservedIp(dns)) {
      return 'آدرس IP رزرو شده برای DNS مناسب نیست';
    }

    return '';
  }
}
