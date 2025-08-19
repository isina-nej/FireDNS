import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/models/notification_model.dart';
import './notification_cache_service.dart';

/// سرویس مدیریت اعلانات
class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _refreshTimer;
  bool _notificationsEnabled = true; // وضعیت فعال بودن اعلان‌ها
  int _unreadCount = 0;

  static const String _notificationsEnabledKey = 'notifications_enabled';

  // Stream برای اطلاع‌رسانی تغییرات اعلانات
  final _notificationStreamController =
      StreamController<List<NotificationModel>>.broadcast();
  Stream<List<NotificationModel>> get notificationStream =>
      _notificationStreamController.stream;

  NotificationService() {
    // بارگذاری تنظیمات و اعلانات
    _loadInitialData();
  }

  /// راه‌اندازی اولیه سرویس به صورت async
  void _loadInitialData() {
    _notificationsEnabled = true; // مقدار پیش‌فرض
    // بارگذاری async تنظیمات و اعلانات
    Future(() async {
      await _loadNotificationSettings();
      await fetchNotifications();
    });
  }

  /// بارگذاری تنظیمات اعلان‌ها
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      // اینجا نیازی به notifyListeners نیست چون در fetchNotifications فراخوانی می‌شود
    } catch (e) {
      print('Error loading notification settings: $e');
      _notificationsEnabled = true;
    }
  }

  /// ذخیره تنظیمات اعلان‌ها
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  /// فعال/غیرفعال کردن اعلان‌ها
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    await _saveNotificationSettings();
  }

  /// آیا اعلان‌ها فعال هستند؟
  bool get notificationsEnabled => _notificationsEnabled;

  /// دریافت اعلانات از کش
  Future<void> fetchNotifications() async {
    print('Fetching notifications...');
    if (!_notificationsEnabled) {
      print('Notifications are disabled');
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('Getting notifications from cache...');
      final notifications =
          await NotificationCacheService.getCachedNotifications();
      _notifications =
          notifications.reversed.toList(); // نمایش جدیدترین‌ها در ابتدا
      print('Received ${_notifications.length} notifications from cache');

      if (_notifications.isEmpty) {
        print('Adding test notification...');
        final testNotification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'به FireDNS خوش آمدید',
          message: 'این یک اعلان تستی برای نمایش قابلیت‌های برنامه است.',
          date: DateTime.now(),
          type: NotificationType.info,
        );
        await addNotification(testNotification);
      }

      _unreadCount = _notifications.where((n) => !n.isRead).length;
      print('Unread count: $_unreadCount');
      _notificationStreamController.add(_notifications);
    } catch (e) {
      _errorMessage = 'خطا در دریافت اعلانات';
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('Fetch complete. Has notifications: ${_notifications.isNotEmpty}');
    }
  }

  /// اضافه کردن نوتیفیکیشن جدید
  Future<void> addNotification(NotificationModel notification) async {
    try {
      print('Adding notification: ${notification.id}');

      // اضافه کردن به لیست محلی
      _notifications.insert(0, notification);
      _notificationStreamController.add(_notifications);
      notifyListeners();

      // ذخیره در کش
      final success =
          await NotificationCacheService.addNotification(notification);
      if (!success) {
        print('Failed to cache notification');
        // حذف از لیست محلی در صورت خطا
        _notifications.removeAt(0);
        _notificationStreamController.add(_notifications);
        notifyListeners();
        _errorMessage = 'خطا در ذخیره اعلان';
      } else {
        print('Successfully added and cached notification');
        // تایید با بازخوانی از کش
        final cached = await NotificationCacheService.getCachedNotifications();
        print('Verified cached notifications count: ${cached.length}');
      }
    } catch (e) {
      print('Error adding notification: $e');
      _errorMessage = 'خطا در ذخیره اعلان';
      notifyListeners();
    }
  }

  /// علامت‌گذاری اعلان به عنوان خوانده شده
  Future<bool> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotification =
            _notifications[index].copyWith(isRead: true);
        _notifications[index] = updatedNotification;
        await NotificationCacheService.markAsRead(notificationId);
        _notificationStreamController.add(_notifications);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// علامت‌گذاری همه اعلانات به عنوان خوانده شده
  Future<bool> markAllAsRead() async {
    try {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      await NotificationCacheService.markAllAsRead();
      _notificationStreamController.add(_notifications);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// حذف اعلان
  Future<bool> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await NotificationCacheService.removeNotification(notificationId);
      _notificationStreamController.add(_notifications);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// دریافت تعداد اعلانات خوانده نشده
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// دریافت لیست اعلانات
  List<NotificationModel> get notifications => _notifications;

  /// آیا در حال بارگذاری است؟
  bool get isLoading => _isLoading;

  /// پیام خطا
  String get errorMessage => _errorMessage;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationStreamController.close();
    super.dispose();
  }
}
