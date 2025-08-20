import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationServiceProvider {
  static NotificationService? _notificationService;

  static NotificationService? get instance => _notificationService;

  static void init(BuildContext context) {
    _notificationService =
        Provider.of<NotificationService>(context, listen: false);
  }

  /// بررسی تغییر زبان و به‌روزرسانی نوتیفیکیشن خوش‌آمدگویی
  static Future<void> checkLanguageChange() async {
    if (_notificationService != null) {
      await _notificationService!.checkLanguageChangeForWelcome();
    }
  }
}
