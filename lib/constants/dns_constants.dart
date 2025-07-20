/// کلاس ثوابت DNS
class DnsConstants {
  // Channel های ارتباطی
  static const String methodChannel = 'com.example.dnschanger/dns';
  static const String vpnStatusChannel = 'com.example.dnschanger/vpnStatus';
  static const String dataUsageChannel = 'com.example.dnschanger/dataUsage';

  // DNS های پیشفرض
  static const String defaultPrimaryDns = '178.22.122.100'; // Shecan DNS
  static const String defaultSecondaryDns = '1.1.1.1'; // Cloudflare DNS

  // DNS های محبوب
  static const Map<String, Map<String, String>> popularDnsServers = {
    'Shecan': {'primary': '178.22.122.100', 'secondary': '185.51.200.2'},
    'Cloudflare': {'primary': '1.1.1.1', 'secondary': '1.0.0.1'},
    'Google': {'primary': '8.8.8.8', 'secondary': '8.8.4.4'},
    'OpenDNS': {'primary': '208.67.222.222', 'secondary': '208.67.220.220'},
    'Quad9': {'primary': '9.9.9.9', 'secondary': '149.112.112.112'},
  };

  // تنظیمات پینگ
  static const int defaultPingInterval = 10; // ثانیه
  static const int pingTimeout = 5; // ثانیه
  static const int maxPingRetries = 3;

  // حدود پینگ (میلی‌ثانیه)
  static const int excellentPingThreshold = 50;
  static const int goodPingThreshold = 100;
  static const int fairPingThreshold = 200;
  static const int poorPingThreshold = 300;

  // متن‌های رابط کاربری
  static const Map<String, String> uiTexts = {
    'dns1Label': 'DNS 1',
    'dns2Label': 'DNS 2',
    'pingBothButton': 'پینگ هر دو',
    'autoPingOn': 'پینگ خودکار: روشن',
    'autoPingOff': 'پینگ خودکار: خاموش',
    'vpnActive': 'VPN روشن است',
    'vpnInactive': 'VPN خاموش است',
    'googleConnectivityTest': 'تست اتصال Google',
    'testGoogleButton': 'تست Google',
    'unavailable': 'ناموجود',
  };

  // پیام‌های خطا
  static const Map<String, String> errorMessages = {
    'invalidDns1': 'لطفاً DNS اول را به‌درستی وارد کنید.',
    'invalidDns2': 'فرمت DNS دوم صحیح نیست.',
    'dns1Unreachable': 'DNS اول در دسترس نیست',
    'dns2Unreachable': 'DNS دوم در دسترس نیست',
    'dnsChangeSuccess': 'DNS با موفقیت تغییر کرد',
    'dnsChangeError': 'خطا در تغییر DNS',
    'vpnDisabled': 'VPN غیرفعال شد.',
    'vpnDisableError': 'خطا در غیرفعال‌سازی VPN',
    'vpnActivated': 'DNS با موفقیت تغییر یافت و VPN فعال شد.',
    'vpnActivationError':
        'تغییر DNS با خطا مواجه شد یا توسط سیستم پشتیبانی نمی‌شود.',
    'connectivityTestPassed': 'Google connectivity test passed! ✅',
    'connectivityTestFailed': 'Google connectivity test failed! ❌',
    'connectivityTestError': 'Error testing Google connectivity',
  };
}
