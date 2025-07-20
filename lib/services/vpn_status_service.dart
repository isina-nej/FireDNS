import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../constants/dns_constants.dart';

/// سرویس مدیریت وضعیت VPN
class VpnStatusService {
  static const _vpnStatusChannel = EventChannel(DnsConstants.vpnStatusChannel);
  static const _dataUsageChannel = EventChannel(DnsConstants.dataUsageChannel);

  // Stream controllers
  static final _vpnStatusController = StreamController<bool>.broadcast();
  static final _dataUsageController =
      StreamController<Map<String, int>>.broadcast();

  // Stream subscriptions
  static StreamSubscription<dynamic>? _vpnStatusSubscription;
  static StreamSubscription<dynamic>? _dataUsageSubscription;

  /// Stream وضعیت VPN
  static Stream<bool> get vpnStatusStream => _vpnStatusController.stream;

  /// Stream مصرف داده
  static Stream<Map<String, int>> get dataUsageStream =>
      _dataUsageController.stream;

  /// شروع listening به وضعیت VPN
  static void startListening() {
    debugPrint('Starting VPN status listening...');

    // Listen to VPN status
    _vpnStatusSubscription = _vpnStatusChannel.receiveBroadcastStream().listen(
      (status) {
        debugPrint('Received VPN status: $status');
        final isActive = status == "VPN_STARTED";
        _vpnStatusController.add(isActive);
      },
      onError: (error) {
        debugPrint('Error listening to VPN status: $error');
        _vpnStatusController.addError(error);
      },
    );

    // Listen to data usage
    _dataUsageSubscription = _dataUsageChannel.receiveBroadcastStream().listen(
      (data) {
        if (data is Map) {
          debugPrint('Received data usage: $data');
          final usage = {
            'download': (data['download'] ?? 0) as int,
            'upload': (data['upload'] ?? 0) as int,
          };
          _dataUsageController.add(usage);
        }
      },
      onError: (error) {
        debugPrint('Error listening to data usage: $error');
        _dataUsageController.addError(error);
      },
    );
  }

  /// توقف listening
  static void stopListening() {
    debugPrint('Stopping VPN status listening...');
    _vpnStatusSubscription?.cancel();
    _dataUsageSubscription?.cancel();
    _vpnStatusSubscription = null;
    _dataUsageSubscription = null;
  }

  /// بستن تمام streams
  static Future<void> dispose() async {
    debugPrint('Disposing VPN status service...');
    stopListening();
    await _vpnStatusController.close();
    await _dataUsageController.close();
  }

  /// ارسال وضعیت VPN به صورت دستی
  static void notifyVpnStatus(bool isActive) {
    if (!_vpnStatusController.isClosed) {
      _vpnStatusController.add(isActive);
    }
  }

  /// ارسال مصرف داده به صورت دستی
  static void notifyDataUsage(int download, int upload) {
    if (!_dataUsageController.isClosed) {
      _dataUsageController.add({'download': download, 'upload': upload});
    }
  }

  /// بررسی وضعیت listening
  static bool get isListening =>
      _vpnStatusSubscription != null && _dataUsageSubscription != null;
}
