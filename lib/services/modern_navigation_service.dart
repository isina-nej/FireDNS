import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

extension NavigationExtensions on BuildContext {
  Future<T?> pushFadeThrough<T>(Widget page, {Duration? duration}) {
    return Navigator.push(
      this,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        transitionDuration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  Future<T?> pushSharedAxisHorizontal<T>(Widget page, {Duration? duration}) {
    return Navigator.push(
      this,
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
        transitionDuration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  Future<T?> pushScale<T>(Widget page, {Duration? duration}) {
    return Navigator.push(
      this,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  Future<T?> pushSlideFade<T>(Widget page, {Duration? duration}) {
    return Navigator.push(
      this,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }
}
