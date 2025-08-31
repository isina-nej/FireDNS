import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../path/path.dart';
import '../services/notification_service.dart';
import 'notification_popup.dart';

/// ویجت زنگوله اعلانات با انیمیشن
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    // تنظیم انیمیشن تکان خوردن زنگوله
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.2, end: 0.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
    ]).animate(_animationController);

    // تنظیم تکرار انیمیشن
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (_hasUnreadNotifications && mounted) {
            _animationController.reset();
            _animationController.forward();
          }
        });
      }
    });

    // بررسی وضعیت اعلانات خوانده نشده در اولین رندر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkUnreadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkUnreadNotifications() {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      final hasUnread = notificationService.unreadCount > 0;

      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });

        if (hasUnread && !_animationController.isAnimating) {
          _animationController.reset();
          _animationController.forward();
        }
      }
    } catch (e) {
      // در صورت عدم دسترسی به Provider، خطا را نادیده بگیر
      print('Error accessing NotificationService: $e');
    }
  }

  void _showNotificationPopup() {
    showDialog(
      context: context,
      builder: (context) => const NotificationPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    // استفاده از Builder برای دسترسی به context جدید
    return Builder(
      builder: (builderContext) {
        // تلاش برای دسترسی به NotificationService
        NotificationService? notificationService;
        int unreadCount = 0;
        bool hasUnread = false;

        try {
          notificationService =
              Provider.of<NotificationService>(builderContext, listen: true);
          unreadCount = notificationService.unreadCount;
          hasUnread = unreadCount > 0;

          // اگر وضعیت اعلانات خوانده نشده تغییر کرده باشد
          if (hasUnread != _hasUnreadNotifications) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasUnreadNotifications = hasUnread;
                });

                if (hasUnread && !_animationController.isAnimating) {
                  _animationController.reset();
                  _animationController.forward();
                }
              }
            });
          }
        } catch (e) {
          // در صورت عدم دسترسی به Provider، خطا را نادیده بگیر
          print('Error accessing NotificationService in build: $e');
        }

        return GestureDetector(
          onTap: _showNotificationPopup,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.1,
            height: MediaQuery.of(context).size.width * 0.1,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // زنگوله با انیمیشن
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: child,
                    );
                  },
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark
                        ? AppColors.darkIconPrimary
                        : AppColors.textPrimary,
                    size: MediaQuery.of(context).size.width * 0.06,
                  ),
                ),

                // نشانگر اعلانات خوانده نشده
                if (hasUnread && notificationService != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.fireRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.backgroundWhite,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.fireRed.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width * 0.04,
                        minHeight: MediaQuery.of(context).size.width * 0.04,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
