import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_notification_service.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  int _notificationId = 0;

  Future<void> initialize() async {
    // بررسی نوتیفیکیشن اولیه در صورت باز شدن اپ از حالت terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification');
      print('Initial message data: ${initialMessage.data}');
      if (initialMessage.data.containsKey('route')) {
        print('Initial navigation to route: ${initialMessage.data['route']}');
        // TODO: اضافه کردن کد ناوبری به صفحه مورد نظر
      }
    }

    // درخواست مجوز نوتیفیکیشن با اجازه نمایش در پس‌زمینه
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    // تنظیم نمایش نوتیفیکیشن در فورگراند
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // دریافت FCM token
    String? token = await _firebaseMessaging.getToken();
    print('==============================================');
    print('FCM Token: $token');
    print('==============================================');

    // تنظیم handlers برای دریافت پیام‌ها در فورگراند
    // نمایش نوتیفیکیشن در حالت فورگراند
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message notification: ${message.notification}');

        LocalNotificationService.showNotification(
          id: _notificationId++,
          title: message.notification!.title ?? 'Fire DNS',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
        // نمایش نوتیفیکیشن در فورگراند
      }
    });

    // وقتی اپلیکیشن از طریق نوتیفیکیشن باز می‌شود
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');

      // می‌توانید اینجا عملیات مربوط به باز کردن صفحه خاص یا اجرای عملیات خاص را انجام دهید
      if (message.data.containsKey('route')) {
        print('Navigation to route: ${message.data['route']}');
        // TODO: اضافه کردن کد ناوبری به صفحه مورد نظر
      }
    });
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
