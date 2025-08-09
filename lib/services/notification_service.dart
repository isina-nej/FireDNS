import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/models/notification_model.dart';
import '../api/services/notification_api_service.dart';

/// سرویس مدیریت اعلانات
class NotificationService extends ChangeNotifier {
  final NotificationApiService _apiService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _refreshTimer;
  
  // Stream برای اطلاع‌رسانی تغییرات اعلانات
  final _notificationStreamController = StreamController<List<NotificationModel>>.broadcast();
  Stream<List<NotificationModel>> get notificationStream => _notificationStreamController.stream;
  
  NotificationService({NotificationApiService? apiService}) 
      : _apiService = apiService ?? NotificationApiService() {
    // بارگذاری اولیه اعلانات
    fetchNotifications();
    
    // تنظیم تایمر برای بررسی دوره‌ای اعلانات جدید (هر 5 دقیقه)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchNotifications();
    });
  }
  
  /// دریافت اعلانات از سرور
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final response = await _apiService.getNotifications();
      
      if (response.isSuccess && response.data != null) {
        _notifications = response.data!;
        _notificationStreamController.add(_notifications);
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'خطا در دریافت اعلانات';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// علامت‌گذاری اعلان به عنوان خوانده شده
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.markAsRead(notificationId);
      
      if (response.isSuccess && response.data == true) {
        // به‌روزرسانی لیست اعلانات محلی
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final updatedNotification = _notifications[index].copyWith(isRead: true);
          _notifications[index] = updatedNotification;
          _notificationStreamController.add(_notifications);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// علامت‌گذاری همه اعلانات به عنوان خوانده شده
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.markAllAsRead();
      
      if (response.isSuccess && response.data == true) {
        // به‌روزرسانی لیست اعلانات محلی
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _notificationStreamController.add(_notifications);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// حذف اعلان
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.deleteNotification(notificationId);
      
      if (response.isSuccess && response.data == true) {
        // حذف اعلان از لیست محلی
        _notifications.removeWhere((n) => n.id == notificationId);
        _notificationStreamController.add(_notifications);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
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
    _apiService.dispose();
    super.dispose();
  }
}
