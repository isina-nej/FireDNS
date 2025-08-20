# 🚨 سیستم گزارش خطا و کرش (Crash Reporting System)

## 📋 **بررسی کلی**

سیستم گزارش خطا و کرش FireDNS به صورت خودکار تمام خطاها، کرش‌ها و مشکلات عملکردی را شناسایی و به سرور شما ارسال می‌کند.

## 🏗️ **ساختار سیستم**

### 1️⃣ **CrashReportingService**
- مدیریت ارسال لاگ‌ها به `/api/app-logs`
- دریافت خودکار Device ID
- ذخیره کرش‌های offline برای ارسال بعدی
- گزارش عملکرد (Performance Monitoring)

### 2️⃣ **FlutterErrorHandler**
- مدیریت خطاهای Flutter Framework
- مدیریت خطاهای Platform (iOS/Android)
- گزارش خطاهای widget tree
- گزارش خطاهای UI

### 3️⃣ **ErrorReporter**
- Helper class برای گزارش آسان خطاها
- گزارش خطاهای مختلف: Network, Database, UI, VPN, DNS
- Performance Timer
- گزارش Warning و Debug Info

## 🚀 **نحوه استفاده**

### **گزارش خطای کلی**
```dart
try {
  // کد شما
} catch (error, stackTrace) {
  await ErrorReporter.reportError(
    error,
    stackTrace: stackTrace,
    context: 'HomePage.initState',
    metadata: {
      'user_id': userId,
      'action': 'data_loading',
    },
  );
}
```

### **گزارش خطای شبکه**
```dart
await ErrorReporter.reportNetworkError(
  endpoint: '/api/dns-list',
  error: 'Connection timeout',
  statusCode: 408,
  requestData: {'filter': 'active'},
);
```

### **گزارش خطای VPN**
```dart
await ErrorReporter.reportVpnError(
  operation: 'connect',
  error: 'Failed to connect to VPN server',
  vpnStatus: false,
  vpnConfig: {'server': 'dns1.server.com'},
);
```

### **گزارش خطای DNS**
```dart
await ErrorReporter.reportDnsError(
  operation: 'speed_test',
  error: 'DNS server not responding',
  dnsServer: '8.8.8.8',
  dnsConfig: {'timeout': 5000},
);
```

### **Performance Monitoring**
```dart
// شروع timer
final timer = ErrorReporter.startPerformanceTimer('data_loading');

try {
  // انجام عملیات
  await loadData();
} finally {
  // پایان timer و گزارش
  await timer.end(additionalData: {
    'items_loaded': itemCount,
    'cache_hit': cacheUsed,
  });
}
```

### **گزارش Warning**
```dart
await ErrorReporter.reportWarning(
  message: 'Slow network detected',
  context: 'NetworkManager',
  warningData: {
    'ping': 1500,
    'threshold': 1000,
  },
);
```

## 📊 **انواع لاگ‌های ارسالی**

### **1. Crash Logs**
```json
{
  "deviceId": "android_abc123",
  "logType": "crash",
  "message": "Exception: Null pointer error",
  "metadata": "{\"stackTrace\":\"...\",\"platform\":\"android\",\"appVersion\":\"2.0.0\"}"
}
```

### **2. Network Error Logs**
```json
{
  "deviceId": "android_abc123",
  "logType": "network_error",
  "message": "Network Error: /api/dns-list",
  "metadata": "{\"endpoint\":\"/api/dns-list\",\"status_code\":500,\"error\":\"Server Error\"}"
}
```

### **3. Performance Logs**
```json
{
  "deviceId": "android_abc123",
  "logType": "performance",
  "message": "Performance: data_loading took 2500ms",
  "metadata": "{\"operation\":\"data_loading\",\"duration_ms\":2500,\"threshold_exceeded\":true}"
}
```

### **4. VPN Error Logs**
```json
{
  "deviceId": "android_abc123",
  "logType": "vpn_error",
  "message": "VPN Error in connect: Failed to establish connection",
  "metadata": "{\"operation\":\"connect\",\"vpn_status\":false,\"vpn_config\":{\"server\":\"dns1.server.com\"}}"
}
```

