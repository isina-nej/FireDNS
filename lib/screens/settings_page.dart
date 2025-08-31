import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' show Lottie, LottieDelegates, ValueDelegate;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          elevation: 0,
          title: Text(
            context.tr('settings'),
            style: TextStyle(
              fontFamily: Provider.of<LanguageManager>(context, listen: false)
                  .fontFamily,
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
                        _showLanguageSelectionDialog(context, languageManager);
                      },
                    );
                  },
                ),
                _buildSettingItem(
                  icon: 'assets/icone/theme.json',
                  title: context.tr('appTheme'),
                  subtitle: themeManager.getThemeName(context),
                  onTap: () {
                    _showThemeSelectionDialog(context, themeManager);
                  },
                ),
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
                  // onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> items,
  }) {
    return Builder(builder: (context) {
      final isDark =
          Provider.of<ThemeManager>(context).isDarkModeActive(context);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : Colors.grey,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
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
            child: Column(children: items),
          ),
        ],
      );
    });
  }

  Widget _buildSettingItem({
    dynamic icon, // Can be IconData or String (for Lottie asset)
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onChanged,
  }) {
    return Builder(builder: (context) {
      final isDark =
          Provider.of<ThemeManager>(context).isDarkModeActive(context);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSwitch ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icon is IconData)
                  Icon(icon,
                      color: isDark ? AppColors.brightBlue : Colors.blue,
                      size: MediaQuery.of(context).size.width * 0.16)
                else if (icon is String)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.width * 0.15,
                    child: Lottie.asset(
                      icon,
                      fit: BoxFit.contain,
                      delegates: icon == 'assets/icone/notifications.json'
                          ? LottieDelegates(
                              values: [
                                ValueDelegate.color(
                                  const ['**'],
                                  value: Colors.yellow,
                                ),
                              ],
                            )
                          : icon == 'assets/icone/laptop.json'
                              ? LottieDelegates(
                                  values: [
                                    ValueDelegate.color(
                                      const ['**'],
                                      value: Colors.lightBlueAccent,
                                    ),
                                  ],
                                )
                              : icon == 'assets/icone/info.json'
                                  ? LottieDelegates(
                                      values: [
                                        ValueDelegate.color(
                                          const ['**'],
                                          value: Colors.tealAccent,
                                        ),
                                      ],
                                    )
                                  : icon == 'assets/icone/website_new.json'
                                      ? LottieDelegates(
                                          values: [
                                            ValueDelegate.color(
                                              const ['**'],
                                              value: Colors.blueAccent,
                                            ),
                                          ],
                                        )
                                      : icon == 'assets/icone/github_alt.json'
                                          ? LottieDelegates(
                                              values: [
                                                ValueDelegate.color(
                                                  const ['**'],
                                                  value: const Color.fromARGB(
                                                      255, 47, 47, 47),
                                                ),
                                              ],
                                            )
                                          : null,
                    ),
                  )
                else
                  Icon(Icons.help_outline,
                      color: isDark ? AppColors.brightBlue : Colors.blue,
                      size: MediaQuery.of(context).size.width * 0.16),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? AppColors.darkTextPrimary : Colors.black,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.005),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSwitch)
                  Switch(
                    value: switchValue,
                    onChanged: onChanged,
                    activeThumbColor:
                        isDark ? AppColors.brightBlue : Colors.blue,
                  )
                else if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDark ? AppColors.darkIconSecondary : Colors.grey,
                    size: MediaQuery.of(context).size.width * 0.04,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showLanguageSelectionDialog(
      BuildContext context, LanguageManager languageManager) {
    final isDark = Provider.of<ThemeManager>(context, listen: false)
        .isDarkModeActive(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          context.tr('changeLanguage'),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, 'فارسی', 'fa', languageManager),
            _buildLanguageOption(context, 'English', 'en', languageManager),
            _buildLanguageOption(context, 'العربية', 'ar', languageManager),
            _buildLanguageOption(context, 'Русский', 'ru', languageManager),
            _buildLanguageOption(context, '中文', 'zh', languageManager),
          ],
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
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, String code,
      LanguageManager languageManager) {
    final isDark = Provider.of<ThemeManager>(context, listen: false)
        .isDarkModeActive(context);
    final isSelected = languageManager.locale.languageCode == code;
    final deviceLocale = PlatformDispatcher.instance.locale;
    final isDeviceLanguage = deviceLocale.languageCode == code;

    return ListTile(
      onTap: () async {
        switch (code) {
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
        }
        if (mounted) {
          setState(() {});
          Navigator.pop(context);
        }
      },
      subtitle: isDeviceLanguage
          ? Text(
              context.tr('deviceLanguage'),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : Colors.grey,
              ),
            )
          : null,
      title: Text(
        name,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: isDark ? AppColors.brightBlue : Colors.blue,
            )
          : null,
    );
  }

  void _showTestTypeSelectionDialog(
      BuildContext context, DnsTestSettingsService dnsTestSettingsService) {
    final isDark = Provider.of<ThemeManager>(context, listen: false)
        .isDarkModeActive(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          context.tr('testType'),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTestTypeOption(context, 'auto', dnsTestSettingsService),
            _buildTestTypeOption(
              context,
              'simultaneous',
              dnsTestSettingsService,
              subtitle: context.tr('highSpeed'),
              subtitleIcon: Icons.flash_on,
            ),
            _buildTestTypeOption(
              context,
              'sequential',
              dnsTestSettingsService,
              subtitle: context.tr('highAccuracy'),
              subtitleIcon: Icons.verified,
            ),
            _buildAdvancedTestTypeOption(context),
          ],
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
    );
  }

  Widget _buildTestTypeOption(
    BuildContext context,
    String type,
    DnsTestSettingsService dnsTestSettingsService, {
    String? subtitle,
    IconData? subtitleIcon,
  }) {
    final isDark = Provider.of<ThemeManager>(context, listen: false)
        .isDarkModeActive(context);
    final isSelected = dnsTestSettingsService.testType == type;

    return ListTile(
      title: Text(
        dnsTestSettingsService.getTestTypeName(type, context),
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Row(
              children: [
                if (subtitleIcon != null)
                  Icon(subtitleIcon,
                      size: MediaQuery.of(context).size.width * 0.04,
                      color: isDark
                          ? AppColors.brightBlue
                          : AppColors.primaryBlue),
                SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : null,
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: isDark ? AppColors.brightBlue : Colors.blue,
            )
          : null,
      onTap: type == 'advanced'
          ? null
          : () async {
              await dnsTestSettingsService.setTestType(type);
              Navigator.pop(context);
            },
      enabled: type != 'advanced',
    );
  }

  Widget _buildAdvancedTestTypeOption(BuildContext context) {
    final isDark = Provider.of<ThemeManager>(context, listen: false)
        .isDarkModeActive(context);
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('comingSoon')),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: AbsorbPointer(
        child: ListTile(
          title: Text(
            context.tr('advancedTest'),
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
              fontWeight: FontWeight.normal,
            ),
          ),
          subtitle: Text(
            context.tr('comingSoon'),
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
              fontSize: 12,
            ),
          ),
          enabled: false,
        ),
      ),
    );
  }

  void _showThemeSelectionDialog(
      BuildContext context, ThemeManager themeManager) {
    final isDark = Provider.of<ThemeManager>(context, listen: false)
        .isDarkModeActive(context);

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
                _buildThemeOption(context, 'system', themeManager),
                _buildThemeOption(context, 'dark', themeManager),
                _buildThemeOption(context, 'light', themeManager),
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
      BuildContext context, String theme, ThemeManager themeManager) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final isDark = themeManager.isDarkModeActive(context);
        final isSelected = themeManager.getCurrentTheme() == theme;

        return Material(
          color: Colors.transparent,
          child: ListTile(
            title: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
              await themeManager.setTheme(theme);
            },
          ),
        );
      },
    );
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
}
