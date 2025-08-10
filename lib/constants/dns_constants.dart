/// کلاس ثوابت DNS
class DnsConstants {
  // Channel های ارتباطی
  static const String methodChannel = 'com.example.firedns/dns';
  static const String vpnStatusChannel = 'com.example.firedns/vpnStatus';
  static const String dataUsageChannel = 'com.example.firedns/dataUsage';

  // DNS های پیشفرض
  static const String defaultPrimaryDns = '8.8.8.8'; // Google DNS
  static const String defaultSecondaryDns = '8.8.4.4'; // Google DNS

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
    'vpnActivatedWithWarning': 'VPN فعال شد، اما سرورهای DNS ممکن است در دسترس نباشند. اتصال ممکن است محدود باشد.',
    'vpnActivationError':
        'تغییر DNS با خطا مواجه شد یا توسط سیستم پشتیبانی نمی‌شود.',
    'connectivityTestPassed': 'Google connectivity test passed! ✅',
    'connectivityTestFailed': 'Google connectivity test failed! ❌',
    'connectivityTestError': 'Error testing Google connectivity',
    'vpnActive': 'VPN فعال است',
  };
}
