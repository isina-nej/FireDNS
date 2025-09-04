import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Enhanced DNS List Tests', () {
    late SharedPreferences mockPrefs;

    setUpAll(() async {
      // Initialize GetX
      Get.testMode = true;
      Get.reset();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        'cached_dns_list': '[]',
        'user_dns_list': '[]',
        'reported_dns_list': '[]',
      });
      mockPrefs = await SharedPreferences.getInstance();

      // Put ThemeController
      Get.put(ThemeController());
    });

    tearDown(() {
      // No need to reset Get here since we're using setUpAll
    });

    testWidgets('DNS selection service should work',
        (WidgetTester tester) async {
      // Create mock services
      final selectionService = DnsSelectionService();
      final managementService = DnsManagementService();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: selectionService),
              ChangeNotifierProvider.value(value: managementService),
            ],
            child: const EnhancedDnsListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify page loads
      expect(find.byType(EnhancedDnsListPage), findsOneWidget);
    });

    test('DNS Selection Service functionality', () {
      final service = DnsSelectionService();

      // Test initial state
      expect(service.isSelectionMode, false);
      expect(service.selectedDnsIds.isEmpty, true);

      // Test enter selection mode
      service.enterSelectionMode();
      expect(service.isSelectionMode, true);

      // Test toggle DNS selection
      service.toggleDnsSelection('test-id');
      expect(service.selectedDnsIds.contains('test-id'), true);
      expect(service.selectedCount, 1);

      // Test toggle again (deselect)
      service.toggleDnsSelection('test-id');
      expect(service.selectedDnsIds.contains('test-id'), false);
      expect(service.selectedCount, 0);
      expect(service.isSelectionMode, false); // Should exit when empty

      // Test multiple selections
      service.enterSelectionMode();
      service.toggleDnsSelection('test-id-1');
      service.toggleDnsSelection('test-id-2');
      expect(service.selectedCount, 2);

      service.exitSelectionMode();
      expect(service.selectedCount, 0);
      expect(service.isSelectionMode, false);
    });

    test('DNS Management Service functionality', () {
      final service = DnsManagementService();

      // Test initial state
      expect(service.records.isEmpty, true);
      expect(service.blockedDnsIds.isEmpty, true);
      expect(service.deletedDnsIds.isEmpty, true);
      expect(service.reportedDnsIds.isEmpty, true);

      // Test stats
      final stats = service.stats;
      expect(stats.totalBlocked, 0);
      expect(stats.totalDeleted, 0);
      expect(stats.totalReported, 0);
      expect(stats.totalManaged, 0);
    });
  });
}
