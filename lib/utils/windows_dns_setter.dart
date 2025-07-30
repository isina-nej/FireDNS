import 'dart:developer';
import 'dart:io';

class WindowsDnsSetter {
  /// بازگرداندن همه کارت‌های شبکه Wi-Fi و Ethernet به حالت دریافت خودکار DNS
  static Future<bool> unsetDns() async {
    try {
      log(
        'شروع عملیات بازگردانی DNS ویندوز به حالت خودکار برای همه کارت‌های Wi-Fi و Ethernet...',
      );
      // شناسایی همه کارت‌های فعال (Wi-Fi و Ethernet و LAN و ...)
      // ابتدا همه کارت‌های فعال را با نام و توضیح لاگ بگیر برای دیباگ
      final allAdaptersResult = await Process.run('powershell', [
        '-Command',
        'Get-NetAdapter | Where-Object { (\$_.Status -eq "Up") -and (\$_.InterfaceType -eq 6 -or \$_.InterfaceType -eq 71) } | Select-Object Name, InterfaceDescription, InterfaceType | ConvertTo-Json',
      ]);
      log(
        'لیست کامل کارت‌های فعال واقعی (نام و توضیح و نوع): ${allAdaptersResult.stdout}',
      );
      // فقط نام کارت‌های فعال واقعی را جدا کن
      final interfacesResult = await Process.run('powershell', [
        '-Command',
        'Get-NetAdapter | Where-Object { (\$_.Status -eq "Up") -and (\$_.InterfaceType -eq 6 -or \$_.InterfaceType -eq 71) } | Select-Object -ExpandProperty Name',
      ]);
      log('PowerShell exitCode: ${interfacesResult.exitCode}');
      log('PowerShell stdout: ${interfacesResult.stdout}');
      log('PowerShell stderr: ${interfacesResult.stderr}');
      final interfaces = (interfacesResult.stdout as String)
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      log('کارت‌های شناسایی‌شده: $interfaces');
      if (interfaces.isEmpty) {
        log('هیچ کارت شبکه فعالی برای بازگردانی DNS پیدا نشد.');
        return false;
      }

      bool allSuccess = true;
      for (final interfaceName in interfaces) {
        log(
          'در حال بازگردانی DNS به حالت خودکار برای کارت شبکه: $interfaceName',
        );
        final netshCmd =
            'netsh interface ip set dns name="$interfaceName" source=dhcp';
        log('دستور netsh اجرا شده: $netshCmd');
        final result = await Process.run('netsh', [
          'interface',
          'ip',
          'set',
          'dns',
          'name="$interfaceName"',
          'source=dhcp',
        ], runInShell: true);
        log('netsh (unset) exitCode: ${result.exitCode}');
        log('netsh (unset) stdout: ${result.stdout}');
        log('netsh (unset) stderr: ${result.stderr}');
        if (result.exitCode != 0) {
          allSuccess = false;
          log('خطا در بازگردانی DNS برای کارت شبکه: $interfaceName');
        } else {
          log(
            'DNS با موفقیت به حالت خودکار برای کارت شبکه $interfaceName بازگردانده شد.',
          );
        }
      }
      if (allSuccess) {
        log('عملیات بازگردانی DNS روی همه کارت‌های فعال با موفقیت انجام شد.');
        return true;
      } else {
        log(
          'برخی کارت‌ها با خطا مواجه شدند. برای جزئیات بیشتر لاگ‌ها را بررسی کنید.',
        );
        return false;
      }
    } catch (e) {
      log('خطا در بازگردانی DNS ویندوز: $e');
      return false;
    }
  }

  static Future<bool> setDns(String dns1, String dns2) async {
    // ست کردن DNS روی همه کارت‌های شبکه فعال از نوع Wi-Fi و Ethernet
    try {
      log(
        'شروع عملیات ست کردن DNS ویندوز برای همه کارت‌های Wi-Fi و Ethernet...',
      );
      // گرفتن لیست کارت‌های شبکه فعال و مناسب (فقط با escape صحیح $)
      final interfacesResult = await Process.run('powershell', [
        '-Command',
        'Get-NetAdapter | Where-Object { (\$_.Status -eq "Up") -and (\$_.InterfaceType -eq 6 -or \$_.InterfaceType -eq 71) } | Select-Object -ExpandProperty Name',
      ]);
      log('PowerShell exitCode: ${interfacesResult.exitCode}');
      log('PowerShell stdout: ${interfacesResult.stdout}');
      log('PowerShell stderr: ${interfacesResult.stderr}');
      final interfaces = (interfacesResult.stdout as String)
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      log('کارت‌های شناسایی‌شده: $interfaces');
      if (interfaces.isEmpty) {
        log('هیچ کارت شبکه Wi-Fi یا Ethernet فعالی پیدا نشد.');
        return false;
      }

      bool allSuccess = true;
      for (final interfaceName in interfaces) {
        log('در حال ست کردن DNS برای کارت شبکه: $interfaceName');
        final setPrimary = await Process.run('netsh', [
          'interface',
          'ip',
          'set',
          'dns',
          'name="$interfaceName"',
          'source=static',
          'addr=$dns1',
          'register=primary',
        ], runInShell: true);
        log('netsh (primary) exitCode: ${setPrimary.exitCode}');
        log('netsh (primary) stdout: ${setPrimary.stdout}');
        log('netsh (primary) stderr: ${setPrimary.stderr}');
        if (setPrimary.exitCode != 0) {
          allSuccess = false;
          log('خطا در ست کردن DNS اصلی برای کارت شبکه: $interfaceName');
          continue;
        }

        if (dns2.isNotEmpty) {
          log('در حال ست کردن DNS دوم برای کارت شبکه: $interfaceName');
          final setSecondary = await Process.run('netsh', [
            'interface',
            'ip',
            'add',
            'dns',
            'name="$interfaceName"',
            'addr=$dns2',
            'index=2',
          ], runInShell: true);
          log('netsh (secondary) exitCode: ${setSecondary.exitCode}');
          log('netsh (secondary) stdout: ${setSecondary.stdout}');
          log('netsh (secondary) stderr: ${setSecondary.stderr}');
          if (setSecondary.exitCode != 0) {
            allSuccess = false;
            log('خطا در ست کردن DNS دوم برای کارت شبکه: $interfaceName');
          }
        }
      }
      if (allSuccess) {
        log('عملیات ست کردن DNS روی همه کارت‌های مناسب با موفقیت انجام شد.');
        return true;
      } else {
        log('برخی کارت‌ها با خطا مواجه شدند.');
        return false;
      }
    } catch (e) {
      log('خطا در ست کردن DNS ویندوز: $e');
      return false;
    }
  }
}
