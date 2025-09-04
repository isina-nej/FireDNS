import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/path/path.dart';
import 'package:firedns/screens/force_update_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppUpdater {
  static Future<bool> checkAndShowUpdateIfNeeded({
    required BuildContext context,
    required ThemeController themeController,
    required LanguageManager languageManager,
  }) async {
    print('🔄 در حال بررسی آپدیت...');
    final languageCode = Localizations.localeOf(context).languageCode;
    final (isLatest, updateInfo) =
        await UpdateChecker.checkForUpdates(languageCode: languageCode);

    if (!isLatest && updateInfo != null && context.mounted) {
      print('📢 نسخه جدید پیدا شد - نمایش صفحه آپدیت');

      // نمایش صفحه آپدیت با GetX
      Get.to(() => ForceUpdatePage(
            updateUrl: updateInfo.updateUrl,
            currentAppVersion: UpdateChecker.currentVersion,
          ));

      print('⏳ منتظر اقدام کاربر برای آپدیت...');
      return false;
    }

    return true;
  }
}
