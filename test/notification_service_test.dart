import 'package:firedns/api/models/notification_model.dart';
import 'package:firedns/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Notification Service Tests', () {
    late NotificationService notificationService;

    setUpAll(() async {
      // Mock SharedPreferences with welcome notification flag to prevent auto-creation
      SharedPreferences.setMockInitialValues({
        'notifications': '[]',
        'unread_count': '0',
        'welcome_notification_shown': 'true', // Prevent welcome notification
        'welcome_notification_language': 'fa', // Match current language
      });

      notificationService = NotificationService();
      // Wait a bit for initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('should add notification correctly', () async {
      final initialCount = notificationService.notifications.length;

      final notification = NotificationModel(
        id: 'test_1',
        title: 'Test Notification',
        message: 'Test Message',
        type: NotificationType.info,
        date: DateTime.now(),
        isRead: false,
      );

      await notificationService.addNotification(notification);

      expect(
        notificationService.notifications.length,
        equals(initialCount + 1),
      );
      expect(
        notificationService.notifications
            .any((n) => n.title == 'Test Notification'),
        isTrue,
      );
    });

    test('should mark notification as read', () async {
      final notification = NotificationModel(
        id: 'test_2',
        title: 'Test Notification 2',
        message: 'Test Message 2',
        type: NotificationType.info,
        date: DateTime.now(),
        isRead: false,
      );

      await notificationService.addNotification(notification);
      final result = await notificationService.markAsRead('test_2');

      expect(result, isTrue);

      final readNotification =
          notificationService.notifications.firstWhere((n) => n.id == 'test_2');
      expect(readNotification.isRead, isTrue);
    });

    test('should mark all notifications as read', () async {
      await notificationService.addNotification(NotificationModel(
        id: 'test_3',
        title: 'Test 3',
        message: 'Message 3',
        date: DateTime.now(),
        type: NotificationType.info,
        isRead: false,
      ));

      await notificationService.addNotification(NotificationModel(
        id: 'test_4',
        title: 'Test 4',
        message: 'Message 4',
        date: DateTime.now(),
        type: NotificationType.warning,
        isRead: false,
      ));

      final result = await notificationService.markAllAsRead();
      expect(result, isTrue);

      final unreadNotifications =
          notificationService.notifications.where((n) => !n.isRead);
      expect(unreadNotifications.isEmpty, isTrue);
    });

    test('should delete notification', () async {
      final notification = NotificationModel(
        id: 'test_5',
        title: 'To Delete',
        message: 'Delete me',
        date: DateTime.now(),
        type: NotificationType.error,
        isRead: false,
      );

      await notificationService.addNotification(notification);
      expect(
        notificationService.notifications.any((n) => n.id == 'test_5'),
        isTrue,
      );

      final result = await notificationService.deleteNotification('test_5');
      expect(result, isTrue);
      expect(
        notificationService.notifications.any((n) => n.id == 'test_5'),
        isFalse,
      );
    });

    test('should count unread notifications correctly', () async {
      // Get current unread count
      final initialUnreadCount = notificationService.unreadCount;

      // Add unread notifications
      await notificationService.addNotification(NotificationModel(
        id: 'test_6',
        title: 'Unread 1',
        message: 'Message 1',
        date: DateTime.now(),
        type: NotificationType.info,
        isRead: false,
      ));

      await notificationService.addNotification(NotificationModel(
        id: 'test_7',
        title: 'Unread 2',
        message: 'Message 2',
        date: DateTime.now(),
        type: NotificationType.success,
        isRead: false,
      ));

      expect(
        notificationService.unreadCount,
        equals(initialUnreadCount + 2),
      );

      // Mark one as read
      await notificationService.markAsRead('test_6');
      expect(
        notificationService.unreadCount,
        equals(initialUnreadCount + 1),
      );
    });

    test('should toggle notifications enabled state', () async {
      final initialState = notificationService.notificationsEnabled;

      await notificationService.toggleNotifications();
      expect(
        notificationService.notificationsEnabled,
        equals(!initialState),
      );

      // Toggle back
      await notificationService.toggleNotifications();
      expect(
        notificationService.notificationsEnabled,
        equals(initialState),
      );
    });
  });
}
