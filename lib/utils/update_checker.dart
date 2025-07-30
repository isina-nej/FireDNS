import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateChecker {
  /// نسخه فعلی برنامه را اینجا وارد کنید
  static const String currentVersion = '1.0.0+1';

  /// آدرس API یا فایل نسخه جدید (مثلاً روی سرور یا گیت‌هاب)
  static const String versionCheckUrl =
      'https://raw.githubusercontent.com/isina-nej/Version-Fire-DNS/main/version.json';
  static const String updateUrl = 'https://firedns.isina-nej.ir';

  /// بررسی آپدیت بودن برنامه
  static Future<bool> isLatestVersion() async {
    try {
      final response = await http.get(Uri.parse(versionCheckUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'] as String?;
        if (latestVersion != null) {
          return _compareVersions(currentVersion, latestVersion) >= 0;
        }
      }
    } catch (_) {}
    // اگر خطا رخ داد، فرض می‌کنیم آخرین نسخه است تا کاربر قفل نشود
    return true;
  }

  /// مقایسه نسخه‌ها (برمی‌گرداند: 1 اگر فعلی جدیدتر، 0 برابر، -1 اگر قدیمی‌تر)
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1
        .split(RegExp(r'[.+]'))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final parts2 = v2
        .split(RegExp(r'[.+]'))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    if (parts1.length > parts2.length) return 1;
    if (parts1.length < parts2.length) return -1;
    return 0;
  }
}
