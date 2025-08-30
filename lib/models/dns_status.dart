import 'package:flutter/material.dart';

import '../styles/app_colors.dart';

/// مدل وضعیت DNS که شامل اطلاعات پینگ و وضعیت دسترسی است
class DnsStatus {
  final int ping;
  final bool isReachable;

  // رنگ‌های ثابت برای نمایش وضعیت (اکنون از AppColors استفاده می‌کند)
  static const Color unreachableColor = AppColors.pingUnreachable; // قرمز تیره
  static const Color bestPingColor = AppColors.pingExcellent; // سبز
  static const Color mediumPingColor = AppColors.pingMedium; // زرد
  static const Color badPingColor = AppColors.pingBad; // قرمز

  const DnsStatus(this.ping, this.isReachable);

  /// رنگ پس‌زمینه بر اساس وضعیت پینگ
  Color get backgroundColor {
    if (!isReachable) return unreachableColor;
    if (ping <= 50) return bestPingColor;
    if (ping <= 100) return mediumPingColor;
    return badPingColor;
  }

  /// رنگ متن بر اساس وضعیت پینگ
  Color get textColor {
    if (!isReachable) return Colors.white;
    if (ping <= 50) return Colors.white;
    if (ping <= 100) return Colors.black;
    return Colors.white;
  }

  /// آیکون بر اساس وضعیت پینگ
  IconData get icon {
    if (!isReachable) return Icons.signal_wifi_off;
    if (ping <= 50) return Icons.signal_wifi_4_bar;
    if (ping <= 100) return Icons.network_wifi_3_bar;
    return Icons.network_wifi_2_bar;
  }

  /// متن وضعیت بر اساس پینگ
  String get statusText {
    if (!isReachable) return 'غیر قابل دسترسی';
    if (ping <= 50) return 'عالی';
    if (ping <= 100) return 'خوب';
    return 'ضعیف';
  }

  /// متن نمایش برای وضعیت پینگ
  String get displayText {
    if (!isReachable) return 'ناموجود';
    return '$ping ms';
  }

  /// کپی کردن با مقادیر جدید
  DnsStatus copyWith({
    int? ping,
    bool? isReachable,
  }) {
    return DnsStatus(
      ping ?? this.ping,
      isReachable ?? this.isReachable,
    );
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
