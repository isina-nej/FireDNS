import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_notification_service.dart';
import 'navigation_service.dart';
import '../routes/app_routes.dart';
import '../api/models/notification_model.dart';
import 'notification_cache_service.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  int _notificationId = 0;

  NotificationType _getNotificationType(RemoteMessage message) {
    final type = message.data['type']?.toString().toLowerCase() ?? 'info';
    switch (type) {
      case 'warning':
        return NotificationType.warning;
      case 'error':
        return NotificationType.error;
      case 'success':
        return NotificationType.success;
      default:
        return NotificationType.info;
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    if (message.data.containsKey('route')) {
      final route = message.data['route'];
      NavigationService.navigatorKey.currentState?.pushNamed(route);
    } else {
      // اگر مسیر خاصی مشخص نشده باشد، به صفحه اعلانات هدایت می‌شود
      NavigationService.navigatorKey.currentState
          ?.pushNamed(AppRoutes.notifications);
    }
  }

  Future<void> initialize() async {
    // بررسی نوتیفیکیشن اولیه در صورت باز شدن اپ از حالت terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification');
      print('Initial message data: ${initialMessage.data}');
      // تاخیر برای اطمینان از آماده بودن نویگیتور
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationNavigation(initialMessage);
      });
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message notification: ${message.notification}');

        // ساخت مدل نوتیفیکیشن
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification!.title ?? 'Fire DNS',
          message: message.notification!.body ?? '',
          date: message.sentTime ?? DateTime.now(),
          type: _getNotificationType(message),
          actionUrl: message.data['actionUrl'],
          imageUrl: message.notification!.android?.imageUrl,
        );

        // ذخیره در کش
        try {
          await NotificationCacheService.addNotification(notification);
          print('Firebase notification saved to cache: ${notification.id}');
        } catch (e) {
          print('Error saving firebase notification to cache: $e');
        }

        // نمایش نوتیفیکیشن
        LocalNotificationService.showNotification(
          id: _notificationId++,
          title: notification.title,
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
      _handleNotificationNavigation(message);
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
