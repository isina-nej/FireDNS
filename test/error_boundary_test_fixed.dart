import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firedns/widgets/error_boundary.dart';

class TestNormalWidget extends StatelessWidget {
  const TestNormalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Normal Widget Works');
  }
}

void main() {
  group('ErrorBoundary', () {
    testWidgets('should display normal child when no error occurs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: TestNormalWidget(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Normal Widget Works'), findsOneWidget);
      expect(find.text('Unexpected Error'), findsNothing);
    });

    testWidgets('should display custom error widget when provided',
        (WidgetTester tester) async {
      const customErrorWidget = Text('Custom Error Message');

      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            errorWidget: customErrorWidget,
            child: TestNormalWidget(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Normal Widget Works'), findsOneWidget);
      expect(find.text('Custom Error Message'), findsNothing);
    });

    testWidgets('should not call onError callback when no error occurs',
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
            child: const TestNormalWidget(),
          ),
        ),
      );

      await tester.pump();

      // Since no error occurs, callback should not be called
      expect(capturedError, isNull);
      expect(capturedStackTrace, isNull);
    });

    testWidgets('should display normal widget without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: TestNormalWidget(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Normal Widget Works'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('ErrorBoundaryExtension', () {
    testWidgets('should add error boundary to widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestNormalWidget().withErrorBoundary(),
        ),
      );

      await tester.pump();
      expect(find.text('Normal Widget Works'), findsOneWidget);
    });
  });

  group('ErrorBoundary.wrap', () {
    testWidgets('should wrap widget with error boundary',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary.wrap(
            const TestNormalWidget(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Normal Widget Works'), findsOneWidget);
    });
  });
}
