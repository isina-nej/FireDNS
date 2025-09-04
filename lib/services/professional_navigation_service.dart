import 'package:animations/animations.dart';
import 'package:firedns/screens/about_page.dart';
import 'package:firedns/screens/notification_list_page.dart';
import 'package:firedns/screens/profile_page.dart';
import 'package:firedns/screens/settings_page.dart';
import 'package:firedns/screens/speed_test_page.dart';
import 'package:firedns/screens/ticket_page.dart';
import 'package:flutter/material.dart';

/// Professional Navigation Service with Material Design 3 Transitions
/// Uses Flutter's official animations package for ultra-smooth transitions
class ProfessionalNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Ultra-smooth Container Transform transition
  /// Perfect for card-to-details page transitions
  static Future<dynamic> containerTransform(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 450),
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return OpenContainer(
            closedBuilder: (context, action) => const SizedBox.shrink(),
            openBuilder: (context, action) => child,
            transitionType: ContainerTransitionType.fadeThrough,
            closedElevation: 0,
            openElevation: 0,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            openShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            transitionDuration: duration,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Material Design 3 Shared Axis Horizontal transition
  /// Perfect for navigation between related screens
  static Future<dynamic> sharedAxisHorizontal(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Material Design 3 Shared Axis Vertical transition
  /// Perfect for parent-child navigation
  static Future<dynamic> sharedAxisVertical(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Material Design 3 Fade Through transition
  /// Perfect for bottom navigation tab changes
  static Future<dynamic> fadeThrough(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 350),
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Material Design 3 Fade Scale transition
  /// Perfect for modal dialogs and overlays
  static Future<dynamic> fadeScale(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeScaleTransition(
            animation: animation,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Ultra-smooth Scale transition with custom curve
  static Future<dynamic> scaleTransition(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Professional slide transition with fade
  static Future<dynamic> slideFadeTransition(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Offset beginOffset = const Offset(1.0, 0.0),
    Curve curve = Curves.easeInOutCubic,
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Push replacement with professional transition
  static Future<dynamic> replaceWithFadeThrough(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 350),
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator)
        .pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// Push and remove until with professional transition
  static Future<dynamic> pushAndRemoveUntilFadeThrough(
    BuildContext context,
    Widget page,
    bool Function(Route<dynamic>) predicate, {
    Duration duration = const Duration(milliseconds: 350),
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator)
        .pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
      predicate,
    );
  }

  /// Pop with smooth animation
  static void pop(BuildContext context, {bool useRootNavigator = false}) {
    Navigator.of(context, rootNavigator: useRootNavigator).pop();
  }

  /// Pre-configured navigation methods for common pages

  /// Navigate to Settings with Shared Axis Horizontal
  static Future<dynamic> navigateToSettings(BuildContext context) {
    return sharedAxisHorizontal(
      context,
      const SettingsPage(),
      duration: const Duration(milliseconds: 420),
    );
  }

  /// Navigate to Notifications with Slide Fade
  static Future<dynamic> navigateToNotifications(BuildContext context) {
    return slideFadeTransition(
      context,
      const NotificationListPage(),
      duration: const Duration(milliseconds: 380),
    );
  }

  /// Navigate to Speed Test with Scale Transition
  static Future<dynamic> navigateToSpeedTest(BuildContext context) {
    return scaleTransition(
      context,
      const SpeedTestPage(),
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Navigate to Profile with Shared Axis Vertical
  static Future<dynamic> navigateToProfile(BuildContext context) {
    return sharedAxisVertical(
      context,
      const ProfilePage(),
      duration: const Duration(milliseconds: 420),
    );
  }

  /// Navigate to About with Fade Through
  static Future<dynamic> navigateToAbout(BuildContext context) {
    return fadeThrough(
      context,
      const AboutPage(),
      duration: const Duration(milliseconds: 350),
    );
  }

  /// Navigate to Ticket with Slide Bottom to Top
  static Future<dynamic> navigateToTicket(BuildContext context) {
    return slideFadeTransition(
      context,
      const TicketPage(),
      beginOffset: const Offset(0.0, 1.0),
      duration: const Duration(milliseconds: 400),
    );
  }
}

/// Extension methods for easier navigation
extension ProfessionalNavigationExtensions on BuildContext {
  /// Navigate with Container Transform
  Future<dynamic> pushContainerTransform(
    Widget page, {
    Duration duration = const Duration(milliseconds: 450),
  }) {
    return ProfessionalNavigationService.containerTransform(
      this,
      page,
      duration: duration,
    );
  }

  /// Navigate with Shared Axis Horizontal
  Future<dynamic> pushSharedAxisHorizontal(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return ProfessionalNavigationService.sharedAxisHorizontal(
      this,
      page,
      duration: duration,
    );
  }

  /// Navigate with Fade Through
  Future<dynamic> pushFadeThrough(
    Widget page, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return ProfessionalNavigationService.fadeThrough(
      this,
      page,
      duration: duration,
    );
  }

  /// Navigate with Scale Transition
  Future<dynamic> pushScale(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return ProfessionalNavigationService.scaleTransition(
      this,
      page,
      duration: duration,
      curve: curve,
    );
  }

  /// Navigate with Slide Fade
  Future<dynamic> pushSlideFade(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Offset beginOffset = const Offset(1.0, 0.0),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return ProfessionalNavigationService.slideFadeTransition(
      this,
      page,
      duration: duration,
      beginOffset: beginOffset,
      curve: curve,
    );
  }
}
