import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firedns/widgets/error_boundary.dart';

class TestErrorWidget extends StatelessWidget {
  const TestErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    throw Exception('Test error');
  }
}

void main() {
  group('ErrorBoundary', () {
    testWidgets('should display error widget when child throws error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: TestErrorWidget(),
          ),
        ),
      );

      // Wait for error to be caught
      await tester.pump();

      // Check if error widget is displayed
      expect(find.text('Unexpected Error'), findsOneWidget);
      expect(find.text('Please try again'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display custom error widget',
        (WidgetTester tester) async {
      const customErrorWidget = Text('Custom Error');

      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            errorWidget: customErrorWidget,
            child: TestErrorWidget(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Custom Error'), findsOneWidget);
    });

    testWidgets('should call onError callback when error occurs',
        (WidgetTester tester) async {
      Object? capturedError;
      StackTrace? capturedStackTrace;

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onError: (error, stackTrace) {
              capturedError = error;
              capturedStackTrace = stackTrace;
            },
            child: const TestErrorWidget(),
          ),
        ),
      );

      await tester.pump();

      expect(capturedError, isNotNull);
      expect(capturedStackTrace, isNotNull);
      expect(capturedError.toString(), contains('Test error'));
    });

    testWidgets('should retry when retry button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: TestErrorWidget(),
          ),
        ),
      );

      await tester.pump();

      // Error should be displayed
      expect(find.text('Unexpected Error'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Error should still be displayed since child still throws
      expect(find.text('Unexpected Error'), findsOneWidget);
    });
  });

  group('ErrorBoundaryExtension', () {
    testWidgets('should add error boundary to widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestErrorWidget().withErrorBoundary(),
        ),
      );

      await tester.pump();

      expect(find.text('Unexpected Error'), findsOneWidget);
    });
  });
}
