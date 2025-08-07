import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// دریافت شناسه یکتای دستگاه
Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // شناسه یکتای اندروید
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown'; // شناسه یکتای iOS
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId; // شناسه یکتای ویندوز
    } else {
      // برای سایر پلتفرم‌ها
      return 'unknown_${Platform.operatingSystem}';
    }
  } catch (e) {
    // در صورت خطا، یک شناسه موقت برمی‌گردانیم
    return 'error_${DateTime.now().millisecondsSinceEpoch}';
  }
}
