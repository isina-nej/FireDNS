import 'package:flutter/material.dart';

/// صفحه تنظیمات با طراحی قرمز (کشیدن به پایین)
class RedSettingsPage extends StatefulWidget {
  final bool autoStartOnBoot;
  final bool darkTheme;
  final Function(bool) onAutoStartChanged;
  final Function(bool) onDarkThemeChanged;
  final VoidCallback onAboutPressed;
  final VoidCallback onSupportPressed;

  const RedSettingsPage({
    Key? key,
    required this.autoStartOnBoot,
    required this.darkTheme,
    required this.onAutoStartChanged,
    required this.onDarkThemeChanged,
    required this.onAboutPressed,
    required this.onSupportPressed,
  }) : super(key: key);

  @override
  State<RedSettingsPage> createState() => _RedSettingsPageState();
}

class _RedSettingsPageState extends State<RedSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          // کشیدن به بالا برای برگشت
          if (details.delta.dy < -5) {
            Navigator.pop(context);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF5757), Color(0xFFFF4444)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Auto start on boot
                    _buildSettingsItem(
                      title: 'Auto start on boot',
                      value: widget.autoStartOnBoot,
                      onChanged: widget.onAutoStartChanged,
                      icon: Icons.shield_outlined,
                    ),

                    const SizedBox(height: 30),

                    // Dark theme
                    _buildSettingsItem(
                      title: 'Dark theme',
                      value: widget.darkTheme,
                      onChanged: widget.onDarkThemeChanged,
                      icon: Icons.nightlight_round,
                    ),

                    const SizedBox(height: 30),

                    // About My DNS
                    _buildSettingsButton(
                      title: 'About My DNS',
                      icon: Icons.info_outline,
                      onTap: widget.onAboutPressed,
                    ),

                    const SizedBox(height: 120),

                    // Support this app button
                    GestureDetector(
                      onTap: widget.onSupportPressed,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Support this app',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.shield_outlined,
                              color: Colors.grey.shade600,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // My DNS button
                    GestureDetector(
                      onTap: () {
                        // Navigate to DNS Manager or record list
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'My DNS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.apps,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Status section - DISCONNECTED
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Power button and laptop icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Power button
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.power_settings_new,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                              // Laptop illustration
                              _buildLaptopIllustration(),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // Status text
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.black54,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'DISCONNECTED',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Your session is not private',
                            style: TextStyle(fontSize: 14, color: Colors.red),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Speed Test Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Run button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Run',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              // Speed icon
                              Container(
                                width: 45,
                                height: 45,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.speed,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          const Text(
                            'SpeedTest',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 8),

                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Speedtest',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' measures the speed between your ',
                                ),
                                TextSpan(
                                  text: 'device',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: ' and a test server, using your',
                                ),
                                TextSpan(
                                  text: '.device\'s internet connection',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaptopIllustration() {
    return SizedBox(
      width: 80,
      height: 60,
      child: Stack(
        children: [
          // Laptop screen
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              width: 55,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Laptop keyboard
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 65,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Red warning dot
          const Positioned(
            top: 15,
            left: 0,
            child: CircleAvatar(radius: 6, backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        // سوییچ
        Transform.scale(
          scale: 1.2,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.green.shade400,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
          ),
        ),

        const SizedBox(width: 20),

        // متن
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),

        // آیکون
        Icon(icon, color: Colors.white, size: 24),
      ],
    );
  }

  Widget _buildSettingsButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // فضای خالی برای تراز کردن با سوییچ‌ها
          const SizedBox(width: 60),

          // متن
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),

          // آیکون
          Icon(icon, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
