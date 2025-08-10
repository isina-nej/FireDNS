import 'package:flutter/material.dart';
import '../screens/settings_page.dart';
import '../screens/about_page.dart';
import '../screens/check_update_page.dart';
import '../screens/ticket_page.dart';
import 'package:provider/provider.dart';
import '../path/path.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: true);
    final isDark = themeManager.isDarkModeActive(context);
    return Drawer(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundLight,
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
            leading: Icon(
              Icons.settings,
              color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.dark_mode,
              color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
            ),
            title: Text(
              isDark ? context.tr('lightMode') : context.tr('darkMode'),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              themeManager.toggleTheme();
              // منو را نمی‌بندیم تا تغییر تم را ببینید
            },
          ),
          ListTile(
            leading: Icon(
              Icons.system_update_alt,
              color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckUpdatePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.support_agent,
              color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TicketPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
      // ),
    );
  }
}
