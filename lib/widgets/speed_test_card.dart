// lib/widgets/speed_test_card.dart

import 'package:flutter/material.dart';
import '../path/path.dart';

import '../utils/responsive_size.dart';
import '../widgets/semi_transparent_text.dart';
// assume AppColors, context.tr

class SpeedTestCard extends StatelessWidget {
  final double height;
  final ThemeManager themeManager;

  const SpeedTestCard({
    Key? key,
    required this.height,
    required this.themeManager,
  }) : super(key: key);

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
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
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
              // دکمه اجرای تست سرعت
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SpeedTestPage(),
                    ),
                  );
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
                    context.tr('startTest'),
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
              // آیکون سرعت با افکت سایه
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
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.speed,
                  color: AppColors.pureWhite,
                  size: responsiveSize(
                    18,
                    context,
                    min: 14,
                    max: 25,
                    scaleByHeight: true,
                  ),
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
            text: context.tr('internetSpeedTest'),
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
            backgroundColor: AppColors.textSuccess,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(10),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            padding: EdgeInsets.all(8),
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
                    text: context.tr('speedTest'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('yourInternetSpeedBetween'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('device'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('measuresAndUsesConnection'),
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