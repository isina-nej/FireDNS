import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../path/path.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode;

    return PopScope(
      canPop: true,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor:
            isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            context.tr('aboutUs'),
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? AppColors.darkIconPrimary : Colors.black54),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppColors.darkSurface,
                            AppColors.darkBackground,
                          ]
                        : [
                            Colors.blue.shade50,
                            Colors.white,
                          ],
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.blue.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor:
                          isDark ? AppColors.brightBlue : Colors.blue,
                      backgroundImage: const AssetImage('assets/logo/logo.png'),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Center(
                  child: Text(
                    context.tr('appName'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : Colors.blue.shade900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${context.tr('appVersion')} 2.0.0',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Card(
                  elevation: isDark ? 0 : 3,
                  color: isDark
                      ? AppColors.darkSurfaceVariant.withOpacity(0.85)
                      : Colors.white.withOpacity(0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      context.tr('appDescription'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.5,
                        height: MediaQuery.of(context).size.height * 0.002,
                        color:
                            isDark ? AppColors.darkTextPrimary : Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modernInfoButton(
                      context,
                      icon: Icons.web,
                      label: 'Fire-DNS.ir',
                      url: 'https://Fire-DNS.ir',
                      color: Colors.blue,
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                    _modernInfoButton(
                      context,
                      icon: Icons.telegram,
                      label: '@Fire_DNS',
                      url: 'https://t.me/Fire_DNS',
                      color: Colors.lightBlue,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                Card(
                  elevation: isDark ? 0 : 2,
                  color: isDark
                      ? AppColors.darkSurfaceVariant.withOpacity(0.92)
                      : Colors.white.withOpacity(0.92),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups,
                                color:
                                    isDark ? AppColors.brightBlue : Colors.blue,
                                size:
                                    MediaQuery.of(context).size.width * 0.065),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              context.tr('developmentTeam'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        Text(
                          context.tr('thankYouMessage'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: MediaQuery.of(context).size.height * 0.002,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // _buildInfoRow removed as it's no longer used

  Widget _modernInfoButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    final isDark = Get.find<ThemeController>().isDarkMode;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.18) : color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.5 : 0.3),
            width: MediaQuery.of(context).size.width * 0.003,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: color, size: MediaQuery.of(context).size.width * 0.055),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
