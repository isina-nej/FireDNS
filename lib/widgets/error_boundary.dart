import 'package:flutter/material.dart';

/// ویجت ErrorBoundary برای مدیریت خطاهای زمان اجرا در Flutter
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // تنظیم هندلر خطا برای این ویجت
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      _handleError(errorDetails.exception);
      return _buildErrorWidget();
    };
  }

  void _handleError(Object error) {
    setState(() {
      _error = error;
    });

    // فراخوانی callback اگر وجود داشته باشد
    widget.onError?.call(error, StackTrace.empty);
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unexpected Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error?.toString() ?? 'Unknown error occurred',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    // استفاده از Builder برای گرفتن خطاها
    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (error) {
          _handleError(error);
          return _buildErrorWidget();
        }
      },
    );
  }
}

/// اکستنشن برای استفاده آسان از ErrorBoundary
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    Widget? errorWidget,
    Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return ErrorBoundary(
      errorWidget: errorWidget,
      onError: onError,
      child: this,
    );
  }
}
