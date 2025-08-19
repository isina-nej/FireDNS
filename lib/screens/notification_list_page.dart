import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:markdown_widget/markdown_widget.dart';
import '../services/notification_service.dart';
import '../api/models/notification_model.dart';
import '../path/path.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({Key? key}) : super(key: key);

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationService>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اعلان‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NotificationService>().fetchNotifications();
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    service.errorMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => service.fetchNotifications(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            );
          }

          final notifications = service.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'اعلان جدیدی ندارید',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<NotificationService>().fetchNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                // نمایش جدیدترین نوتیفیکیشن‌ها در بالای لیست
                final notification =
                    notifications[notifications.length - 1 - index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade700,
                    ),
                  ),
                  onDismissed: (_) {
                    service.deleteNotification(notification.id);
                  },
                  child: Card(
                    elevation: notification.isRead ? 0 : 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: notification.isRead
                            ? Colors.grey.shade200
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    color: notification.isRead
                        ? Colors.white
                        : Colors.blue.shade50.withOpacity(0.5),
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
                                const SizedBox(width: 12),
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: notification.isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            timeago.format(
                                              notification.date,
                                              locale: 'fa',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (notification.message.isNotEmpty) ...[
                                        const SizedBox(height: 8),
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
                                                style: TextStyle(
                                                  color: AppColors.brightBlue,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (notification.actionUrl?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: 12),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            launchUrl(
                                              Uri.parse(
                                                  notification.actionUrl!),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          },
                                          icon: Icon(
                                            Icons.open_in_new,
                                            size: 16,
                                            color: AppColors.brightBlue,
                                          ),
                                          label: Text(
                                            'مشاهده',
                                            style: TextStyle(
                                              color: AppColors.brightBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
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
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    final (IconData iconData, Color color) = switch (type) {
      NotificationType.info => (Icons.info_outline, Colors.blue),
      NotificationType.warning => (Icons.warning_amber_outlined, Colors.orange),
      NotificationType.error => (Icons.error_outline, Colors.red),
      NotificationType.success => (Icons.check_circle_outline, Colors.green),
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }
}
