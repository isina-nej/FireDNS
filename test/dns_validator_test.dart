import 'package:flutter_test/flutter_test.dart';
import 'package:firedns/utils/dns_validator.dart';

void main() {
  group('DnsValidator', () {
    test('should validate correct IPv4 addresses', () {
      expect(DnsValidator.isValidDns('192.168.1.1'), true);
      expect(DnsValidator.isValidDns('8.8.8.8'), true);
      expect(DnsValidator.isValidDns('1.1.1.1'), true);
      expect(DnsValidator.isValidDns('255.255.255.255'), true);
    });

    test('should reject invalid IPv4 addresses', () {
      expect(DnsValidator.isValidDns(''), false);
      expect(DnsValidator.isValidDns('192.168.1'), false);
      expect(DnsValidator.isValidDns('192.168.1.1.1'), false);
      expect(DnsValidator.isValidDns('256.1.1.1'), false);
      expect(DnsValidator.isValidDns('192.168.1.256'), false);
      expect(DnsValidator.isValidDns('abc.def.ghi.jkl'), false);
    });

    test('should identify private IPs', () {
      expect(DnsValidator.isPrivateIp('192.168.1.1'), true);
      expect(DnsValidator.isPrivateIp('10.0.0.1'), true);
      expect(DnsValidator.isPrivateIp('172.16.0.1'), true);
      expect(DnsValidator.isPrivateIp('8.8.8.8'), false);
    });

    test('should identify localhost', () {
      expect(DnsValidator.isLocalhost('127.0.0.1'), true);
      expect(DnsValidator.isLocalhost('192.168.1.1'), false);
    });

    test('should sanitize DNS addresses', () {
      expect(DnsValidator.sanitizeDns('  8.8.8.8  '), '8.8.8.8');
      expect(DnsValidator.sanitizeDns('192.168.1.1'), '192.168.1.1');
    });

    test('should provide validation error messages', () {
      expect(
          DnsValidator.getValidationError(''), 'آدرس DNS نمی‌تواند خالی باشد');
      expect(
          DnsValidator.getValidationError('invalid'), 'فرمت آدرس IP صحیح نیست');
      expect(DnsValidator.getValidationError('127.0.0.1'),
          'آدرس localhost برای DNS مناسب نیست');
      expect(DnsValidator.getValidationError('8.8.8.8'), '');
    });
  });
}
