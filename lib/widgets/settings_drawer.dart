import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'theme_selector.dart';

/// منوی کناری تنظیمات
class SettingsDrawer extends StatefulWidget {
  final bool autoStartOnBoot;
  final bool darkTheme;
  final bool notificationsEnabled;
  final String currentDns1;
  final String currentDns2;
  final String currentIpv4;
  final Function(bool) onAutoStartChanged;
  final Function(bool) onDarkThemeChanged;
  final Function(bool) onNotificationsChanged;
  final VoidCallback onAboutPressed;
  final VoidCallback onSupportPressed;
  final VoidCallback onChangeServerPressed;

  const SettingsDrawer({
    Key? key,
    required this.autoStartOnBoot,
    required this.darkTheme,
    required this.notificationsEnabled,
    required this.currentDns1,
    required this.currentDns2,
    required this.currentIpv4,
    required this.onAutoStartChanged,
    required this.onDarkThemeChanged,
    required this.onNotificationsChanged,
    required this.onAboutPressed,
    required this.onSupportPressed,
    required this.onChangeServerPressed,
  }) : super(key: key);

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.drawerBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.spaceXL),

                // Header with Personal and menu icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Personal',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: const Icon(
                        Icons.apps,
                        color: AppColors.textWhite,
                        size: AppSizes.iconL,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spaceXXXL),

                // UI specs section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UI specs',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingS),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.monitor,
                        color: AppColors.textWhite,
                        size: AppSizes.iconM,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spaceXL),

                // UI specs card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.paddingXL),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: AppSizes.borderThick,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: AppSizes.radiusM,
                            height: AppSizes.radiusM,
                            decoration: const BoxDecoration(
                              color: AppColors.statusUnknown,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSizes.spaceXL),
                          Text(
                            'Corners 2 dp',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spaceL),
                      Row(
                        children: [
                          Container(
                            width: AppSizes.radiusM,
                            height: AppSizes.radiusM,
                            decoration: const BoxDecoration(
                              color: AppColors.statusUnknown,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSizes.spaceM),
                          Container(
                            width: 60,
                            height: AppSizes.spaceXL,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusXS,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.spaceXL),
                          Text(
                            'Border 4 dp',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.spaceXXXL),

                // Change Server section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.paddingXL),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: AppSizes.borderThick,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Change Server button
                      GestureDetector(
                        onTap: widget.onChangeServerPressed,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.paddingM,
                            horizontal: AppSizes.paddingXL,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGrey,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusXS,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Change Server',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(Icons.wifi, color: Colors.red, size: 24),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // DNS Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.currentDns1,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'DNS2 ${widget.currentDns2}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Unknown',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Current IPv4',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              Text(
                                'DNS1 ${widget.currentIpv4}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Notifications toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.notifications_outlined,
                          color: Colors.black,
                          size: 24,
                        ),
                      ],
                    ),
                    Switch(
                      value: widget.notificationsEnabled,
                      onChanged: widget.onNotificationsChanged,
                      activeColor: Colors.red,
                      activeTrackColor: Colors.red.shade100,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spaceXXL),

                // تنظیمات تم
                const ThemeToggleSwitch(),

                const SizedBox(height: AppSizes.spaceL),

                // تنظیمات زبان
                const LanguageToggleSwitch(),

                const SizedBox(height: AppSizes.spaceXXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
