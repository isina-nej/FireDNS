import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart' show Lottie;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/theme_controller.dart';
import '../path/path.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // تنظیم زبان بر اساس زبان دستگاه در اولین اجرا
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageManager =
          Provider.of<LanguageManager>(context, listen: false);
      final deviceLocale = PlatformDispatcher.instance.locale;
      languageManager.getDeviceLanguage(deviceLocale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final languageManager =
        Provider.of<LanguageManager>(context, listen: false);

    return PopScope(
      canPop: true,
      child: Obx(() {
        final isDark = themeController.isDarkModeActive(context);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              elevation: 0,
              title: Text(
                context.tr('settings'),
                style: TextStyle(
                  fontFamily: languageManager.fontFamily,
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
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingSection(
                  title: context.tr('general'),
                  items: [
                    Consumer<LanguageManager>(
                      builder: (context, languageManager, child) {
                        return _buildSettingItem(
                          icon: 'assets/icone/language.json',
                          title: context.tr('language'),
                          subtitle: languageManager.languageName,
                          onTap: () {
                            _showLanguageSelectionDialog(
                                context, languageManager);
                          },
                        );
                      },
                    ),
                    Obx(() => _buildSettingItem(
                          icon: 'assets/icone/theme.json',
                          title: context.tr('appTheme'),
                          subtitle: themeController.getThemeName(context),
                          onTap: () {
                            _showThemeSelectionDialog(context, themeController);
                          },
                        )),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildSettingSection(
                  title: context.tr('notifications'),
                  items: [
                    Consumer<NotificationService>(
                      builder: (context, notificationService, child) {
                        return _buildSettingItem(
                          icon: 'assets/icone/notifications.json',
                          title: context.tr('notificationsEnabled'),
                          isSwitch: true,
                          switchValue: notificationService.notificationsEnabled,
                          onChanged: (value) {
                            notificationService.toggleNotifications();
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildSettingSection(
                  title: context.tr('dnsTest'),
                  items: [
                    Consumer<DnsTestSettingsService>(
                      builder: (context, dnsTestSettingsService, child) {
                        return _buildSettingItem(
                          icon: 'assets/icone/dns.json',
                          title: context.tr('testType'),
                          subtitle: dnsTestSettingsService.getTestTypeName(
                            dnsTestSettingsService.testType,
                            context,
                          ),
                          onTap: () {
                            _showTestTypeSelectionDialog(
                                context, dnsTestSettingsService);
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildSettingSection(
                  title: 'شبکه‌های اجتماعی',
                  items: [
                    _buildSettingItem(
                      icon: 'assets/icone/twitter.json',
                      title: 'Twitter',
                      onTap: () async {
                        final url = Uri.parse('https://x.com/isina_nej');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: 'assets/icone/linkedin.json',
                      title: 'LinkedIn',
                      onTap: () async {
                        final url =
                            Uri.parse('https://www.linkedin.com/in/isina-nej/');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: 'assets/icone/telegram.json',
                      title: 'Telegram',
                      onTap: () async {
                        final url = Uri.parse('https://t.me/Fire_DNS');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: 'assets/icone/github_alt.json',
                      title: 'GitHub',
                      onTap: () async {
                        final url =
                            Uri.parse('https://github.com/isina-nej/FireDNS');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: 'assets/icone/website_new.json',
                      title: 'Website',
                      onTap: () async {
                        final url = Uri.parse('https://Fire-DNS.ir');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildSettingSection(
                  title: context.tr('aboutUs'),
                  items: [
                    _buildSettingItem(
                      icon: 'assets/icone/info.json',
                      title: context.tr('appVersion'),
                      subtitle: '2.0.0',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> items,
  }) {
    return Builder(builder: (context) {
      final themeController = Get.find<ThemeController>();
      final isDark = themeController.isDarkModeActive(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: items),
          ),
        ],
      );
    });
  }

  Widget _buildSettingItem({
    required String icon,
    required String title,
    String? subtitle,
    bool isSwitch = false,
    bool switchValue = false,
    Function(bool)? onChanged,
    VoidCallback? onTap,
  }) {
    return Builder(builder: (context) {
      final themeController = Get.find<ThemeController>();
      final isDark = themeController.isDarkModeActive(context);
      return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.darkCardBackground : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Lottie.asset(
            icon,
            width: 24,
            height: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                ),
              )
            : null,
        trailing: isSwitch
            ? Switch(
                value: switchValue,
                onChanged: onChanged,
                activeThumbColor: isDark ? AppColors.brightBlue : Colors.blue,
              )
            : Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.darkIconPrimary : Colors.grey,
              ),
        onTap: onTap,
      );
    });
  }

  void _showLanguageSelectionDialog(
      BuildContext context, LanguageManager languageManager) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive(context);

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: isDark ? AppColors.darkTextPrimary : Colors.black,
                displayColor: isDark ? AppColors.darkTextPrimary : Colors.black,
              ),
        ),
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: Text(
            context.tr('language'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(context, 'en', languageManager),
                _buildLanguageOption(context, 'fa', languageManager),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('cancel'),
                style: TextStyle(
                  color: isDark ? AppColors.brightBlue : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, String language, LanguageManager languageManager) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive(context);
    final isSelected = languageManager.locale.languageCode == language;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
          child: Text(_getLanguageDisplayName(context, language)),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: isDark ? AppColors.brightBlue : Colors.blue,
              )
            : null,
        onTap: () async {
          Navigator.pop(context);
          await _setLanguage(languageManager, language);
        },
      ),
    );
  }

  String _getLanguageDisplayName(BuildContext context, String language) {
    switch (language) {
      case 'en':
        return context.tr('english');
      case 'fa':
        return context.tr('persian');
      default:
        return language;
    }
  }

  void _showTestTypeSelectionDialog(
      BuildContext context, DnsTestSettingsService dnsTestSettingsService) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive(context);

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: isDark ? AppColors.darkTextPrimary : Colors.black,
                displayColor: isDark ? AppColors.darkTextPrimary : Colors.black,
              ),
        ),
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: Text(
            context.tr('testType'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTestTypeOption(context, 'ping', dnsTestSettingsService),
                _buildTestTypeOption(context, 'dns', dnsTestSettingsService),
                _buildAdvancedTestTypeOption(context, dnsTestSettingsService),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('cancel'),
                style: TextStyle(
                  color: isDark ? AppColors.brightBlue : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestTypeOption(BuildContext context, String testType,
      DnsTestSettingsService dnsTestSettingsService) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive(context);
    final isSelected = dnsTestSettingsService.testType == testType;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
          child: Text(_getTestTypeDisplayName(context, testType)),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: isDark ? AppColors.brightBlue : Colors.blue,
              )
            : null,
        onTap: () async {
          Navigator.pop(context);
          await dnsTestSettingsService.setTestType(testType);
        },
      ),
    );
  }

  Widget _buildAdvancedTestTypeOption(
      BuildContext context, DnsTestSettingsService dnsTestSettingsService) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive(context);
    final isSelected = dnsTestSettingsService.testType == 'advanced';

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
          child: Text(context.tr('advancedTest')),
        ),
        subtitle: Text(
          context.tr('comingSoon'),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: isDark ? AppColors.brightBlue : Colors.blue,
              )
            : null,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('comingSoon')),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  String _getTestTypeDisplayName(BuildContext context, String testType) {
    switch (testType) {
      case 'ping':
        return context.tr('pingTest');
      case 'dns':
        return context.tr('dnsTest');
      default:
        return testType;
    }
  }

  void _showThemeSelectionDialog(
      BuildContext context, ThemeController themeController) {
    final isDark = themeController.isDarkModeActive(context);

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: isDark ? AppColors.darkTextPrimary : Colors.black,
                displayColor: isDark ? AppColors.darkTextPrimary : Colors.black,
              ),
        ),
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: Text(
            context.tr('appTheme'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOption(context, 'system', themeController),
                _buildThemeOption(context, 'dark', themeController),
                _buildThemeOption(context, 'light', themeController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('cancel'),
                style: TextStyle(
                  color: isDark ? AppColors.brightBlue : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, String theme, ThemeController themeController) {
    return Obx(() {
      final isDark = themeController.isDarkModeActive(context);
      final isSelected = themeController.getCurrentTheme() == theme;

      return Material(
        color: Colors.transparent,
        child: ListTile(
          title: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
            child: Text(_getThemeDisplayName(context, theme)),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: isDark ? AppColors.brightBlue : Colors.blue,
                )
              : null,
          onTap: () async {
            Navigator.pop(context);
            await themeController.setTheme(theme);
          },
        ),
      );
    });
  }

  String _getThemeDisplayName(BuildContext context, String theme) {
    switch (theme) {
      case 'system':
        return context.tr('systemDefault');
      case 'dark':
        return context.tr('darkMode');
      case 'light':
        return context.tr('lightMode');
      default:
        return theme;
    }
  }

  Future<void> _setLanguage(
      LanguageManager languageManager, String language) async {
    switch (language) {
      case 'fa':
        await languageManager.setFarsi();
        break;
      case 'en':
        await languageManager.setEnglish();
        break;
      case 'ar':
        await languageManager.setArabic();
        break;
      case 'ru':
        await languageManager.setRussian();
        break;
      case 'zh':
        await languageManager.setChinese();
        break;
      default:
        await languageManager.setEnglish();
    }
  }
}
