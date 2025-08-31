import 'package:flutter/material.dart';

/// Splash screen بهینه برای startup
class OptimizedSplashScreen extends StatelessWidget {
  const OptimizedSplashScreen({super.key});

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
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.width * 0.2,
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.width * 0.2,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              const CircularProgressIndicator(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
