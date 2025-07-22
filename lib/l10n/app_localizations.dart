/// کلاس ترجمه‌های اپلیکیشن
class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedStrings = {
    'fa': {
      // عمومی
      'appTitle': 'تغییر دهنده DNS',
      'settings': 'تنظیمات',
      'about': 'درباره',
      'support': 'پشتیبانی',
      'close': 'بستن',
      'ok': 'تأیید',
      'cancel': 'لغو',
      'save': 'ذخیره',
      'delete': 'حذف',
      'edit': 'ویرایش',
      'add': 'افزودن',
      'back': 'بازگشت',
      'next': 'بعدی',
      'previous': 'قبلی',
      'loading': 'در حال بارگذاری...',
      'error': 'خطا',
      'success': 'موفقیت',
      'warning': 'هشدار',
      'info': 'اطلاعات',

      // صفحه اصلی
      'myDns': 'DNS من',
      'connected': 'متصل',
      'disconnected': 'قطع شده',
      'connecting': 'در حال اتصال...',
      'yourSessionIsPrivate': 'جلسه شما خصوصی است',
      'yourSessionIsNotPrivate': 'جلسه شما خصوصی نیست',
      'speedTest': 'تست سرعت',
      'configuration': 'پیکربندی',
      'run': 'اجرا',
      'switch': 'تغییر',

      // تنظیمات
      'autoStartOnBoot': 'شروع خودکار',
      'darkTheme': 'تم تاریک',
      'language': 'زبان',
      'changeLanguage': 'تغییر زبان',
      'farsi': 'فارسی',
      'english': 'انگلیسی',
      'notifications': 'اعلان‌ها',
      'aboutMyDns': 'درباره DNS من',
      'supportThisApp': 'حمایت از این برنامه',

      // DNS
      'dnsManager': 'مدیریت DNS',
      'dnsRecords': 'رکوردهای DNS',
      'primaryDns': 'DNS اصلی',
      'secondaryDns': 'DNS فرعی',
      'customDns': 'DNS سفارشی',
      'publicDns': 'DNS عمومی',
      'googleDns': 'Google DNS',
      'cloudflareDns': 'Cloudflare DNS',
      'openDns': 'OpenDNS',

      // اتصال و شبکه
      'connectionStatus': 'وضعیت اتصال',
      'networkSettings': 'تنظیمات شبکه',
      'vpnActive': 'VPN فعال',
      'vpnInactive': 'VPN غیرفعال',
      'ping': 'پینگ',
      'latency': 'تأخیر',
      'downloadSpeed': 'سرعت دانلود',
      'uploadSpeed': 'سرعت آپلود',

      // پیام‌ها
      'vpnActivated': 'VPN با موفقیت فعال شد',
      'vpnDeactivated': 'VPN با موفقیت غیرفعال شد',
      'vpnActivationError': 'خطا در فعال‌سازی VPN',
      'vpnDeactivationError': 'خطا در غیرفعال‌سازی VPN',
      'connectivityTestPassed': 'تست اتصال موفقیت‌آمیز بود',
      'connectivityTestFailed': 'تست اتصال ناموفق بود',
      'invalidDnsAddress': 'آدرس DNS نامعتبر است',
      'networkError': 'خطای شبکه',
      'connectionFailed': 'اتصال ناموفق',
      'operationCancelled': 'عملیات لغو شد',
      'permissionDenied': 'دسترسی رد شد',
      'serviceUnavailable': 'سرویس در دسترس نیست',

      // راهنما
      'swipeDownToClose': 'برای بستن به پایین بکشید',
      'swipeUpToLock': 'برای قفل کردن به بالا بکشید',
      'tapToToggle': 'برای تغییر ضربه بزنید',
      'longPressForOptions': 'برای گزینه‌ها نگه دارید',

      // توضیحات
      'speedTestDescription':
          'تست سرعت، سرعت اتصال بین دستگاه شما و سرور آزمایش را اندازه‌گیری می‌کند.',
      'configurationDescription':
          'تنظیمات شبکه خود را شخصی‌سازی کنید و پیکربندی مناسب برای نیازهای اتصال خود را انتخاب کنید.',
      'dnsExplanation':
          'DNS (سیستم نام دامنه) نام‌های وب‌سایت‌ها را به آدرس IP تبدیل می‌کند.',

      // وضعیت‌ها
      'online': 'آنلاین',
      'offline': 'آفلاین',
      'unknown': 'نامشخص',
      'checking': 'در حال بررسی...',
      'failed': 'ناموفق',
      'timeout': 'زمان تمام شد',
    },

