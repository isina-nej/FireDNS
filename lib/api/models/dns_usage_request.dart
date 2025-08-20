class DnsUsageRequest {
  final DnsInfo dns;
  final DateTime timestamp;
  final ConnectionType connectionType;
  final NetworkInfo networkInfo;

  DnsUsageRequest({
    required this.dns,
    required this.timestamp,
    required this.connectionType,
    required this.networkInfo,
  });

  Map<String, dynamic> toJson() => {
        'dns': dns.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'connection_type': connectionType.toString().split('.').last,
        'network_info': networkInfo.toJson(),
      };
}

class DnsInfo {
  final String label;
  final String ip1;
  final String ip2;

  DnsInfo({
    required this.label,
    required this.ip1,
    required this.ip2,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'ip1': ip1,
        'ip2': ip2,
      };
}

enum ConnectionType {
  connected,
  disconnected,
}

class DeviceInfo {
  final String deviceType; // android/ios/windows
  final String brand; // برند دستگاه (مثل Samsung, Xiaomi)
  final String model; // مدل دستگاه
  final String osVersion; // نسخه سیستم عامل

  DeviceInfo({
    required this.deviceType,
    required this.brand,
    required this.model,
    required this.osVersion,
  });

  Map<String, dynamic> toJson() => {
        'device_type': deviceType,
        'brand': brand,
        'model': model,
        'os_version': osVersion,
      };
}

class NetworkInfo {
  final String connectionType; // WIFI/MOBILE/HAMRAHAVAL/IRANCELL etc.
  final String? carrierName; // نام واقعی اپراتور
  final String? ipAddress; // آی‌پی واقعی کاربر
  final String? mobileNetworkType; // نوع شبکه واقعی

  NetworkInfo({
    required this.connectionType,
    this.carrierName,
    this.ipAddress,
    this.mobileNetworkType,
  });

  Map<String, dynamic> toJson() => {
        'connection_type': connectionType,
        'carrier_name': carrierName,
        'ip_address': ipAddress,
        'mobile_network_type': mobileNetworkType,
      };
}
