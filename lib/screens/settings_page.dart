import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../path/path.dart';
import '../services/notification_service.dart';
import '../services/dns_test_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
      final deviceLocale = WidgetsBinding.instance.window.locale;
      languageManager.getDeviceLanguage(deviceLocale);
    });
  }

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
          context.tr('settings'),
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
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingSection(
            title: context.tr('general'),
            items: [
              Consumer<LanguageManager>(
                builder: (context, languageManager, child) {
                  return _buildSettingItem(
                    icon: Icons.language,
                    title: context.tr('language'),
                    subtitle: languageManager.languageName,
                    onTap: () {
                      _showLanguageSelectionDialog(context, languageManager);
                    },
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.dark_mode,
                title: context.tr('appTheme'),
                subtitle: themeManager.getThemeName(context),
                onTap: () {
                  _showThemeSelectionDialog(context, themeManager);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            title: context.tr('notifications'),
            items: [
              Consumer<NotificationService>(
                builder: (context, notificationService, child) {
                  return _buildSettingItem(
                    icon: Icons.notifications,
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
          const SizedBox(height: 16),
          _buildSettingSection(
            title: context.tr('dnsTest'),
            items: [
              Consumer<DnsTestSettingsService>(
                builder: (context, dnsTestSettingsService, child) {
                  return _buildSettingItem(
                    icon: Icons.dns,
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
          const SizedBox(height: 16),
          _buildSettingSection(
            title: context.tr('aboutUs'),
            items: [
              _buildSettingItem(
                icon: Icons.info_outline,
                title: context.tr('appVersion'),
                subtitle: '1.0.0',
                onTap: () {},
              ),
            ],
          ),
        ],
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
    required IconData icon,
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
                Icon(icon,
                    color: isDark ? AppColors.brightBlue : Colors.blue,
                    size: 24),
                const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
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
                    activeColor: isDark ? AppColors.brightBlue : Colors.blue,
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDark ? AppColors.darkIconSecondary : Colors.grey,
                    size: 16,
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
    final deviceLocale = WidgetsBinding.instance.window.locale;
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
                context, 'simultaneous', dnsTestSettingsService),
            _buildTestTypeOption(context, 'sequential', dnsTestSettingsService),
            _buildTestTypeOption(context, 'advanced', dnsTestSettingsService),
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

  Widget _buildTestTypeOption(BuildContext context, String type,
      DnsTestSettingsService dnsTestSettingsService) {
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
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: isDark ? AppColors.brightBlue : Colors.blue,
            )
          : null,
      onTap: () async {
        await dnsTestSettingsService.setTestType(type);
        Navigator.pop(context);
      },
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
