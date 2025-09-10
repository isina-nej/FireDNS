import 'package:firedns/services/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger Tests', () {
    test('should log debug messages in debug mode', () {
      // Test logger functionality
      expect(() => AppLogger.debug('Test debug message'), returnsNormally);
    });

    test('should log info messages', () {
      expect(() => AppLogger.info('Test info message'), returnsNormally);
    });

    test('should log warnings', () {
      expect(() => AppLogger.warning('Test warning message'), returnsNormally);
    });

    test('should log errors with stack trace', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      expect(() => AppLogger.error('Test error message', error, stackTrace),
          returnsNormally);
    });

    test('should log network requests', () {
      expect(
          () => AppLogger.network('GET', 'https://api.example.com/dns',
              statusCode: 200),
          returnsNormally);
    });

    test('should log performance metrics', () {
      const duration = Duration(milliseconds: 150);
      final metadata = {'operation': 'dns_lookup', 'records': 5};
      expect(
          () =>
              AppLogger.performance('DNS Lookup', duration, metadata: metadata),
          returnsNormally);
    });

    test('should log user actions', () {
      final context = {'dns_id': '123', 'action_type': 'connect'};
      expect(() => AppLogger.userAction('DNS Connect', context: context),
          returnsNormally);
    });
  });

  group('AppLogger Extensions', () {
    test('should log with class context', () {
      final testObject = TestClass();
      expect(() => testObject.logInfo('Test message'), returnsNormally);
      expect(() => testObject.logDebug('Debug message'), returnsNormally);
      expect(() => testObject.logWarning('Warning message'), returnsNormally);
      expect(() => testObject.logError('Error message'), returnsNormally);
    });
  });
}

class TestClass {
  void testMethod() {
    logInfo('Test method called');
  }
}
