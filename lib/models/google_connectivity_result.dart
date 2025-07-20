/// مدل نتیجه تست اتصال Google
class GoogleConnectivityResult {
  final bool googlePing;
  final bool dnsResolution;
  final bool httpsConnectivity;
  final bool overallStatus;
  final String message;

  const GoogleConnectivityResult({
    required this.googlePing,
    required this.dnsResolution,
    required this.httpsConnectivity,
    required this.overallStatus,
    required this.message,
  });

  /// ایجاد از Map
  factory GoogleConnectivityResult.fromMap(Map<String, dynamic> map) {
    return GoogleConnectivityResult(
      googlePing: map['googlePing'] ?? false,
      dnsResolution: map['dnsResolution'] ?? false,
      httpsConnectivity: map['httpsConnectivity'] ?? false,
      overallStatus: map['overallStatus'] ?? false,
      message: map['message'] ?? '',
    );
  }

  /// تبدیل به Map
  Map<String, dynamic> toMap() {
    return {
      'googlePing': googlePing,
      'dnsResolution': dnsResolution,
      'httpsConnectivity': httpsConnectivity,
      'overallStatus': overallStatus,
      'message': message,
    };
  }

  /// کپی کردن با مقادیر جدید
  GoogleConnectivityResult copyWith({
    bool? googlePing,
    bool? dnsResolution,
    bool? httpsConnectivity,
    bool? overallStatus,
    String? message,
  }) {
    return GoogleConnectivityResult(
      googlePing: googlePing ?? this.googlePing,
      dnsResolution: dnsResolution ?? this.dnsResolution,
      httpsConnectivity: httpsConnectivity ?? this.httpsConnectivity,
      overallStatus: overallStatus ?? this.overallStatus,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'GoogleConnectivityResult(googlePing: $googlePing, dnsResolution: $dnsResolution, httpsConnectivity: $httpsConnectivity, overallStatus: $overallStatus, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleConnectivityResult &&
        other.googlePing == googlePing &&
        other.dnsResolution == dnsResolution &&
        other.httpsConnectivity == httpsConnectivity &&
        other.overallStatus == overallStatus &&
        other.message == message;
  }

  @override
  int get hashCode {
    return googlePing.hashCode ^
        dnsResolution.hashCode ^
        httpsConnectivity.hashCode ^
        overallStatus.hashCode ^
        message.hashCode;
  }
}
