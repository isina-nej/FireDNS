import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' show Lottie, LottieDelegates, ValueDelegate;
import 'package:provider/provider.dart';

import '../path/path.dart';
import '../screens/check_update_page.dart';
import '../services/navigation_service.dart';
import '../services/professional_navigation_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: true);
    final isDark = themeManager.isDarkModeActive(context);
    return Drawer(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.backgroundLight,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardBackground
                  : AppColors.backgroundGrey,
            ),
            child: Center(
              child: Text(
                context.tr('appName'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          ListTile(
            leading: SizedBox(
              width: MediaQuery.of(context).size.width * 0.12,
              height: MediaQuery.of(context).size.width * 0.12,
              child: Lottie.asset(
                'assets/icone/settings.json',
                fit: BoxFit.contain,
                delegates: isDark
                    ? LottieDelegates(
                        values: [
                          ValueDelegate.color(
                            const ['**'],
                            value: Colors.deepPurpleAccent,
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            title: Text(
              context.tr('settings'),
              style: TextStyle(
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // بستن drawer
              NavigationService.navigateToSettings(context);
            },
          ),
          ListTile(
            leading: SizedBox(
              width: MediaQuery.of(context).size.width * 0.12,
              height: MediaQuery.of(context).size.width * 0.12,
              child: Lottie.asset(
                'assets/icone/success_animation.json',
                fit: BoxFit.contain,
                delegates: isDark
                    ? LottieDelegates(
                        values: [
                          ValueDelegate.color(
                            const ['**'],
                            value: Colors.amberAccent,
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            title: Text(
              context.tr('checkForUpdates'),
              style: TextStyle(
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // بستن drawer
              ProfessionalNavigationService.fadeThrough(
                context,
                const CheckUpdatePage(),
                duration: const Duration(milliseconds: 350),
              );
            },
          ),
          ListTile(
            leading: SizedBox(
              width: MediaQuery.of(context).size.width * 0.12,
              height: MediaQuery.of(context).size.width * 0.12,
              child: Lottie.asset(
                'assets/icone/support.json',
                fit: BoxFit.contain,
                delegates: isDark
                    ? LottieDelegates(
                        values: [
                          ValueDelegate.color(
                            const ['**'],
                            value: Colors.blueAccent,
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            title: Text(
              context.tr('sendTicket'),
              style: TextStyle(
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // بستن drawer
              NavigationService.navigateToTicket(context);
            },
          ),
          ListTile(
            leading: SizedBox(
              width: MediaQuery.of(context).size.width * 0.12,
              height: MediaQuery.of(context).size.width * 0.12,
              child: Lottie.asset(
                'assets/icone/about.json',
                fit: BoxFit.contain,
                delegates: isDark
                    ? LottieDelegates(
                        values: [
                          ValueDelegate.color(
                            const ['**'],
                            value: Colors.greenAccent,
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            title: Text(
              context.tr('aboutUs'),
              style: TextStyle(
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // بستن drawer
              NavigationService.navigateToAbout(context);
            },
          ),
        ],
      ),
      // ),
    );
  }
}
