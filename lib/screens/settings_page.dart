import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../path/path.dart';
import '../services/notification_service.dart';
import '../services/dns_test_settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
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
          icon: Icon(
            Icons.arrow_back, 
            color: isDark ? AppColors.darkIconPrimary : Colors.black54
          ),
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
                subtitle: themeManager.themeName,
                onTap: () async {
                  await themeManager.toggleTheme();
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
                      _showTestTypeSelectionDialog(context, dnsTestSettingsService);
                    },
                  );
                },
              ),
              Consumer<DnsTestSettingsService>(
                builder: (context, dnsTestSettingsService, child) {
                  return _buildSettingItem(
                    icon: Icons.numbers,
                    title: context.tr('testCount'),
                    subtitle: dnsTestSettingsService.testCount.toString(),
                    onTap: () {
                      _showTestCountSelectionDialog(context, dnsTestSettingsService);
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
    return Builder(
      builder: (context) {
        final isDark = Provider.of<ThemeManager>(context).isDarkModeActive(context);
    
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
      }
    );
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
    return Builder(
      builder: (context) {
        final isDark = Provider.of<ThemeManager>(context).isDarkModeActive(context);
    
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSwitch ? null : onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isDark ? AppColors.brightBlue : Colors.blue,
                    size: 24
                  ),
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
                            color: isDark ? AppColors.darkTextPrimary : Colors.black,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
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
      }
    );
  }
  
  void _showLanguageSelectionDialog(BuildContext context, LanguageManager languageManager) {
    final isDark = Provider.of<ThemeManager>(context, listen: false).isDarkModeActive(context);
    
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
  
  Widget _buildLanguageOption(BuildContext context, String name, String code, LanguageManager languageManager) {
    final isDark = Provider.of<ThemeManager>(context, listen: false).isDarkModeActive(context);
    final isSelected = languageManager.locale.languageCode == code;
    
    return ListTile(
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
        Navigator.pop(context);
      },
    );
  }
  
  void _showTestTypeSelectionDialog(BuildContext context, DnsTestSettingsService dnsTestSettingsService) {
    final isDark = Provider.of<ThemeManager>(context, listen: false).isDarkModeActive(context);
    
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
            _buildTestTypeOption(context, 'simultaneous', dnsTestSettingsService),
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
  
  Widget _buildTestTypeOption(BuildContext context, String type, DnsTestSettingsService dnsTestSettingsService) {
    final isDark = Provider.of<ThemeManager>(context, listen: false).isDarkModeActive(context);
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
  
  void _showTestCountSelectionDialog(BuildContext context, DnsTestSettingsService dnsTestSettingsService) {
    final isDark = Provider.of<ThemeManager>(context, listen: false).isDarkModeActive(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          context.tr('testCount'),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTestCountOption(context, 3, dnsTestSettingsService),
            _buildTestCountOption(context, 5, dnsTestSettingsService),
            _buildTestCountOption(context, 10, dnsTestSettingsService),
            _buildTestCountOption(context, 15, dnsTestSettingsService),
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
  
  Widget _buildTestCountOption(BuildContext context, int count, DnsTestSettingsService dnsTestSettingsService) {
    final isDark = Provider.of<ThemeManager>(context, listen: false).isDarkModeActive(context);
    final isSelected = dnsTestSettingsService.testCount == count;
    
    return ListTile(
      title: Text(
        count.toString(),
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
        await dnsTestSettingsService.setTestCount(count);
        Navigator.pop(context);
      },
    );
  }
}
