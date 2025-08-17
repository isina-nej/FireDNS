import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/force_update_page.dart';
import 'update_checker.dart';
import '../path/path.dart';

class AppUpdater {
  static Future<bool> checkAndShowUpdateIfNeeded({
    required BuildContext context,
    required ThemeManager themeManager,
    required LanguageManager languageManager,
  }) async {
    print('🔄 در حال بررسی آپدیت...');
    final languageCode = Localizations.localeOf(context).languageCode;
    final (isLatest, updateInfo) =
        await UpdateChecker.checkForUpdates(languageCode: languageCode);

    if (!isLatest && updateInfo != null && context.mounted) {
      print('📢 نسخه جدید پیدا شد - نمایش صفحه آپدیت');

      // نمایش صفحه آپدیت با Provider
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
              ChangeNotifierProvider<LanguageManager>.value(
                  value: languageManager),
            ],
            child: ForceUpdatePage(
              updateUrl: updateInfo.updateUrl,
              currentAppVersion: UpdateChecker.currentVersion,
            ),
          ),
        ),
      );

      print('⏳ منتظر اقدام کاربر برای آپدیت...');
      return false;
    }

    return true;
  }
}
