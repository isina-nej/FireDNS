import 'package:flutter/material.dart';

/// صفحه Splash اولیه که فوراً نمایش داده می‌شود
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false, // صفحه splash نباید بک داشته باشد
      child: Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        body: AnimatedBuilder(
          animation: _logoAnimation,
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo با انیمیشن ساده
                  Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.width * 0.3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.orange.withValues(alpha: 0.3)
                                : Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/logo/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.dns,
                              size: MediaQuery.of(context).size.width * 0.15,
                              color: isDarkMode ? Colors.white : Colors.black,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                  // نام برنامه
                  FadeTransition(
                    opacity: _logoAnimation,
                    child: Text(
                      'Fire DNS',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF2D3748),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  // نوار پیشرفت ساده
                  FadeTransition(
                    opacity: _logoAnimation,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: LinearProgressIndicator(
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
