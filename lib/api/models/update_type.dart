/// انواع آپدیت برنامه
enum UpdateType {
  /// آپدیت اجباری - کاربر باید برنامه را به‌روزرسانی کند
  mandatory,

  /// آپدیت مهم - کاربر می‌تواند فعلاً از آن صرف نظر کند
  important,

  /// آپدیت جزئی - کاربر می‌تواند آن را نادیده بگیرد
  minor;

  /// تبدیل رشته به نوع آپدیت
  static UpdateType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'mandatory':
        return UpdateType.mandatory;
      case 'important':
        return UpdateType.important;
      case 'minor':
      default:
        return UpdateType.minor;
    }
  }

  @override
  String toString() {
    switch (this) {
      case UpdateType.mandatory:
        return 'mandatory';
      case UpdateType.important:
        return 'important';
      case UpdateType.minor:
        return 'minor';
    }
  }
}
