import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles/app_styles.dart';
import '../styles/language_manager.dart';
import '../l10n/localization_extension.dart';

/// ویجت انتخاب تم
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      themeManager.themeIcon,
                      color: AppColors.iconPrimary,
                      size: AppSizes.iconL,
                    ),
                    const SizedBox(width: AppSizes.spaceM),
                    Text('تم اپلیکیشن', style: AppTextStyles.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSizes.spaceL),

                // گزینه‌های تم
                _buildThemeOption(
                  context,
                  themeManager,
                  ThemeMode.system,
                  'سیستم',
                  Icons.brightness_auto,
                  'تم سیستم عامل',
                ),
                const SizedBox(height: AppSizes.spaceS),

                _buildThemeOption(
                  context,
                  themeManager,
                  ThemeMode.light,
                  'روشن',
                  Icons.brightness_7,
                  'تم روشن',
                ),
                const SizedBox(height: AppSizes.spaceS),

                _buildThemeOption(
                  context,
                  themeManager,
                  ThemeMode.dark,
                  'تاریک',
                  Icons.brightness_2,
                  'تم تاریک',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeManager themeManager,
    ThemeMode themeMode,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = themeManager.themeMode == themeMode;

    return InkWell(
      onTap: () async {
        switch (themeMode) {
          case ThemeMode.system:
            await themeManager.setSystemTheme();
            break;
          case ThemeMode.light:
            await themeManager.setLightTheme();
            break;
          case ThemeMode.dark:
            await themeManager.setDarkTheme();
            break;
        }
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: isSelected
              ? Border.all(
                  color: AppColors.primaryRed,
                  width: AppSizes.borderMedium,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryRed
                  : AppColors.iconSecondary,
              size: AppSizes.iconL,
            ),
            const SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isSelected ? AppColors.primaryRed : null,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryRed,
                size: AppSizes.iconL,
              ),
          ],
        ),
      ),
    );
  }
}

/// سوییچ ساده برای تغییر تم
class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return SwitchListTile(
          title: Text('تم تاریک', style: AppTextStyles.bodyLarge),
          subtitle: Text(
            'استفاده از تم تاریک',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          value: themeManager.isDarkMode,
          onChanged: (value) async {
            if (value) {
              await themeManager.setDarkTheme();
            } else {
              await themeManager.setLightTheme();
            }
          },
          secondary: Icon(
            themeManager.isDarkMode ? Icons.brightness_2 : Icons.brightness_7,
            color: AppColors.iconPrimary,
          ),
        );
      },
    );
  }
}

/// دکمه سریع برای تغییر تم
class QuickThemeToggle extends StatelessWidget {
  const QuickThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return IconButton(
          onPressed: () async {
            await themeManager.toggleTheme();
          },
          icon: Icon(themeManager.themeIcon),
          tooltip: 'تغییر تم به ${themeManager.themeName}',
        );
      },
    );
  }
}

/// سوییچ تغییر زبان
class LanguageToggleSwitch extends StatelessWidget {
  const LanguageToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      languageManager.languageFlag,
                      style: const TextStyle(fontSize: AppSizes.iconL),
                    ),
                    const SizedBox(width: AppSizes.spaceM),
                    Text(
                      context.tr('language'),
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spaceL),

                // گزینه‌های زبان
                _buildLanguageOption(
                  context,
                  languageManager,
                  const Locale('fa', 'IR'),
                  '🇮🇷',
                  context.tr('farsi'),
                ),
                const SizedBox(height: AppSizes.spaceS),

                _buildLanguageOption(
                  context,
                  languageManager,
                  const Locale('en', 'US'),
                  '🇺🇸',
                  context.tr('english'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LanguageManager languageManager,
    Locale locale,
    String flag,
    String title,
  ) {
    final isSelected =
        languageManager.locale.languageCode == locale.languageCode;

    return InkWell(
      onTap: () async {
        if (locale.languageCode == 'fa') {
          await languageManager.setFarsi();
        } else {
          await languageManager.setEnglish();
        }
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: isSelected
              ? Border.all(
                  color: AppColors.primaryRed,
                  width: AppSizes.borderMedium,
                )
              : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: AppSizes.iconL)),
            const SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected ? AppColors.primaryRed : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryRed,
                size: AppSizes.iconL,
              ),
          ],
        ),
      ),
    );
  }
}

/// دکمه سریع تغییر زبان
class QuickLanguageToggle extends StatelessWidget {
  const QuickLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return IconButton(
          onPressed: () async {
            await languageManager.toggleLanguage();
          },
          icon: Text(
            languageManager.languageFlag,
            style: const TextStyle(fontSize: 20),
          ),
          tooltip: context.tr('changeLanguage'),
        );
      },
    );
  }
}
