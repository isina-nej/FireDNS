// lib/utils/snackbar_utils.dart

import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class SnackBarStyle {
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  SnackBarStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

SnackBarStyle getSnackBarStyle(SnackBarType type, bool isDark) {
  switch (type) {
    case SnackBarType.success:
      return SnackBarStyle(
        backgroundColor: const Color(0xFF2E7D32), // Dark green
        borderColor: const Color(0xFF4CAF50).withOpacity(0.5),
        icon: Icons.check_circle,
      );
    case SnackBarType.error:
      return SnackBarStyle(
        backgroundColor: const Color(0xFFD32F2F), // Dark red
        borderColor: const Color(0xFFE57373).withOpacity(0.5),
        icon: Icons.error,
      );
    case SnackBarType.warning:
      return SnackBarStyle(
        backgroundColor: const Color(0xFFEF6C00), // Dark orange
        borderColor: const Color(0xFFFFB74D).withOpacity(0.5),
        icon: Icons.warning,
      );
    case SnackBarType.info:
      return SnackBarStyle(
        backgroundColor: const Color(0xFF1976D2), // Dark blue
        borderColor: const Color(0xFF64B5F6).withOpacity(0.5),
        icon: Icons.info,
      );
  }
}

void showEnhancedSnackBar({
  required BuildContext context,
  required String message,
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 3),
  bool dismissible = true,
  VoidCallback? onTap,
  required DateTime? lastSnackBarTime,
  required String? lastSnackBarMessage,
  required Function(DateTime?) setLastSnackBarTime,
  required Function(String?) setLastSnackBarMessage,
  required bool Function() isDarkModeActive,
}) {
  final now = DateTime.now();

  // Anti-spam protection
  if (lastSnackBarMessage == message &&
      lastSnackBarTime != null &&
      now.difference(lastSnackBarTime).inSeconds < 2) {
    return;
  }

  // Rate limiting
  if (lastSnackBarTime != null &&
      now.difference(lastSnackBarTime).inMilliseconds < 800) {
    return;
  }

  setLastSnackBarMessage(message);
  setLastSnackBarTime(now);

  // Clear any existing SnackBars to prevent stacking
  ScaffoldMessenger.of(context).clearSnackBars();

  // Get appropriate colors and icon based on type
  final isDark = isDarkModeActive();
  final snackBarStyle = getSnackBarStyle(type, isDark);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          // Icon with subtle animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Icon(
                    snackBarStyle.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Message with fade-in animation
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          // Optional close button
          if (dismissible)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
            ),
        ],
      ),
      backgroundColor: snackBarStyle.backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: snackBarStyle.borderColor,
          width: 1,
        ),
      ),
      elevation: 6,
    ),
  );
}