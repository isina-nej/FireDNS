/// کلاس ابزارهای قالب‌بندی
class FormatUtils {
  /// قالب‌بندی بایت به واحدهای مناسب
  static String formatBytes(int bytes) {
    if (bytes < 0) return '0 B';

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// قالب‌بندی مدت زمان
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} روز';
    }

    if (duration.inHours > 0) {
      return '${duration.inHours} ساعت';
    }

    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} دقیقه';
    }

    return '${duration.inSeconds} ثانیه';
  }

  /// قالب‌بندی زمان پینگ
  static String formatPingTime(int pingMs) {
    if (pingMs < 0) return '--';
    if (pingMs == 0) return '< 1 ms';
    return '$pingMs ms';
  }

  /// قالب‌بندی درصد
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// قالب‌بندی عدد با جداکننده هزارگان
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// قالب‌بندی وضعیت boolean به متن فارسی
  static String formatBooleanStatus(bool status) {
    return status ? 'فعال' : 'غیرفعال';
  }

  /// قالب‌بندی وضعیت boolean به ایموجی
  static String formatBooleanEmoji(bool status) {
    return status ? '✅' : '❌';
  }

  /// قالب‌بندی آدرس IP (حذف فضاهای اضافی)
  static String formatIpAddress(String ip) {
    return ip.trim().replaceAll(RegExp(r'\s+'), '');
  }

  /// کوتاه کردن متن طولانی
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// قالب‌بندی پیام خطا
  static String formatErrorMessage(String error) {
    // حذف پیشوند خطای فنی
    final cleanError = error
        .replaceAll('PlatformException', '')
        .replaceAll('Exception', '')
        .replaceAll('Error', '')
        .trim();

    if (cleanError.isEmpty) return 'خطای نامشخص';

    // بزرگ کردن حرف اول
    return cleanError[0].toUpperCase() + cleanError.substring(1);
  }
}
