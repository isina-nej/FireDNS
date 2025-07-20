/// انواع DNS موجود
enum DnsType {
  general,
  radar,
  shekan,
  irancell,
  hamrahaval,
  gaming,
  telecom,
  other,
  ipv6,
  google,
}

/// تبدیل string به DnsType
DnsType dnsTypeFromString(String value) {
  switch (value.toUpperCase()) {
    case 'GENERAL':
      return DnsType.general;
    case 'RADAR':
      return DnsType.radar;
    case 'SHEKAN':
      return DnsType.shekan;
    case 'IRANCELL':
      return DnsType.irancell;
    case 'HAMRAHAVAL':
      return DnsType.hamrahaval;
    case 'GAMING':
      return DnsType.gaming;
    case 'TELECOM':
      return DnsType.telecom;
    case 'OTHER':
      return DnsType.other;
    case 'IPV6':
      return DnsType.ipv6;
    case 'GOOGLE':
      return DnsType.google;
    default:
      return DnsType.other;
  }
}

/// تبدیل DnsType به string
String dnsTypeToString(DnsType type) {
  switch (type) {
    case DnsType.general:
      return 'GENERAL';
    case DnsType.radar:
      return 'RADAR';
    case DnsType.shekan:
      return 'SHEKAN';
    case DnsType.irancell:
      return 'IRANCELL';
    case DnsType.hamrahaval:
      return 'HAMRAHAVAL';
    case DnsType.gaming:
      return 'GAMING';
    case DnsType.telecom:
      return 'TELECOM';
    case DnsType.other:
      return 'OTHER';
    case DnsType.ipv6:
      return 'IPV6';
    case DnsType.google:
      return 'GOOGLE';
  }
}

/// مدل رکورد DNS
class DnsRecord {
  final String id;
  final String label;
  final String ip1;
  final String ip2;
  final DnsType type;
  final DateTime createdAt;

  const DnsRecord({
    required this.id,
    required this.label,
    required this.ip1,
    required this.ip2,
    required this.type,
    required this.createdAt,
  });

  /// Factory constructor برای ایجاد از JSON
  factory DnsRecord.fromJson(Map<String, dynamic> json) {
    return DnsRecord(
      id: json['id'] as String,
      label: json['label'] as String,
      ip1: json['ip1'] as String,
      ip2: json['ip2'] as String,
      type: dnsTypeFromString(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'ip1': ip1,
      'ip2': ip2,
      'type': dnsTypeToString(type),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// کپی کردن با مقادیر جدید
  DnsRecord copyWith({
    String? id,
    String? label,
    String? ip1,
    String? ip2,
    DnsType? type,
    DateTime? createdAt,
  }) {
    return DnsRecord(
      id: id ?? this.id,
      label: label ?? this.label,
      ip1: ip1 ?? this.ip1,
      ip2: ip2 ?? this.ip2,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DnsRecord(id: $id, label: $label, ip1: $ip1, ip2: $ip2, type: $type, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DnsRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// مدل درخواست ایجاد/ویرایش DNS
class DnsRecordRequest {
  final String label;
  final String ip1;
  final String ip2;
  final DnsType type;

  const DnsRecordRequest({
    required this.label,
    required this.ip1,
    required this.ip2,
    required this.type,
  });

  /// Factory constructor برای ایجاد از JSON
  factory DnsRecordRequest.fromJson(Map<String, dynamic> json) {
    return DnsRecordRequest(
      label: json['label'] as String,
      ip1: json['ip1'] as String,
      ip2: json['ip2'] as String,
      type: dnsTypeFromString(json['type'] as String),
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'ip1': ip1,
      'ip2': ip2,
      'type': dnsTypeToString(type),
    };
  }

  /// ایجاد از DnsRecord
  factory DnsRecordRequest.fromDnsRecord(DnsRecord record) {
    return DnsRecordRequest(
      label: record.label,
      ip1: record.ip1,
      ip2: record.ip2,
      type: record.type,
    );
  }

  @override
  String toString() {
    return 'DnsRecordRequest(label: $label, ip1: $ip1, ip2: $ip2, type: $type)';
  }
}

/// Extension برای کار راحت‌تر با DnsType
extension DnsTypeExtension on DnsType {
  /// نام نمایشی نوع DNS
  String get displayName {
    switch (this) {
      case DnsType.general:
        return 'عمومی';
      case DnsType.radar:
        return 'رادار گیمز';
      case DnsType.shekan:
        return 'شکن';
      case DnsType.irancell:
        return 'ایرانسل';
      case DnsType.hamrahaval:
        return 'همراه اول';
      case DnsType.gaming:
        return 'گیمینگ';
      case DnsType.telecom:
        return 'مخابرات';
      case DnsType.other:
        return 'سایر';
      case DnsType.ipv6:
        return 'IPv6';
      case DnsType.google:
        return 'گوگل';
    }
  }

  /// رنگ مربوط به نوع DNS
  int get colorValue {
    switch (this) {
      case DnsType.general:
        return 0xFF2196F3; // آبی
      case DnsType.radar:
        return 0xFF9C27B0; // بنفش
      case DnsType.shekan:
        return 0xFF4CAF50; // سبز
      case DnsType.irancell:
        return 0xFFFF9800; // نارنجی
      case DnsType.hamrahaval:
        return 0xFFE91E63; // صورتی
      case DnsType.gaming:
        return 0xFFF44336; // قرمز
      case DnsType.telecom:
        return 0xFF795548; // قهوه‌ای
      case DnsType.other:
        return 0xFF607D8B; // خاکستری آبی
      case DnsType.ipv6:
        return 0xFF3F51B5; // ایندیگو
      case DnsType.google:
        return 0xFF009688; // سبز آبی
    }
  }
}
