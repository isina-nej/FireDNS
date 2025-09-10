import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:firedns/controllers/theme_controller.dart';

/// Provider برای دسترسی سریع به ThemeController در سراسر اپ
class ThemeProvider extends InheritedWidget {
  final ThemeController themeController;

  const ThemeProvider({
    super.key,
    required this.themeController,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  static ThemeController? controllerOf(BuildContext context) {
    return of(context)?.themeController;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return oldWidget.themeController != themeController;
  }
}

/// Extension برای دسترسی آسان به ThemeController
extension ThemeControllerExtension on BuildContext {
  ThemeController? get themeController => ThemeProvider.controllerOf(this);

  bool get isDarkMode {
    final controller = themeController;
    if (controller == null) return false;
    return controller.isDarkModeActive(this);
  }

  ThemeData get currentTheme {
    final controller = themeController;
    if (controller == null) return Theme.of(this);
    return controller.getCurrentThemeData(this);
  }

  Future<void> toggleTheme() async {
    final controller = themeController;
    if (controller != null) {
      await controller.toggleThemeWithAnimation(this);
    }
  }
}

/// ویجت برای تغییر تم با انیمیشن smooth
class ThemeToggleButton extends StatelessWidget {
  final Widget? lightIcon;
  final Widget? darkIcon;
  final double size;

  const ThemeToggleButton({
    super.key,
    this.lightIcon,
    this.darkIcon,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = context.themeController;
      if (controller == null) return const SizedBox.shrink();

      final isDark = controller.isDarkModeActive(context);

      return IconButton(
        onPressed: () => controller.toggleThemeWithAnimation(context),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: isDark
              ? (darkIcon ??
                  Icon(
                    Icons.dark_mode,
                    key: const ValueKey('dark'),
                    size: size,
                    color: Theme.of(context).iconTheme.color,
                  ))
              : (lightIcon ??
                  Icon(
                    Icons.light_mode,
                    key: const ValueKey('light'),
                    size: size,
                    color: Theme.of(context).iconTheme.color,
                  )),
        ),
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      );
    });
  }
}

/// ویجت برای نمایش وضعیت تم فعلی
class ThemeStatusIndicator extends StatelessWidget {
  const ThemeStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = context.themeController;
      if (controller == null) return const SizedBox.shrink();

      final isDark = controller.isDarkModeActive(context);
      final themeName = controller.getThemeName(context);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              themeName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    });
  }
}
