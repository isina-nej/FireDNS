import 'package:flutter_test/flutter_test.dart';
import 'package:firedns/services/dns_service.dart';
import 'package:firedns/models/dns_status.dart';

void main() {
  group('DnsService', () {
    test('should create DnsStatus correctly', () {
      final status = DnsStatus(50, true);
      expect(status.ping, 50);
      expect(status.isReachable, true);
      expect(status.displayText, '50 ms');
    });

    test('should handle unreachable DNS', () {
      final status = DnsStatus(-1, false);
      expect(status.ping, -1);
      expect(status.isReachable, false);
      expect(status.displayText, 'ناموجود');
    });

    test('should copy DnsStatus with new values', () {
      final original = DnsStatus(100, true);
      final copy = original.copyWith(ping: 50);
      expect(copy.ping, 50);
      expect(copy.isReachable, true);
    });

    test('should create DnsChangeResult correctly', () {
      final result =
          DnsChangeResult(success: true, message: 'Success', errorCode: 'OK');
      expect(result.success, true);
      expect(result.message, 'Success');
      expect(result.errorCode, 'OK');
    });
  });
}
