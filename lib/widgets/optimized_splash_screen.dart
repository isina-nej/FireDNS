import 'package:flutter/material.dart';

/// Splash screen بهینه برای startup
class OptimizedSplashScreen extends StatelessWidget {
  const OptimizedSplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // لوگوی کوچک و بهینه
              SizedBox(
                width: 80,
                height: 80,
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'بارگذاری...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
