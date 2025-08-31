/// Modern Navigation Showcase
/// This file demonstrates the beautiful page transitions implemented in FireDNS
///
/// Available Transition Types:
/// 1. fadeTransition - Ultra-modern fade with subtle scale effect
/// 2. slideRightToLeft - Smooth slide transition (iOS style)
/// 3. sharedAxisHorizontal - Material Design 3 shared axis horizontal
/// 4. sharedAxisVertical - Material Design 3 shared axis vertical
/// 5. scaleTransition - Scale transition with fade effect
/// 6. rotateTransition - Rotate transition with scale effect
/// 7. slideLeftToRight - Left to right slide (for back navigation)
/// 8. sizeTransition - Size transition with fade effect
/// 9. slideTopToBottom - Top to bottom slide transition
/// 10. slideBottomToTop - Bottom to top slide transition
///
/// Usage Examples:
///
/// // Basic fade through transition
/// await context.pushFadeThrough(MyPage());
///
/// // Shared axis horizontal (Material Design 3)
/// await context.pushSharedAxisHorizontal(MyPage());
///
/// // Scale transition with custom duration
/// await context.pushScale(MyPage(), duration: Duration(milliseconds: 500));
///
/// // Using the service directly
/// await ProfessionalNavigationService.fadeThrough(context, MyPage());
/// await ProfessionalNavigationService.sharedAxisHorizontal(context, MyPage());
/// await ProfessionalNavigationService.scaleTransition(context, MyPage());
///
/// // Pre-configured page transitions
/// await NavigationService.navigateToSettings(context); // Shared axis horizontal
/// await NavigationService.navigateToNotifications(context); // Slide right to left
/// await NavigationService.navigateToSpeedTest(context); // Scale transition
/// await NavigationService.navigateToProfile(context); // Shared axis vertical
/// await NavigationService.navigateToAbout(context); // Fade transition
/// await NavigationService.navigateToTicket(context); // Slide bottom to top
///
/// Performance Tips:
/// - Use shorter durations (200-400ms) for better UX
/// - Choose appropriate curves (easeInOutCubic, easeOut, easeInOutBack)
/// - Consider using childBuilder for lazy widget construction
/// - Use RepaintBoundary on heavy widgets
///
/// Example with performance optimization:
/// await context.pushFade(
///   RepaintBoundary(child: HeavyWidget()),
///   duration: Duration(milliseconds: 250),
///   curve: Curves.easeOut,
/// );
library;

import 'package:flutter/material.dart';

import '../services/modern_navigation_service.dart';

class NavigationShowcase extends StatelessWidget {
  const NavigationShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Navigation Showcase'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTransitionButton(
            context,
            'Fade Through Transition',
            () => context.pushFadeThrough(const _DemoPage('Fade Through')),
          ),
          _buildTransitionButton(
            context,
            'Shared Axis Horizontal',
            () => context
                .pushSharedAxisHorizontal(const _DemoPage('Shared Axis H')),
          ),
          _buildTransitionButton(
            context,
            'Scale Transition',
            () => context.pushScale(const _DemoPage('Scale')),
          ),
          _buildTransitionButton(
            context,
            'Slide Fade Transition',
            () => context.pushSlideFade(const _DemoPage('Slide Fade')),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionButton(
    BuildContext context,
    String title,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(title),
      ),
    );
  }
}

class _DemoPage extends StatelessWidget {
  final String transitionType;

  const _DemoPage(this.transitionType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$transitionType Transition'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Beautiful $transitionType Transition!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
