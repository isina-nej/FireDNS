import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum GetXTransitionType {
  fade,
  fadeIn,
  rightToLeft,
  leftToRight,
  upToDown,
  downToUp,
  zoom,
  topLevel,
  noTransition,
  cupertino,
  cupertinoDialog,
  native,
  leftToRightWithFade,
  rightToLeftWithFade,
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = Get.key;
  static GetXTransitionType _currentTransition = GetXTransitionType.fade;

  // Set current transition type dynamically
  static void setTransitionType(GetXTransitionType transition) {
    _currentTransition = transition;
  }

  static GetXTransitionType get currentTransition => _currentTransition;

  // Get transition from enum
  static Transition _getTransition(GetXTransitionType type) {
    switch (type) {
      case GetXTransitionType.fade:
        return Transition.fade;
      case GetXTransitionType.fadeIn:
        return Transition.fadeIn;
      case GetXTransitionType.rightToLeft:
        return Transition.rightToLeft;
      case GetXTransitionType.leftToRight:
        return Transition.leftToRight;
      case GetXTransitionType.upToDown:
        return Transition.upToDown;
      case GetXTransitionType.downToUp:
        return Transition.downToUp;
      case GetXTransitionType.zoom:
        return Transition.zoom;
      case GetXTransitionType.topLevel:
        return Transition.topLevel;
      case GetXTransitionType.noTransition:
        return Transition.noTransition;
      case GetXTransitionType.cupertino:
        return Transition.cupertino;
      case GetXTransitionType.cupertinoDialog:
        return Transition.cupertinoDialog;
      case GetXTransitionType.native:
        return Transition.native;
      case GetXTransitionType.leftToRightWithFade:
        return Transition.leftToRightWithFade;
      case GetXTransitionType.rightToLeftWithFade:
        return Transition.rightToLeftWithFade;
    }
  }

  // Navigate to page with current transition
  static Future<dynamic> navigateToPage(
    Widget page, {
    GetXTransitionType? transition,
    Duration? duration,
  }) {
    final trans = transition ?? _currentTransition;
    Get.to(
      () => page,
      transition: _getTransition(trans),
      duration: duration ?? const Duration(milliseconds: 300),
    );
    return Future.value();
  }

  static Future<dynamic> navigateToPageReplacement(
    Widget page, {
    GetXTransitionType? transition,
    Duration? duration,
  }) {
    Get.off(
      () => page,
    );
    return Future.value();
  }

  static Future<dynamic> navigateToRoute(
    String routeName, {
    Object? arguments,
    GetXTransitionType? transition,
    Duration? duration,
  }) {
    Get.toNamed(
      routeName,
      arguments: arguments,
    );
    return Future.value();
  }

  static void pop() {
    Get.back();
  }

  // Specific navigation methods with different transitions
  static Future<dynamic> navigateToSettings(BuildContext context) {
    return navigateToPage(
      const SettingsPage(),
      transition: GetXTransitionType.rightToLeft,
      duration: const Duration(milliseconds: 400),
    );
  }

  static Future<dynamic> navigateToNotifications(BuildContext context) {
    return navigateToPage(
      const NotificationListPage(),
      transition: GetXTransitionType.fadeIn,
      duration: const Duration(milliseconds: 350),
    );
  }

  static Future<dynamic> navigateToSpeedTest(BuildContext context) {
    return navigateToPage(
      const SpeedTestPage(),
      transition: GetXTransitionType.zoom,
      duration: const Duration(milliseconds: 450),
    );
  }

  static Future<dynamic> navigateToProfile(BuildContext context) {
    return navigateToPage(
      const ProfilePage(),
      transition: GetXTransitionType.upToDown,
      duration: const Duration(milliseconds: 400),
    );
  }

  static Future<dynamic> navigateToAbout(BuildContext context) {
    return navigateToPage(
      const AboutPage(),
      transition: GetXTransitionType.zoom,
      duration: const Duration(milliseconds: 350),
    );
  }

  static Future<dynamic> navigateToTicket(BuildContext context) {
    return navigateToPage(
      const TicketPage(),
      transition: GetXTransitionType.downToUp,
      duration: const Duration(milliseconds: 400),
    );
  }
}
