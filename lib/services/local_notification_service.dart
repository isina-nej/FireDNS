import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSettings {
  static const androidChannel = AndroidNotificationChannel(
    'fire_dns_high_importance_channel',
    'Fire DNS Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // اینجا می‌توانید کدهای مربوط به کلیک روی نوتیفیکیشن را اضافه کنید
        print('Notification clicked: ${notificationResponse.payload}');
      },
    );

    // ایجاد کانال نوتیفیکیشن برای اندروید
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(NotificationSettings.androidChannel);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationSettings.androidChannel.id,
            NotificationSettings.androidChannel.name,
            channelDescription: NotificationSettings.androidChannel.description,
            importance: NotificationSettings.androidChannel.importance,
            priority: Priority.high,
            ticker: 'ticker',
            visibility: NotificationVisibility.public,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}
