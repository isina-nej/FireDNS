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
