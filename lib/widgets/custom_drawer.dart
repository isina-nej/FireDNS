import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/path/path.dart';
import 'package:firedns/screens/check_update_page.dart';
import 'package:firedns/services/navigation_service.dart';
import 'package:firedns/services/professional_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart' show Lottie, LottieDelegates, ValueDelegate;

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      final isDark = themeController.isDarkModeActive(context);
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
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
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
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
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
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
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
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // بستن drawer
                NavigationService.navigateToAbout(context);
              },
            ),
            // Temporary DNS Management Test Button
            ListTile(
              leading: const Icon(Icons.dns),
              title: Text(
                'Enhanced DNS List (Test)',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // بستن drawer
                Navigator.pushNamed(context, '/enhanced-dns-list');
              },
            ),
          ],
        ),
      );
    });
  }
}
