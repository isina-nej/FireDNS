import 'package:animations/animations.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';
  static const String notifications = '/notifications';
  static const String enhancedDnsList = '/enhanced-dns-list';

  static Map<String, Widget Function(BuildContext)> routes = {
    home: (context) => FireDNSHomePage(
          title: context.tr('appTitle'),
          key: const ValueKey('home_page'),
        ),
    notifications: (context) => const NotificationListPage(),
    enhancedDnsList: (context) => const EnhancedDnsListPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FireDNSHomePage(
            title: 'FireDNS',
            key: ValueKey('home_page'),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          settings: settings,
        );
      case notifications:
        // استخراج notificationId از arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final highlightNotificationId =
            args?['highlightNotificationId'] as String?;

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              NotificationListPage(
            highlightNotificationId: highlightNotificationId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          settings: settings,
        );
      case enhancedDnsList:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const EnhancedDnsListPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          settings: settings,
        );
      default:
        // اگر مسیر شناخته شده نبود، به صفحه اصلی برمی‌گردیم
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FireDNSHomePage(
            title: 'FireDNS',
            key: ValueKey('home_page'),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          settings: settings,
        );
    }
  }
}
