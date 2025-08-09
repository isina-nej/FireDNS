import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../path/path.dart';

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
          'تنظیمات',
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
            title: 'عمومی',
            items: [
              _buildSettingItem(
                icon: Icons.language,
                title: 'زبان برنامه',
                subtitle: 'فارسی',
                onTap: () {
                  // TODO: نمایش دیالوگ تغییر زبان
                },
              ),
              _buildSettingItem(
                icon: Icons.dark_mode,
                title: 'تم برنامه',
                subtitle: themeManager.themeName,
                onTap: () async {
                  await themeManager.toggleTheme();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            title: 'اعلان‌ها',
            items: [
              _buildSettingItem(
                icon: Icons.notifications,
                title: 'اعلان‌های برنامه',
                isSwitch: true,
                onChanged: (value) {
                  // TODO: تغییر وضعیت اعلان‌ها
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            title: 'درباره ما',
            items: [
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'نسخه برنامه',
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
                      value: false, // مقدار پیش‌فرض
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
}
