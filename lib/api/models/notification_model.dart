/// مدل اعلان برنامه
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final String? imageUrl;
  final String? actionUrl;
  final NotificationType type;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.imageUrl,
    this.actionUrl,
    required this.type,
    this.isRead = false,
  });

  /// Factory constructor برای ایجاد از JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType type = NotificationType.info;
    final typeString = json['type'] as String?;
    if (typeString != null) {
      switch (typeString.toLowerCase()) {
        case 'info':
          type = NotificationType.info;
          break;
        case 'warning':
          type = NotificationType.warning;
          break;
        case 'error':
          type = NotificationType.error;
          break;
        case 'success':
          type = NotificationType.success;
          break;
      }
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
      type: type,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case NotificationType.info:
        typeString = 'info';
        break;
      case NotificationType.warning:
        typeString = 'warning';
        break;
      case NotificationType.error:
        typeString = 'error';
        break;
      case NotificationType.success:
        typeString = 'success';
        break;
    }

    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'type': typeString,
      'isRead': isRead,
    };
  }

  /// ایجاد یک کپی از اعلان با تغییر وضعیت خوانده شدن
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    String? imageUrl,
    String? actionUrl,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, date: $date, imageUrl: $imageUrl, actionUrl: $actionUrl, type: $type, isRead: $isRead)';
  }
}

/// انواع اعلان
enum NotificationType {
  info,
  warning,
  error,
  success,
}