## 🔧 **تنظیمات و کانفیگوریشن**

### **در main.dart**
```dart
// سیستم خودکار راه‌اندازی شده است
// هیچ تنظیم اضافی نیاز نیست
```

### **در ApiClient**
```dart
// خطاهای شبکه خودکار گزارش می‌شوند
// نیازی به کد اضافی نیست
```

## 🎯 **ویژگی‌های کلیدی**

✅ **گزارش خودکار کرش‌ها**: تمام خطاهای uncaught  
✅ **گزارش خودکار خطاهای شبکه**: از ApiClient  
✅ **Performance Monitoring**: زمان‌سنجی عملیات  
✅ **Offline Support**: ذخیره و ارسال بعدی  
✅ **Device Identification**: شناسایی منحصر به فرد دستگاه  
✅ **Rich Metadata**: اطلاعات کامل درباره خطا  
✅ **Production Safe**: غیرفعال شدن در production برای برخی لاگ‌ها  

## 🔄 **پردازش سمت سرور**

### **Endpoint: POST /api/app-logs**
```typescript
interface AppLogRequest {
  deviceId: string;
  logType: 'crash' | 'error' | 'warning' | 'performance' | 'network_error' | 'vpn_error' | 'dns_error' | 'ui_error' | 'database_error' | 'startup' | 'info' | 'debug';
  message: string;
  metadata: string; // JSON string
}
```

### **نمونه Response**
```json
{
  "status": true,
  "message": "Log received successfully",
  "data": {
    "logId": "log_123456",
    "timestamp": "2025-08-20T10:30:00Z"
  }
}
```

## 📈 **نظارت و Analytics**

### **Dashboard Metrics پیشنهادی:**
- 📊 **تعداد کرش روزانه**
- 🌐 **خطاهای شبکه بر اساس endpoint**
- ⚡ **مشکلات عملکرد (operations > 1s)**
- 🔗 **خطاهای VPN و DNS**
- 📱 **آمار بر اساس دستگاه و پلتفرم**

### **آلارم‌های پیشنهادی:**
- 🚨 **بیش از 5 کرش در ساعت**
- ⚠️ **خطاهای شبکه بیش از 10% درخواست‌ها**
- 🐌 **عملیات کند (بیش از 5 ثانیه)**

## 🛠️ **نحوه Debugging**

### **مشاهده لاگ‌ها در Development:**
```dart
// لاگ‌ها در console نمایش داده می‌شوند
[CrashReporting] Crash report sent successfully
[ErrorReporter] Network error reported for /api/dns-list
```

### **تست سیستم گزارش خطا:**
```dart
// برای تست، یک خطای دستی ایجاد کنید
await ErrorReporter.reportError(
  Exception('Test crash for debugging'),
  context: 'ManualTest',
  metadata: {'test': true},
);
```

## 🔒 **ملاحظات امنیتی**

- ❌ **هیچ اطلاعات حساس کاربر ارسال نمی‌شود**
- ✅ **فقط Device ID (غیرقابل شناسایی) ارسال می‌شود**
- ✅ **JWT و اطلاعات احراز هویت ارسال نمی‌شود**
- ✅ **پیام‌های خطا sanitize می‌شوند**

## 🎛️ **تنظیمات پیشرفته**

### **غیرفعال کردن در Production:**
```dart
// در CrashReportingService.reportInfo()
if (!kDebugMode) return; // فقط در دیباگ فعال
```

### **تنظیم threshold عملکرد:**
```dart
// در ErrorReporter.reportPerformanceIssue()
final thresholdMs = threshold ?? 1000; // پیشفرض 1 ثانیه
```

---

## ✅ **سیستم آماده استفاده است!**

تمام کرش‌ها و خطاهای مهم به صورت خودکار به سرور شما ارسال خواهند شد. برای مشاهده گزارش‌ها، endpoint `/api/app-logs` را در سرور خود پیاده‌سازی کنید.

**نکته:** این سیستم به طور کامل یکپارچه شده و نیازی به تغییر کد موجود ندارید. 🚀