    'en': {
      // General
      'appTitle': 'Fire DNS',
      'settings': 'Settings',
      'about': 'About',
      'support': 'Support',
      'close': 'Close',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Info',

      // Home page
      'myDns': 'My DNS',
      'connected': 'CONNECTED',
      'disconnected': 'DISCONNECTED',
      'connecting': 'Connecting...',
      'yourSessionIsPrivate': 'Your session is private',
      'yourSessionIsNotPrivate': 'Your session is not private',
      'speedTest': 'SpeedTest',
      'configuration': 'Configuration',
      'run': 'Run',
      'switch': 'Switch',

      // Settings
      'autoStartOnBoot': 'Auto start on boot',
      'darkTheme': 'Dark theme',
      'language': 'Language',
      'changeLanguage': 'Change Language',
      'farsi': 'Persian',
      'english': 'English',
      'notifications': 'Notifications',
      'aboutMyDns': 'About My DNS',
      'supportThisApp': 'Support this app',

      // DNS
      'dnsManager': 'DNS Manager',
      'dnsRecords': 'DNS Records',
      'primaryDns': 'Primary DNS',
      'secondaryDns': 'Secondary DNS',
      'customDns': 'Custom DNS',
      'publicDns': 'Public DNS',
      'googleDns': 'Google DNS',
      'cloudflareDns': 'Cloudflare DNS',
      'openDns': 'OpenDNS',

      // Connection and Network
      'connectionStatus': 'Connection Status',
      'networkSettings': 'Network Settings',
      'vpnActive': 'VPN Active',
      'vpnInactive': 'VPN Inactive',
      'ping': 'Ping',
      'latency': 'Latency',
      'downloadSpeed': 'Download Speed',
      'uploadSpeed': 'Upload Speed',

      // Messages
      'vpnActivated': 'VPN activated successfully',
      'vpnDeactivated': 'VPN deactivated successfully',
      'vpnActivationError': 'Error activating VPN',
      'vpnDeactivationError': 'Error deactivating VPN',
      'connectivityTestPassed': 'Connectivity test passed',
      'connectivityTestFailed': 'Connectivity test failed',
      'invalidDnsAddress': 'Invalid DNS address',
      'networkError': 'Network error',
      'connectionFailed': 'Connection failed',
      'operationCancelled': 'Operation cancelled',
      'permissionDenied': 'Permission denied',
      'serviceUnavailable': 'Service unavailable',

      // Guide
      'swipeDownToClose': 'Swipe down to close',
      'swipeUpToLock': 'Swipe up to lock',
      'tapToToggle': 'Tap to toggle',
      'longPressForOptions': 'Long press for options',

      // Descriptions
      'speedTestDescription':
          'Speedtest measures the speed between your device and a test server, using your device\'s internet connection.',
      'configurationDescription':
          'Customize your network preferences and choose the configuration that best suits your connection needs.',
      'dnsExplanation':
          'DNS (Domain Name System) translates website names to IP addresses.',

      // Status
      'online': 'Online',
      'offline': 'Offline',
      'unknown': 'Unknown',
      'checking': 'Checking...',
      'failed': 'Failed',
      'timeout': 'Timeout',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedStrings[languageCode]?[key] ?? key;
  }

  static String get(String key, String languageCode) {
    return translate(key, languageCode);
  }
}
