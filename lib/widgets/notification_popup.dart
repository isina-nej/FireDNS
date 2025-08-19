import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/models/notification_model.dart';
import '../services/notification_service.dart';
import '../path/path.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// ویجت پاپ‌آپ اعلانات
class NotificationPopup extends StatefulWidget {
  const NotificationPopup({Key? key}) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Schedule notification refresh after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      // Fetch in a new microtask to avoid build phase conflicts
      await Future.microtask(() => notificationService.fetchNotifications());
    } catch (e) {
      print('Error refreshing notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      await notificationService.markAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      await notificationService.markAllAsRead();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      await notificationService.deleteNotification(notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cannotOpenLink')),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('errorOpeningLink')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // استفاده از Builder برای دسترسی به context جدید
    return Builder(builder: (builderContext) {
      ThemeManager? themeManager;
      bool isDark = false;
      NotificationService? notificationService;
      List<NotificationModel> notifications = [];
      bool hasUnread = false;

      try {
        themeManager = Provider.of<ThemeManager>(builderContext);
        isDark = themeManager.isDarkModeActive(builderContext);
      } catch (e) {
        print('Error accessing ThemeManager: $e');
        // مقدار پیش‌فرض برای حالت روشن
        isDark = false;
      }

      try {
        notificationService = Provider.of<NotificationService>(builderContext);
        notifications = notificationService.notifications;
        hasUnread = notificationService.unreadCount > 0;
      } catch (e) {
        print('Error accessing NotificationService: $e');
        // مقادیر پیش‌فرض
        notifications = [];
        hasUnread = false;
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.backgroundGrey.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('notifications'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        if (hasUnread)
                          TextButton.icon(
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: Text(context.tr('markAllAsRead')),
                            onPressed: _markAllAsRead,
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? AppColors.brightBlue
                                  : AppColors.brightBlue,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: isDark
                              ? AppColors.darkIconPrimary
                              : AppColors.iconPrimary,
                          iconSize: 20,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: isDark
                              ? AppColors.brightBlue
                              : AppColors.brightBlue,
                        ),
                      )
                    : notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 48,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('noNotificationsYet'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshNotifications,
                            color: isDark
                                ? AppColors.brightBlue
                                : AppColors.brightBlue,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: notifications.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                        .withOpacity(0.1)
                                    : AppColors.textSecondary.withOpacity(0.1),
                              ),
                              itemBuilder: (context, index) {
                                // معکوس کردن ایندکس برای نمایش جدیدترین‌ها در بالا
                                final notification = notifications[
                                    notifications.length - 1 - index];
                                return _buildNotificationItem(
                                    notification, isDark);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNotificationItem(NotificationModel notification, bool isDark) {
    // تعیین رنگ و آیکون بر اساس نوع اعلان
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.info:
        icon = Icons.info_outline;
        iconColor = isDark ? Colors.blue.shade300 : Colors.blue;
        break;
      case NotificationType.warning:
        icon = Icons.warning_amber_outlined;
        iconColor = isDark ? Colors.orange.shade300 : Colors.orange;
        break;
      case NotificationType.error:
        icon = Icons.error_outline;
        iconColor = isDark ? Colors.red.shade300 : Colors.red;
        break;
      case NotificationType.success:
        icon = Icons.check_circle_outline;
        iconColor = isDark ? Colors.green.shade300 : Colors.green;
        break;
    }

    // تبدیل تاریخ به فرمت مناسب
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm');
    final formattedDate = dateFormat.format(notification.date);

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          _markAsRead(notification.id);
        }
        if (notification.actionUrl != null &&
            notification.actionUrl!.isNotEmpty) {
          _openUrl(notification.actionUrl);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: !notification.isRead
            ? (isDark
                ? AppColors.darkBackground.withOpacity(0.3)
                : AppColors.backgroundGrey.withOpacity(0.2))
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _deleteNotification(notification.id),
                        color: isDark
                            ? AppColors.darkIconPrimary
                            : AppColors.iconPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary.withOpacity(0.7)
                              : AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                      if (notification.actionUrl != null &&
                          notification.actionUrl!.isNotEmpty)
                        Text(
                          context.tr('view'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.brightBlue
                                : AppColors.brightBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
