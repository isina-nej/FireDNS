import 'package:firedns/api/models/notification_model.dart';
import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class NotificationListPage extends StatefulWidget {
  final String? highlightNotificationId;

  const NotificationListPage({super.key, this.highlightNotificationId});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();
  String? _highlightedNotificationId;

  @override
  void initState() {
    super.initState();
    _highlightedNotificationId = widget.highlightNotificationId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationService>().fetchNotifications().then((_) {
        if (widget.highlightNotificationId != null) {
          _scrollToNotification(widget.highlightNotificationId!);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNotification(String notificationId) {
    final service = context.read<NotificationService>();
    final notifications = service.notifications;

    // پیدا کردن ایندکس نوتیف (با در نظر گیری معکوس بودن لیست)
    final originalIndex =
        notifications.indexWhere((n) => n.id == notificationId);
    if (originalIndex != -1) {
      final reversedIndex = notifications.length - 1 - originalIndex;

      // محاسبه موقعیت تقریبی
      const itemHeight = 150.0; // تقریبی ارتفاع هر آیتم
      final targetOffset = reversedIndex * itemHeight;

      // scroll کردن به آن موقعیت
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      // پاک کردن highlight بعد از مدتی
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedNotificationId = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      final isDark = themeController.isDarkModeActive(context);

      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.backgroundLight,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? AppColors.darkTextPrimary : Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(context.tr('notifications'),
                style: AppTextStyles.appBarTitle(context)),
            backgroundColor:
                isDark ? AppColors.darkCardBackground : AppColors.primaryBlue,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.tr('refreshNotifications'),
                onPressed: () {
                  context.read<NotificationService>().fetchNotifications();
                },
              ),
            ],
            elevation: 0,
          ),
          body: Consumer<NotificationService>(
            builder: (context, service, _) {
              if (service.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.primaryBlue),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Text(context.tr('loadingNotifications'),
                          style: AppTextStyles.bodyMedium(context)),
                    ],
                  ),
                );
              }

              if (service.errorMessage.isNotEmpty) {
                return Center(
                  child: Card(
                    color: AppColors.backgroundLight,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: MediaQuery.of(context).size.width * 0.12,
                              color: AppColors.textError),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                          Text(service.errorMessage,
                              style: AppTextStyles.error(context),
                              textAlign: TextAlign.center),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          TextButton.icon(
                            onPressed: () => service.fetchNotifications(),
                            icon: const Icon(Icons.refresh),
                            label: Text(context.tr('tryAgain'),
                                style: AppTextStyles.buttonMedium(context)),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  AppColors.primaryBlue.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final notifications = service.notifications;

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: MediaQuery.of(context).size.height * 0.06,
                          color: AppColors.iconSecondary),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Text(context.tr('noNotificationsYet'),
                          style: AppTextStyles.bodyMedium(context)
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context
                      .read<NotificationService>()
                      .fetchNotifications();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification =
                        notifications[notifications.length - 1 - index];
                    final isHighlighted =
                        _highlightedNotificationId == notification.id;

                    return Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppColors.textError.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(Icons.delete_outline,
                            color: AppColors.textError,
                            size: MediaQuery.of(context).size.width * 0.07),
                      ),
                      onDismissed: (_) {
                        service.deleteNotification(notification.id);
                      },
                      child: Card(
                        elevation: notification.isRead ? 0 : 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isHighlighted
                                ? AppColors.brightBlue
                                : (notification.isRead
                                    ? AppColors.cardBorder
                                    : Colors.transparent),
                            width: isHighlighted
                                ? MediaQuery.of(context).size.width * 0.005
                                : MediaQuery.of(context).size.width * 0.0025,
                          ),
                        ),
                        color: isHighlighted
                            ? AppColors.selectedLight
                            : (notification.isRead
                                ? AppColors.backgroundWhite
                                : AppColors.selectedLight
                                    .withValues(alpha: 0.7)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (!notification.isRead) {
                              service.markAsRead(notification.id);
                            }
                            if (notification.actionUrl != null &&
                                notification.actionUrl!.isNotEmpty) {
                              launchUrl(
                                Uri.parse(notification.actionUrl!),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _getNotificationIcon(notification.type),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification.title,
                                                  style: notification.isRead
                                                      ? AppTextStyles
                                                          .titleSmall(context)
                                                      : AppTextStyles
                                                          .titleMedium(context),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.02),
                                              Text(
                                                timeago.format(
                                                    notification.date,
                                                    locale: context
                                                        .languageManager
                                                        .locale
                                                        .languageCode),
                                                style: AppTextStyles.caption(
                                                    context),
                                              ),
                                            ],
                                          ),
                                          if (notification
                                              .message.isNotEmpty) ...[
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.01),
                                            MarkdownWidget(
                                              data: notification.message,
                                              shrinkWrap: true,
                                              config: MarkdownConfig(
                                                configs: [
                                                  LinkConfig(
                                                    onTap: (url) {
                                                      launchUrl(
                                                        Uri.parse(url),
                                                        mode: LaunchMode
                                                            .externalApplication,
                                                      );
                                                    },
                                                    style: AppTextStyles
                                                            .bodyMedium(context)
                                                        .copyWith(
                                                      color:
                                                          AppColors.brightBlue,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (notification
                                                  .actionUrl?.isNotEmpty ==
                                              true) ...[
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.015),
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                backgroundColor:
                                                    AppColors.selectedLight,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              onPressed: () {
                                                launchUrl(
                                                  Uri.parse(
                                                      notification.actionUrl!),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              },
                                              icon: Icon(Icons.open_in_new,
                                                  size: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.04,
                                                  color: AppColors.brightBlue),
                                              label: Text(context.tr('view'),
                                                  style: AppTextStyles
                                                          .buttonMedium(context)
                                                      .copyWith(
                                                          color: AppColors
                                                              .brightBlue)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _getNotificationIcon(NotificationType type) {
    // final themeController = Get.find<ThemeController>();
    // final isDark = themeController.isDarkModeActive(context);

    late IconData iconData;
    late Color color;
    switch (type) {
      case NotificationType.info:
        iconData = Icons.info_outline;
        color = AppColors.brightBlue;
        break;
      case NotificationType.warning:
        iconData = Icons.warning_amber_outlined;
        color = AppColors.textWarning;
        break;
      case NotificationType.error:
        iconData = Icons.error_outline;
        color = AppColors.textError;
        break;
      case NotificationType.success:
        iconData = Icons.check_circle_outline;
        color = AppColors.textSuccess;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: MediaQuery.of(context).size.width * 0.06,
      ),
    );
  }
}
