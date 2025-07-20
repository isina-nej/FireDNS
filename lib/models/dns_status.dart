import 'package:flutter/material.dart';

/// مدل وضعیت DNS که شامل اطلاعات پینگ و وضعیت دسترسی است
class DnsStatus {
  final int ping;
  final bool isReachable;

  // رنگ‌های ثابت برای نمایش وضعیت
  static const Color unreachableColor = Color(0xFF800000); // قرمز تیره
  static const Color bestPingColor = Color(0xFF4CAF50); // سبز
  static const Color mediumPingColor = Color(0xFFFFC107); // زرد
  static const Color badPingColor = Color(0xFFF44336); // قرمز

  const DnsStatus(this.ping, this.isReachable);

  /// رنگ پس‌زمینه بر اساس وضعیت پینگ
  Color get backgroundColor {
    if (!isReachable) return unreachableColor;

    if (ping < 0) return Colors.grey;

    // اگر پینگ کمتر از 100ms باشد، از سبز به زرد
    if (ping <= 100) {
      return Color.lerp(bestPingColor, mediumPingColor, ping / 100) ??
          bestPingColor;
    }
    // اگر پینگ بین 100ms تا 300ms باشد، از زرد به قرمز
    else if (ping <= 300) {
      return Color.lerp(mediumPingColor, badPingColor, (ping - 100) / 200) ??
          mediumPingColor;
    }
    // اگر پینگ بیشتر از 300ms باشد، قرمز
    else {
      return badPingColor;
    }
  }

  /// متن نمایشی وضعیت
  String get displayText {
    if (!isReachable) return 'ناموجود';
    if (ping < 0) return '--';
    return '$ping ms';
  }

  /// کپی کردن با مقادیر جدید
  DnsStatus copyWith({int? ping, bool? isReachable}) {
    return DnsStatus(ping ?? this.ping, isReachable ?? this.isReachable);
  }

  @override
  String toString() {
    return 'DnsStatus(ping: $ping, isReachable: $isReachable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DnsStatus &&
        other.ping == ping &&
        other.isReachable == isReachable;
  }

  @override
  int get hashCode => ping.hashCode ^ isReachable.hashCode;
}
