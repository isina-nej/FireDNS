import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../path/path.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text(
          context.tr('aboutUs'),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.darkIconPrimary : Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: isDark ? AppColors.brightBlue : Colors.blue,
            child: const Text(
              'DNS', // This is a brand name, so we keep it as is
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('appName'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr('appVersion')} 2.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('appDescription'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? AppColors.darkTextPrimary : Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow(context, Icons.email, context.tr('supportEmail'),
              context.tr('supportEmailAddress')),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.web, context.tr('website'),
              context.tr('websiteAddress')),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  context.tr('developmentTeam'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('thankYouMessage'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String title, String value) {
    final isDark = Provider.of<ThemeManager>(context).isDarkModeActive(context);

    return Row(
      children: [
        Icon(icon,
            color: isDark ? AppColors.brightBlue : Colors.blue, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
