import 'package:flutter/material.dart';
import '../screens/notification_list_page.dart';
import '../path/path.dart';

class AppRoutes {
  static const String home = '/';
  static const String notifications = '/notifications';

  static Map<String, Widget Function(BuildContext)> routes = {
    home: (context) => FireDNSHomePage(
          title: context.tr('appTitle'),
          key: const ValueKey('home_page'),
        ),
    notifications: (context) => const NotificationListPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (context) => FireDNSHomePage(
            title: context.tr('appTitle'),
            key: const ValueKey('home_page'),
          ),
          settings: settings,
        );
      case notifications:
        return MaterialPageRoute(
          builder: (context) => const NotificationListPage(),
          settings: settings,
        );
      default:
        // اگر مسیر شناخته شده نبود، به صفحه اصلی برمی‌گردیم
        return MaterialPageRoute(
          builder: (context) => FireDNSHomePage(
            title: context.tr('appTitle'),
            key: const ValueKey('home_page'),
          ),
        );
    }
  }
}
