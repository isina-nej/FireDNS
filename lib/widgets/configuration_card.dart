// lib/widgets/configuration_card.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../path/path.dart';
import '../utils/responsive_size.dart';
import '../widgets/semi_transparent_text.dart';
import '../services/navigation_service.dart';
// assume AppColors, context.tr, DnsListPage, etc

class ConfigurationCard extends StatelessWidget {
  final double height;
  final ThemeManager themeManager;
  final Function(DnsRecord) onDnsSelected;
  final bool vpnActive;
  final Function() deactivateVpn;
  final Function() activateVpn;
  final Function() loadSelectedDnsLabel;
  final Function(String) showSnackBar;

  const ConfigurationCard({
    super.key,
    required this.height,
    required this.themeManager,
    required this.onDnsSelected,
    required this.vpnActive,
    required this.deactivateVpn,
    required this.activateVpn,
    required this.loadSelectedDnsLabel,
    required this.showSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDarkModeActive(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(12, context, min: 6, max: 18, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(
          responsiveSize(12, context, min: 6, max: 16, scaleByHeight: true),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // دکمه Switch (فعال)
              GestureDetector(
                onTap: () async {
                  final result = await NavigationService.navigateToPage(
                    const DnsListPage(),
                  );

                  // اگر کاربر DNS جدیدی انتخاب کرده
                  if (result != null && result is DnsRecord) {
                    debugPrint('User selected DNS: ${result.label}');
                    debugPrint('IP1: ${result.ip1}, IP2: ${result.ip2}');

                    onDnsSelected(result);

                    // ذخیره DNS انتخابی در SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('cached_selected_dns', result.id);

                    // اگر VPN فعال است، با DNS جدید مجدداً متصل شود
                    if (vpnActive) {
                      showSnackBar('در حال اعمال DNS جدید...');

                      // ابتدا VPN را قطع کن
                      await deactivateVpn();

                      // سپس با DNS جدید وصل کن
                      await Future.delayed(const Duration(milliseconds: 500));
                      await activateVpn();
                    }
                  } else {
                    // اگر کاربر بدون انتخاب برگشت، DNS قبلی را بارگذاری کن
                    await loadSelectedDnsLabel();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveSize(
                      16,
                      context,
                      min: 8,
                      max: 25,
                      scaleByHeight: true,
                    ),
                    vertical: responsiveSize(
                      8,
                      context,
                      min: 4,
                      max: 12,
                      scaleByHeight: true,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brightBlue,
                    borderRadius: BorderRadius.circular(
                      responsiveSize(
                        16,
                        context,
                        min: 8,
                        max: 25,
                        scaleByHeight: true,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brightBlue.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    context.tr('changeDns'),
                    style: TextStyle(
                      fontSize: responsiveSize(
                        14,
                        context,
                        min: 12,
                        max: 30,
                        scaleByHeight: true,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
              // آیکون تنظیمات با افکت سایه
              Container(
                width: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                height: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textSuccess,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textSuccess.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      color: AppColors.pureWhite,
                      size: responsiveSize(
                        16,
                        context,
                        min: 12,
                        max: 20,
                        scaleByHeight: true,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: responsiveSize(
                          6,
                          context,
                          min: 4,
                          max: 8,
                          scaleByHeight: true,
                        ),
                        height: responsiveSize(
                          6,
                          context,
                          min: 4,
                          max: 8,
                          scaleByHeight: true,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.textSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: responsiveSize(
              8, // کاهش فاصله عمودی
              context,
              min: 4,
              max: 12,
              scaleByHeight: true,
            ),
          ),
          SemiTransparentText(
            text: context.tr('networkConfiguration'),
            style: TextStyle(
              fontSize: responsiveSize(
                18,
                context,
                min: 14,
                max: 48,
                scaleByHeight: true,
              ),
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            backgroundColor: AppColors.brightBlue,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          SizedBox(
            height: responsiveSize(
              4, // کاهش فاصله عمودی
              context,
              min: 2,
              max: 6,
              scaleByHeight: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary)
                  .withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: responsiveSize(
                    15,
                    context,
                    min: 10,
                    max: 30,
                    scaleByHeight: true,
                  ),
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: context.tr('inThisSection'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('networkSettings'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('customizeYour'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('configuration'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('chooseAccordingToNeeds'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
