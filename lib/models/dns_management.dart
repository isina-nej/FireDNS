/// وضعیت مدیریت DNS
enum DnsManagementStatus {
  /// DNS فعال و قابل استفاده
  active,

  /// DNS مسدود شده (نمایش داده نمی‌شود در تست‌ها)
  blocked,

  /// DNS حذف شده از کش (اگر سروری باشد، دوباره می‌آید)
  deleted,

  /// DNS گزارش شده (حذف شده و هرگز دوباره ذخیره نمی‌شود)
  reported,
}

/// مدل‌های مدیریت DNS برای سیستم حرفه‌ای مدیریت DNS
class DnsManagementRecord {
  final String dnsId;
  final String dnsLabel;
  final String dnsIp1;
  final String? dnsIp2;
  final DnsManagementStatus status;
  final DateTime timestamp;
  final String? reason; // دلیل مسدودسازی یا گزارش

  const DnsManagementRecord({
    required this.dnsId,
    required this.dnsLabel,
    required this.dnsIp1,
    this.dnsIp2,
    required this.status,
    required this.timestamp,
    this.reason,
  });

  /// Factory constructor برای ایجاد از JSON
  factory DnsManagementRecord.fromJson(Map<String, dynamic> json) {
    return DnsManagementRecord(
      dnsId: json['dnsId'] as String,
      dnsLabel: json['dnsLabel'] as String,
      dnsIp1: json['dnsIp1'] as String,
      dnsIp2: json['dnsIp2'] as String?,
      status: _statusFromString(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      reason: json['reason'] as String?,
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'dnsId': dnsId,
      'dnsLabel': dnsLabel,
      'dnsIp1': dnsIp1,
      'dnsIp2': dnsIp2,
      'status': _statusToString(status),
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
    };
  }

  /// کپی کردن با مقادیر جدید
  DnsManagementRecord copyWith({
    String? dnsId,
    String? dnsLabel,
    String? dnsIp1,
    String? dnsIp2,
    DnsManagementStatus? status,
    DateTime? timestamp,
    String? reason,
  }) {
    return DnsManagementRecord(
      dnsId: dnsId ?? this.dnsId,
      dnsLabel: dnsLabel ?? this.dnsLabel,
      dnsIp1: dnsIp1 ?? this.dnsIp1,
      dnsIp2: dnsIp2 ?? this.dnsIp2,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
    );
  }

  static DnsManagementStatus _statusFromString(String value) {
    switch (value) {
      case 'blocked':
        return DnsManagementStatus.blocked;
      case 'deleted':
        return DnsManagementStatus.deleted;
      case 'reported':
        return DnsManagementStatus.reported;
      case 'active':
      default:
        return DnsManagementStatus.active;
    }
  }

  static String _statusToString(DnsManagementStatus status) {
    switch (status) {
      case DnsManagementStatus.blocked:
        return 'blocked';
      case DnsManagementStatus.deleted:
        return 'deleted';
      case DnsManagementStatus.reported:
        return 'reported';
      case DnsManagementStatus.active:
        return 'active';
    }
  }

  @override
  String toString() {
    return 'DnsManagementRecord(dnsId: $dnsId, dnsLabel: $dnsLabel, status: $status, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DnsManagementRecord && other.dnsId == dnsId;
  }

  @override
  int get hashCode => dnsId.hashCode;
}

/// مدل نتیجه عملیات مدیریت DNS
class DnsManagementResult {
  final bool success;
  final String message;
  final DnsManagementRecord? record;

  const DnsManagementResult({
    required this.success,
    required this.message,
    this.record,
  });
}

/// مدل آمار مدیریت DNS
class DnsManagementStats {
  final int totalBlocked;
  final int totalDeleted;
  final int totalReported;
  final int totalManaged;

  const DnsManagementStats({
    required this.totalBlocked,
    required this.totalDeleted,
    required this.totalReported,
    required this.totalManaged,
  });

  int get total => totalBlocked + totalDeleted + totalReported;
}
