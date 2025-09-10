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

  /// Static method to wrap any widget with error boundary
  static Widget wrap(
    Widget child, {
    Widget? errorWidget,
    Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return ErrorBoundary(
      errorWidget: errorWidget,
      onError: onError,
      child: child,
    );
  }
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // تنظیم error handler سراسری در صورت نیاز
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted && !_hasError) {
        _handleError(details.exception, details.stack ?? StackTrace.empty);
      }
      // همچنان خطا را به handler پیش‌فرض ارسال کنیم
      FlutterError.presentError(details);
    };
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (mounted && !_hasError) {
      setState(() {
        _error = error;
        _hasError = true;
      });

      // فراخوانی callback اگر وجود داشته باشد
      widget.onError?.call(error, stackTrace);
    }
  }

  void retry() {
    setState(() {
      _error = null;
      _hasError = false;
    });
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return widget.child;
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
