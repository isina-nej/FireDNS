import 'package:firedns/api/models/dns_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DnsRecord Tests', () {
    test('should create DNS record with valid data', () {
      // Arrange & Act
      final record = DnsRecord(
        id: '1',
        label: 'Cloudflare',
        ip1: '1.1.1.1',
        ip2: '1.0.0.1',
        type: DnsType.general,
        createdAt: DateTime.now(),
      );

      // Assert
      expect(record.id, equals('1'));
      expect(record.label, equals('Cloudflare'));
      expect(record.ip1, equals('1.1.1.1'));
      expect(record.ip2, equals('1.0.0.1'));
      expect(record.type, equals(DnsType.general));
    });

    test('should create DNS record with null ip2', () {
      // Arrange & Act
      final record = DnsRecord(
        id: '2',
        label: 'Single IP DNS',
        ip1: '8.8.8.8',
        ip2: null,
        type: DnsType.google,
        createdAt: DateTime.now(),
      );

      // Assert
      expect(record.ip2, isNull);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final record = DnsRecord(
        id: '1',
        label: 'Test DNS',
        ip1: '1.1.1.1',
        ip2: '1.0.0.1',
        type: DnsType.general,
        createdAt: now,
      );

      // Act
      final json = record.toJson();

      // Assert
      expect(json['id'], equals('1'));
      expect(json['label'], equals('Test DNS'));
      expect(json['ip1'], equals('1.1.1.1'));
      expect(json['ip2'], equals('1.0.0.1'));
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'id': '1',
        'label': 'Test DNS',
        'ip1': '1.1.1.1',
        'ip2': '1.0.0.1',
        'type': 'GENERAL',
        'createdAt': '2025-01-01T00:00:00.000Z',
      };

      // Act
      final record = DnsRecord.fromJson(json);

      // Assert
      expect(record.id, equals('1'));
      expect(record.label, equals('Test DNS'));
      expect(record.ip1, equals('1.1.1.1'));
      expect(record.ip2, equals('1.0.0.1'));
      expect(record.type, equals(DnsType.general));
    });
  });

  group('DnsType Tests', () {
    test('should convert string to DnsType correctly', () {
      expect(dnsTypeFromString('GENERAL'), equals(DnsType.general));
      expect(dnsTypeFromString('GOOGLE'), equals(DnsType.google));
      expect(dnsTypeFromString('GAMING'), equals(DnsType.gaming));
    });

    test('should handle unknown types gracefully', () {
      expect(dnsTypeFromString('UNKNOWN'), equals(DnsType.other));
    });

    test('should convert DnsType to string correctly', () {
      // Based on the actual implementation, all types except ipv6 return 'IPv4'
      expect(dnsTypeToString(DnsType.general), equals('IPv4'));
      expect(dnsTypeToString(DnsType.google), equals('IPv4'));
      expect(dnsTypeToString(DnsType.gaming), equals('IPv4'));
      expect(dnsTypeToString(DnsType.ipv6), equals('IPv6'));
    });
  });
}
