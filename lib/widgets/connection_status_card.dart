// lib/widgets/connection_status_card.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// import other necessary
import '../utils/responsive_size.dart';
import '../widgets/semi_transparent_text.dart';
// assume AppColors, context.tr, etc are imported or passed
import '../path/path.dart';

class ConnectionStatusCard extends StatelessWidget {
  final double height;
  final ThemeManager themeManager;
  final bool vpnActive;
  final bool vpnLoading;
  final AnimationController lottieController;
  final VoidCallback onToggleVpn;
  final String? selectedDnsLabel;
  final String? selectedDnsIp;
  final TextEditingController dns1Controller;
  final TextEditingController dns2Controller;

  const ConnectionStatusCard({
    Key? key,
    required this.height,
    required this.themeManager,
    required this.vpnActive,
    required this.vpnLoading,
    required this.lottieController,
    required this.onToggleVpn,
    required this.selectedDnsLabel,
    required this.selectedDnsIp,
    required this.dns1Controller,
    required this.dns2Controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDarkModeActive(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(24, context, min: 10, max: 28, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(
          responsiveSize(14, context, min: 6, max: 20, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // بهبود انیمیشن با کاهش اندازه و تنظیم موقعیت
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double factor = 1.2; // کاهش اندازه انیمیشن
                return Opacity(
                  opacity: 0.45, // کاهش شفافیت برای وضوح بیشتر متن‌ها
                  child: Align(
                    alignment: Alignment.center, // تنظیم در مرکز
                    child: OverflowBox(
                      maxWidth: constraints.maxWidth * factor,
                      maxHeight: constraints.maxHeight * factor,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          responsiveSize(
                            24,
                            context,
                            min: 10,
                            max: 40,
                            scaleByHeight: true,
                          ),
                        ),
                        child: Lottie.asset(
                          'assets/icone/laptop.json',
                          width: constraints.maxWidth * factor,
                          height: constraints.maxHeight * factor,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          controller: lottieController,
                          animate: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // استفاده از SingleChildScrollView برای جلوگیری از سرریز
          SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(), // غیرفعال کردن اسکرول دستی
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: responsiveSize(
                        120,
                        context,
                        min: 60,
                        max: 160,
                        scaleByHeight: true,
                      ),
                      height: responsiveSize(
                        90,
                        context,
                        min: 40,
                        max: 120,
                        scaleByHeight: true,
                      ),
                    ),
                    GestureDetector(
                      onTap: vpnLoading ? null : onToggleVpn,
                      child: TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 500),
                        tween: ColorTween(
                          begin: vpnLoading
                              ? AppColors.textSuccess
                              : (vpnActive
                                  ? AppColors.textSuccess
                                  : AppColors.statusDisconnected),
                          end: vpnActive
                              ? AppColors.textSuccess
                              : AppColors.statusDisconnected,
                        ),
                        builder: (context, color, _) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: responsiveSize(
                              70,
                              context,
                              min: 40,
                              max: 90,
                              scaleByHeight: true,
                            ),
                            height: responsiveSize(
                              70,
                              context,
                              min: 40,
                              max: 90,
                              scaleByHeight: true,
                            ),
                            decoration: BoxDecoration(
                              color: color ?? AppColors.statusDisconnected,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (color ?? AppColors.statusDisconnected)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: vpnLoading
                                  ? Center(
                                      key: const ValueKey('loading'),
                                      child: SizedBox(
                                        width: responsiveSize(
                                          36,
                                          context,
                                          min: 20,
                                          max: 40,
                                          scaleByHeight: true,
                                        ),
                                        height: responsiveSize(
                                          36,
                                          context,
                                          min: 20,
                                          max: 40,
                                          scaleByHeight: true,
                                        ),
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.pureWhite,
                                          ),
                                          strokeWidth: 4,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.power_settings_new,
                                      key: const ValueKey('power'),
                                      color: AppColors.pureWhite,
                                      size: responsiveSize(
                                        40,
                                        context,
                                        min: 24,
                                        max: 48,
                                        scaleByHeight: true,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    // ...existing code...
                  ],
                ),
                SizedBox(
                  height: responsiveSize(
                    16, // کاهش فاصله عمودی
                    context,
                    min: 8,
                    max: 24,
                    scaleByHeight: true,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: (selectedDnsLabel != null &&
                              selectedDnsIp != null &&
                              selectedDnsIp!.isNotEmpty)
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => DnsInfoPopup(
                                  label: selectedDnsLabel!,
                                  ip: selectedDnsIp!,
                                  ping: null,
                                ),
                              );
                            }
                          : null,
                      child: Icon(
                        Icons.info_outline,
                        size: responsiveSize(
                          20,
                          context,
                          min: 14,
                          max: 28,
                          scaleByHeight: true,
                        ),
                        color: (selectedDnsLabel != null &&
                                selectedDnsIp != null &&
                                selectedDnsIp!.isNotEmpty)
                            ? AppColors.brightBlue
                            : AppColors.textLight,
                      ),
                    ),
                    SizedBox(
                      width: responsiveSize(
                        8,
                        context,
                        min: 4,
                        max: 16,
                        scaleByHeight: true,
                      ),
                    ),
                    SemiTransparentText(
                      text: vpnActive
                          ? context.tr('connected')
                          : context.tr('disconnected'),
                      style: TextStyle(
                        fontSize: responsiveSize(
                          24,
                          context,
                          min: 16,
                          max: 48,
                          scaleByHeight: true,
                        ),
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      backgroundColor: vpnActive
                          ? AppColors.textSuccess
                          : Colors.red, // Bright red for disconnected state
                      opacity: 0.15,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                SizedBox(
                  height: responsiveSize(
                    4, // کاهش فاصله عمودی
                    context,
                    min: 2,
                    max: 8,
                    scaleByHeight: true,
                  ),
                ),
                if (selectedDnsLabel != null)
                  Row(
                    children: [
                      Icon(
                        Icons.dns,
                        size: responsiveSize(
                          20,
                          context,
                          min: 14,
                          max: 28,
                          scaleByHeight: true,
                        ),
                        color: vpnActive
                            ? AppColors.textSuccess
                            : AppColors.brightBlue,
                      ),
                      SizedBox(
                        width: responsiveSize(
                          8,
                          context,
                          min: 4,
                          max: 16,
                          scaleByHeight: true,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // نمایش نام DNS
                            SemiTransparentText(
                              text: selectedDnsLabel ?? 'DNS',
                              style: TextStyle(
                                fontSize: responsiveSize(
                                  16,
                                  context,
                                  min: 12,
                                  max: 30,
                                  scaleByHeight: true,
                                ),
                                fontWeight: FontWeight.bold,
                                color: vpnActive
                                    ? AppColors.textSuccess
                                    : AppColors.brightBlue,
                              ),
                              backgroundColor: vpnActive
                                  ? AppColors.textSuccess
                                  : AppColors.brightBlue,
                              opacity: 0.1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 4),
                            // نمایش آدرس‌های IP در یک ردیف برای صرفه‌جویی در فضا
                            SemiTransparentText(
                              text:
                                  "${dns1Controller.text} / ${dns2Controller.text}",
                              style: TextStyle(
                                fontSize: responsiveSize(
                                  12, // کاهش اندازه فونت
                                  context,
                                  min: 8,
                                  max: 20,
                                  scaleByHeight: true,
                                ),
                                fontFamily: 'monospace',
                                color: vpnActive
                                    ? AppColors.textSuccess
                                    : AppColors.brightBlue,
                              ),
                              backgroundColor: vpnActive
                                  ? AppColors.textSuccess
                                  : AppColors.brightBlue,
                              opacity: 0.08,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                // حذف تکرار اطلاعات DNS
              ],
            ),
          ),
        ],
      ),
    );
  }
}