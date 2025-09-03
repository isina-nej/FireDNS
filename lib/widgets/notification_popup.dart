import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models/notification_model.dart';
import '../controllers/theme_controller.dart';
import '../path/path.dart';
import '../services/navigation_service.dart';

/// ویجت پاپ‌آپ اعلانات با طراحی بهبود یافته
class NotificationPopup extends StatefulWidget {
  const NotificationPopup({super.key});

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Load notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      await Future.microtask(() => notificationService.fetchNotifications());
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('errorLoadingNotifications')),
            backgroundColor: AppColors.fireRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      final success = await notificationService.markAllAsRead();

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.pureWhite,
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Text(context.tr('allNotificationsMarkedAsRead')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      final success =
          await notificationService.deleteNotification(notificationId);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: AppColors.pureWhite,
                  size: MediaQuery.of(context).size.width * 0.05,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Text(context.tr('notificationDeleted')),
              ],
            ),
            backgroundColor: AppColors.fireRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cannotOpenLink')),
            backgroundColor: AppColors.fireRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: context.tr('tryAgain'),
              textColor: AppColors.pureWhite,
              onPressed: () => _openUrl(url),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('errorOpeningLink')),
            backgroundColor: AppColors.fireRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _closePopup() async {
    await _fadeController.reverse();
    await _slideController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Obx(
          () {
            final themeController = Get.find<ThemeController>();
            final notificationService = Get.find<NotificationService>();
            final isDark = themeController.isDarkMode;
            final notifications = notificationService.notifications;
            final hasUnread = notificationService.unreadCount > 0;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                        maxHeight: MediaQuery.of(context).size.height * 0.8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.06),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.12),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModernHeader(context, isDark, hasUnread,
                            notificationService.unreadCount),
                        _buildModernBody(context, isDark, notifications),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernHeader(
      BuildContext context, bool isDark, bool hasUnread, int unreadCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.darkBackground.withValues(alpha: 0.9),
                ]
              : [
                  AppColors.backgroundWhite,
                  AppColors.brightBlue.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.1)
                : AppColors.textSecondary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Notification Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brightBlue.withValues(alpha: 0.15),
                      AppColors.gradientOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.brightBlue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.brightBlue,
                  size: MediaQuery.of(context).size.width * 0.07,
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.fireRed,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.backgroundWhite,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(width: MediaQuery.of(context).size.width * 0.05),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('notifications'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                Text(
                  hasUnread
                      ? context
                          .tr('youHaveUnreadNotifications')
                          .replaceAll('{count}', unreadCount.toString())
                      : context.tr('allNotificationsRead'),
                  style: TextStyle(
                    fontSize: 13,
                    color: hasUnread
                        ? AppColors.brightBlue
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasUnread)
                _buildHeaderButton(
                  context,
                  icon: Icons.done_all_rounded,
                  onPressed: _markAllAsRead,
                  tooltip: context.tr('markAllAsRead'),
                  color: Colors.green.shade600,
                  isDark: isDark,
                ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              _buildHeaderButton(
                context,
                icon: Icons.refresh_rounded,
                onPressed: _refreshNotifications,
                tooltip: context.tr('refreshNotifications'),
                color:
                    isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                isDark: isDark,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              _buildHeaderButton(
                context,
                icon: Icons.close_rounded,
                onPressed: _closePopup,
                tooltip: context.tr('close'),
                color:
                    isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernBody(BuildContext context, bool isDark,
      List<NotificationModel> notifications) {
    if (_isLoading) {
      return _buildLoadingState(context, isDark);
    }

    if (notifications.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return _buildNotificationsList(context, isDark, notifications);
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brightBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.brightBlue,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Text(
              context.tr('loadingNotifications'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              context.tr('pleaseWait'),
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                    : AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark
                          ? AppColors.darkTextSecondary.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                      isDark
                          ? AppColors.darkTextSecondary.withValues(alpha: 0.05)
                          : AppColors.textSecondary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: MediaQuery.of(context).size.width * 0.14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                context.tr('noNotificationsYet'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                context.tr('notificationsWillAppearHere'),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.8)
                      : AppColors.textSecondary.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              TextButton.icon(
                onPressed: _refreshNotifications,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: MediaQuery.of(context).size.width * 0.045,
                  color: AppColors.brightBlue,
                ),
                label: Text(
                  context.tr('checkForNotifications'),
                  style: const TextStyle(
                    color: AppColors.brightBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: AppColors.brightBlue.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, bool isDark,
      List<NotificationModel> notifications) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: AppColors.brightBlue,
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.backgroundWhite,
        strokeWidth: 2.5,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.1)
                      : AppColors.textSecondary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          itemBuilder: (context, index) {
            // عکس کردن ترتیب برای نمایش جدیدترین‌ها در بالا
            final notification =
                notifications[notifications.length - 1 - index];
            return _buildModernNotificationItem(context, notification, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildModernNotificationItem(
      BuildContext context, NotificationModel notification, bool isDark) {
    final (IconData icon, Color iconColor, Color backgroundColor) =
        _getNotificationStyle(notification.type, isDark);
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm');
    final formattedDate = dateFormat.format(notification.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: !notification.isRead
            ? (isDark
                ? AppColors.brightBlue.withValues(alpha: 0.08)
                : AppColors.brightBlue.withValues(alpha: 0.04))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: !notification.isRead
            ? Border.all(
                color: AppColors.brightBlue.withValues(alpha: 0.25),
                width: 1.5,
              )
            : Border.all(
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.1)
                    : AppColors.textSecondary.withValues(alpha: 0.08),
                width: 1,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Type Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: MediaQuery.of(context).size.width * 0.055,
                  ),
                ),

                SizedBox(width: MediaQuery.of(context).size.width * 0.04),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.025,
                              height: MediaQuery.of(context).size.width * 0.025,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.brightBlue,
                                    AppColors.gradientOrange,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brightBlue
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),

                      // Message
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Date
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                      .withValues(alpha: 0.1)
                                  : AppColors.textSecondary
                                      .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                        .withValues(alpha: 0.9)
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Action Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (notification.actionUrl != null &&
                                  notification.actionUrl!.isNotEmpty)
                                _buildActionButton(
                                  context,
                                  icon: Icons.open_in_new_rounded,
                                  onPressed: () =>
                                      _openUrl(notification.actionUrl),
                                  tooltip: context.tr('openLink'),
                                  color: AppColors.brightBlue,
                                  isDark: isDark,
                                ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              _buildActionButton(
                                context,
                                icon: Icons.delete_outline_rounded,
                                onPressed: () =>
                                    _deleteNotification(notification.id),
                                tooltip: context.tr('deleteNotification'),
                                color: AppColors.fireRed,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: MediaQuery.of(context).size.width * 0.04,
            color: color,
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _getNotificationStyle(
      NotificationType type, bool isDark) {
    return switch (type) {
      NotificationType.info => (
          Icons.info_outline_rounded,
          isDark
              ? AppColors.brightBlue.withValues(alpha: 0.9)
              : AppColors.brightBlue,
          isDark
              ? AppColors.brightBlue.withValues(alpha: 0.15)
              : AppColors.brightBlue.withValues(alpha: 0.1),
        ),
      NotificationType.warning => (
          Icons.warning_amber_outlined,
          isDark
              ? AppColors.gradientOrange.withValues(alpha: 0.9)
              : AppColors.gradientOrange,
          isDark
              ? AppColors.gradientOrange.withValues(alpha: 0.15)
              : AppColors.gradientOrange.withValues(alpha: 0.1),
        ),
      NotificationType.error => (
          Icons.error_outline_rounded,
          isDark ? AppColors.fireRed.withValues(alpha: 0.9) : AppColors.fireRed,
          isDark
              ? AppColors.fireRed.withValues(alpha: 0.15)
              : AppColors.fireRed.withValues(alpha: 0.1),
        ),
      NotificationType.success => (
          Icons.check_circle_outline_rounded,
          isDark ? Colors.green.shade400 : Colors.green.shade600,
          isDark
              ? Colors.green.shade400.withValues(alpha: 0.15)
              : Colors.green.shade600.withValues(alpha: 0.1),
        ),
    };
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if unread
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Close popup with animation
    _closePopup();

    // Navigate to notifications page
    NavigationService.navigateToRoute(
      '/notifications',
      arguments: {
        'highlightNotificationId': notification.id,
      },
    );
  }
}
