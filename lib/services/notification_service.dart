// import 'dart:async';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import '../models/fcm_message.dart';
// import '../api/services/fcm_api_service.dart';
// import '../screens/force_update_page.dart';

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;

//   final _fcmService = FcmApiService();
//   final _messageController = StreamController<FcmMessage>.broadcast();

//   Stream<FcmMessage> get messages => _messageController.stream;

//   NotificationService._internal();

//   Future<void> initialize(BuildContext context) async {
//     // درخواست مجوز نوتیفیکیشن
//     final messaging = FirebaseMessaging.instance;
//     await messaging.requestPermission();

//     // دریافت توکن FCM
//     final token = await messaging.getToken();
//     if (token != null) {
//       await _fcmService.registerFcmToken(
//         userId: 'guest', // یا از سیستم مدیریت کاربران دریافت شود
//         deviceId: 'device_id', // از سیستم دریافت شود
//         token: token,
//         platform: Theme.of(context).platform.toString(),
//       );
//     }

//     // گوش دادن به پیام‌های FCM
//     FirebaseMessaging.onMessage.listen(_handleMessage);
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
//     FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

//     // چک کردن پیام اولیه (وقتی اپ با کلیک روی نوتیفیکیشن باز شده)
//     final initialMessage = await messaging.getInitialMessage();
//     if (initialMessage != null) {
//       _handleMessage(initialMessage);
//     }
//   }

//   void _handleMessage(RemoteMessage message) {
//     try {
//       final fcmMessage = FcmMessage(
//         type: message.data['type'] as String,
//         data: message.data,
//       );

//       _messageController.add(fcmMessage);

//       // اگر پیام از نوع آپدیت بود
//       if (fcmMessage.type == FcmMessage.typeUpdateAvailable) {
//         _showUpdateDialog(fcmMessage.data);
//       }
//     } catch (e) {
//       debugPrint('Error handling FCM message: $e');
//     }
//   }

//   static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
//     // این متد فقط در پس‌زمینه اجرا می‌شود
//     debugPrint('Received background message: ${message.data}');
//   }

//   void _showUpdateDialog(Map<String, dynamic> data) {
//     // نمایش دیالوگ آپدیت در تمام صفحات اپلیکیشن
//     for (final context in _findGlobalContexts()) {
//       showDialog(
//         context: context,
//         barrierDismissible: !(data['force'] as bool? ?? false),
//         builder: (context) => AlertDialog(
//           title: const Text('بروزرسانی جدید'),
//           content: const Text('نسخه جدید برنامه در دسترس است. لطفاً برنامه را بروزرسانی کنید.'),
//           actions: [
//             if (!(data['force'] as bool? ?? false))
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('بعداً'),
//               ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => ForceUpdatePage(
//                       updateUrl: data['url'] as String? ?? UpdateChecker.updateUrl,
//                     ),
//                   ),
//                 );
//               },
//               child: const Text('بروزرسانی'),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   List<BuildContext> _findGlobalContexts() {
//     // پیدا کردن تمام context های فعال در اپلیکیشن
//     final contexts = <BuildContext>[];
//     final navigatorState = GlobalKey<NavigatorState>().currentState;
//     if (navigatorState != null) {
//       contexts.add(navigatorState.context);
//     }
//     return contexts;
//   }

//   void dispose() {
//     _messageController.close();
//   }
// }
