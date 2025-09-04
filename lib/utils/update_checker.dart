import 'package:firedns/api/models/update_info.dart';
import 'package:firedns/api/services/update_api_service.dart';

/// کلاس مدیریت بررسی آپدیت برنامه
class UpdateChecker {
  /// نسخه فعلی برنامه
  static const String currentVersion = '2.0.0+1';

  /// آدرس پایه API
  static const String baseUrl = 'https://api.fire-dns.ir';

  static final UpdateApiService _updateApiService = UpdateApiService();

  /// بررسی آپدیت بودن برنامه و دریافت اطلاعات آپدیت
  static Future<(bool isLatest, UpdateInfo? updateInfo)> checkForUpdates(
      {String? languageCode}) async {
    print('🔍 شروع بررسی آپدیت جدید...');
    print('📱 نسخه فعلی برنامه: $currentVersion');

    try {
      print('🌐 درخواست بررسی آپدیت...');
      final response = await _updateApiService.getUpdateInfo(currentVersion);

      if (response.status && response.data != null) {
        final updateInfo = response.data!;
        print('📦 آخرین نسخه موجود: ${updateInfo.latestVersion}');

        final isLatest =
            _compareVersions(currentVersion, updateInfo.latestVersion) >= 0;
        print(isLatest ? '✨ برنامه به روز است' : '🔄 نسخه جدید در دسترس است');

        if (!isLatest) {
          print('📝 توضیحات آپدیت: ${updateInfo.description}');
          print('🔄 نوع آپدیت: ${updateInfo.updateType}');
          print('✨ ویژگی‌های جدید: ${updateInfo.features.join(", ")}');
          print('🔧 تغییرات: ${updateInfo.changes.join(", ")}');
        }

        return (isLatest, updateInfo);
      } else {
        print('⚠️ خطا در دریافت اطلاعات آپدیت: ${response.message}');
      }
    } catch (e) {
      print('⚠️ خطا در بررسی آپدیت: $e');
    }

    print('ℹ️ به دلیل خطا، فرض می‌کنیم برنامه به روز است');
    return (true, null);
  }

  /// مقایسه نسخه‌ها (برمی‌گرداند: 1 اگر فعلی جدیدتر، 0 برابر، -1 اگر قدیمی‌تر)
  static int _compareVersions(String v1, String v2) {
    print('🔄 مقایسه نسخه‌ها:');
    print('  - نسخه فعلی: $v1');
    print('  - نسخه جدید: $v2');

    final parts1 =
        v1.split(RegExp(r'[.+]')).map(int.tryParse).whereType<int>().toList();
    final parts2 =
        v2.split(RegExp(r'[.+]')).map(int.tryParse).whereType<int>().toList();

    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }

    if (parts1.length > parts2.length) return 1;
    if (parts1.length < parts2.length) return -1;
    return 0;
  }
}
