// lib/widgets/dns_card.dart

import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/path/path.dart'; // Assuming AppColors, context.tr are defined here or in imports
import 'package:firedns/widgets/animated_overflow_label.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class DnsCard extends StatelessWidget {
  final DnsRecord record;
  final int index;
  final bool isSelected;
  final Map<String, int> pingCache;
  final bool isUserDns;
  final Function(DnsRecord) onConnect;
  final Function(DnsRecord) onRePing;
  final Function(String) onToggleLike;
  final Function(DnsRecord) onEdit;
  final Function(DnsRecord) onDelete;
  final Function(DnsRecord)? onCopy;
  final Function(DnsRecord)? onBlock;
  final Function(DnsRecord)? onReport;
  final bool isLoading;
  final List<String> likedDnsIds;

  // Selection mode parameters
  final bool isSelectionMode;
  final bool isSelectedForBulk;
  final Function(String)? onToggleSelection;
  final Function(String)? onLongPress;

  const DnsCard({
    super.key,
    required this.record,
    required this.index,
    required this.isSelected,
    required this.pingCache,
    required this.isUserDns,
    required this.onConnect,
    required this.onRePing,
    required this.onToggleLike,
    required this.onEdit,
    required this.onDelete,
    this.onCopy,
    this.onBlock,
    this.onReport,
    required this.isLoading,
    required this.likedDnsIds,
    this.isSelectionMode = false,
    this.isSelectedForBulk = false,
    this.onToggleSelection,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive(context);
    final ping1 = pingCache['${record.id}_1'] ?? pingCache[record.id];
    final ping2 = pingCache['${record.id}_2'] ?? pingCache[record.id];

    int? bestPing;
    int? bestPing2;
    if (ping1 != null && ping2 != null && ping1 >= 0 && ping2 >= 0) {
      if (ping1 <= ping2) {
        bestPing = ping1;
        bestPing2 = ping2;
      } else {
        bestPing = ping2;
        bestPing2 = ping1;
      }
    } else if (ping1 != null && ping1 >= 0) {
      bestPing = ping1;
      bestPing2 = null;
    } else if (ping2 != null && ping2 >= 0) {
      bestPing = ping2;
      bestPing2 = null;
    } else {
      // اگر پینگ در کش وجود ندارد، مقدار پیش‌فرض نمایش دهیم
      bestPing = null;
      bestPing2 = null;
    }

    Color pingColor;
    if (bestPing == null) {
      pingColor = Colors.grey.shade400;
    } else if (bestPing < 50) {
      pingColor = AppColors.pingExcellent;
    } else if (bestPing < 120) {
      pingColor = AppColors.pingGood;
    } else if (bestPing < 250) {
      pingColor = AppColors.pingMedium;
    } else if (bestPing < 500) {
      pingColor = AppColors.pingPoor;
    } else {
      pingColor = AppColors.pingBad;
    }
    Color ping2Color;
    if (bestPing2 == null) {
      ping2Color = Colors.grey.shade400;
    } else if (bestPing2 < 50) {
      ping2Color = AppColors.pingExcellent;
    } else if (bestPing2 < 120) {
      ping2Color = AppColors.pingGood;
    } else if (bestPing2 < 250) {
      ping2Color = AppColors.pingMedium;
    } else if (bestPing2 < 500) {
      ping2Color = AppColors.pingPoor;
    } else {
      ping2Color = AppColors.pingBad;
    }

    return ClipRect(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.15,
        child: Card(
          elevation: isSelectedForBulk ? 4 : (isSelected ? 4 : 1),
          color: isDark
              ? (isSelectedForBulk
                  ? AppColors.brightBlue.withAlpha((0.1 * 255).round())
                  : (isSelected
                      ? AppColors.darkCardBackground
                          .withAlpha((0.8 * 255).round())
                      : AppColors.darkCardBackground))
              : (isSelectedForBulk
                  ? AppColors.brightBlue.withAlpha((0.15 * 255).round())
                  : (isSelected ? AppColors.selectedLight : Colors.white)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onTap: () {
              if (isSelectionMode) {
                onToggleSelection?.call(record.id);
              } else if (!isLoading) {
                onConnect(record);
              }
            },
            onLongPress: () {
              if (!isSelectionMode) {
                onLongPress?.call(record.id);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isSelectedForBulk
                    ? Border.all(
                        color:
                            AppColors.brightBlue.withAlpha((0.3 * 255).round()),
                        width: 1)
                    : null,
                color: isDark
                    ? (isSelectedForBulk
                        ? AppColors.brightBlue.withAlpha((0.1 * 255).round())
                        : (isSelected
                            ? AppColors.darkCardBackground
                                .withAlpha((0.8 * 255).round())
                            : AppColors.darkCardBackground))
                    : (isSelectedForBulk
                        ? AppColors.brightBlue.withAlpha((0.15 * 255).round())
                        : (isSelected
                            ? AppColors.selectedLight
                            : Colors.white)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.09,
                          height: MediaQuery.of(context).size.width * 0.09,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue
                                .withAlpha((0.08 * 255).round()),
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.03),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF5A9CFF),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.03),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final text = record.label;
                                          final textStyle = TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : const Color(0xFF222B45),
                                          );
                                          final textPainter = TextPainter(
                                            text: TextSpan(
                                              text: text,
                                              style: textStyle,
                                            ),
                                            maxLines: 1,
                                            textDirection: TextDirection.ltr,
                                          )..layout(
                                              maxWidth: constraints.maxWidth);
                                          final isOverflow = textPainter.width >
                                              constraints.maxWidth;
                                          if (isOverflow) {
                                            return AnimatedOverflowLabel(
                                              label: text,
                                              width: constraints.maxWidth,
                                              style: textStyle,
                                            );
                                          } else {
                                            return Text(text, style: textStyle);
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        likedDnsIds.contains(record.id)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: likedDnsIds.contains(record.id)
                                            ? Colors.red
                                            : Colors.grey.shade400,
                                      ),
                                      tooltip: likedDnsIds.contains(record.id)
                                          ? context.tr('removeFromFavorites')
                                          : context.tr('addToFavorites'),
                                      onPressed: () => onToggleLike(record.id),
                                    ),
                                    // Hide the three-dot menu when in selection mode
                                    if (!isSelectionMode)
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: isDark
                                              ? AppColors.darkIconPrimary
                                              : Colors.grey.shade600,
                                        ),
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'copy':
                                              onCopy?.call(record);
                                              break;
                                            case 'delete':
                                              onDelete(record);
                                              break;
                                            case 'block':
                                              onBlock?.call(record);
                                              break;
                                            case 'report':
                                              onReport?.call(record);
                                              break;
                                            case 'like':
                                              if (!likedDnsIds
                                                  .contains(record.id)) {
                                                onToggleLike(record.id);
                                              }
                                              break;
                                            case 'unlike':
                                              if (likedDnsIds
                                                  .contains(record.id)) {
                                                onToggleLike(record.id);
                                              }
                                              break;
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          // Like/Unlike option
                                          if (likedDnsIds.contains(record.id))
                                            PopupMenuItem<String>(
                                              value: 'unlike',
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons.favorite_border,
                                                      color: Colors.grey,
                                                      size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(context.tr(
                                                      'removeFromFavorites')),
                                                ],
                                              ),
                                            )
                                          else
                                            PopupMenuItem<String>(
                                              value: 'like',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.favorite,
                                                      color: Colors.red,
                                                      size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(context
                                                      .tr('addToFavorites')),
                                                ],
                                              ),
                                            ),
                                          // Copy option
                                          PopupMenuItem<String>(
                                            value: 'copy',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.copy,
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Text(context.tr('copy')),
                                              ],
                                            ),
                                          ),
                                          // Delete option (only for non-user DNS or in selection mode)
                                          if (!isUserDns || isSelectionMode)
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete,
                                                      color: Colors.red,
                                                      size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(context.tr('delete')),
                                                ],
                                              ),
                                            ),
                                          // Block option
                                          PopupMenuItem<String>(
                                            value: 'block',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.block,
                                                    color: Colors.orange,
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Text(context.tr('block')),
                                              ],
                                            ),
                                          ),
                                          // Report option
                                          PopupMenuItem<String>(
                                            value: 'report',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.report,
                                                    color: Colors.red,
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Text(context.tr('report')),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (isUserDns) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        tooltip: context.tr('edit'),
                                        onPressed: () => onEdit(record),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: context.tr('delete'),
                                        onPressed: () => onDelete(record),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.005),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.dns,
                                      size: MediaQuery.of(context).size.width *
                                          0.045,
                                      color: isDark
                                          ? AppColors.darkIconPrimary
                                          : const Color(0xFF5A9CFF),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.01),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final text = record.ip1;
                                          const textStyle = TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF607D8B),
                                          );
                                          final textPainter = TextPainter(
                                            text: TextSpan(
                                              text: text,
                                              style: textStyle,
                                            ),
                                            maxLines: 1,
                                            textDirection: TextDirection.ltr,
                                          )..layout(
                                              maxWidth: constraints.maxWidth);
                                          final isOverflow = textPainter.width >
                                              constraints.maxWidth;
                                          if (isOverflow) {
                                            return AnimatedOverflowLabel(
                                              label: text,
                                              width: constraints.maxWidth,
                                              style: textStyle,
                                            );
                                          } else {
                                            return Text(text, style: textStyle);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    // همیشه پینگ را نمایش دهیم
                                    Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: (event) {
                                        if (Theme.of(context).platform ==
                                            TargetPlatform.windows) {
                                          if (event.kind ==
                                              PointerDeviceKind.mouse) {
                                            onRePing(record);
                                          }
                                        }
                                      },
                                      child: GestureDetector(
                                        onTap: () => onRePing(record),
                                        behavior: HitTestBehavior.opaque,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.speed,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.045,
                                              color: pingColor,
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.005),
                                            bestPing == -2
                                                ? SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.045,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.045,
                                                    child:
                                                        const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : (bestPing == null ||
                                                        bestPing == -1 ||
                                                        bestPing < 0 ||
                                                        bestPing >= 1000)
                                                    ? Text(
                                                        bestPing == null
                                                            ? 'N/A'
                                                            : '---',
                                                        style: TextStyle(
                                                          color: pingColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      )
                                                    : Text(
                                                        '$bestPing ms',
                                                        style: TextStyle(
                                                          color: pingColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                            if (bestPing != null &&
                                                bestPing > 0 &&
                                                bestPing < 80)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 2,
                                                ),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.055,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.055,
                                                child: Lottie.asset(
                                                  'assets/icone/Fire.json',
                                                  repeat: true,
                                                  animate: true,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.0025),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.dns_outlined,
                                      size: MediaQuery.of(context).size.width *
                                          0.045,
                                      color: isDark
                                          ? AppColors.darkIconSecondary
                                          : const Color(0xFFB0BEC5),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.01),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final text = record.ip2 ?? '';
                                          const textStyle = TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF90A4AE),
                                          );
                                          final textPainter = TextPainter(
                                            text: TextSpan(
                                              text: text,
                                              style: textStyle,
                                            ),
                                            maxLines: 1,
                                            textDirection: TextDirection.ltr,
                                          )..layout(
                                              maxWidth: constraints.maxWidth);
                                          final isOverflow = textPainter.width >
                                              constraints.maxWidth;
                                          if (isOverflow) {
                                            return AnimatedOverflowLabel(
                                              label: text,
                                              width: constraints.maxWidth,
                                              style: textStyle,
                                            );
                                          } else {
                                            return Text(text, style: textStyle);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    // همیشه پینگ دوم را نمایش دهیم
                                    Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: (event) {
                                        if (Theme.of(context).platform ==
                                            TargetPlatform.windows) {
                                          if (event.kind ==
                                              PointerDeviceKind.mouse) {
                                            onRePing(record);
                                          }
                                        }
                                      },
                                      child: GestureDetector(
                                        onTap: () => onRePing(record),
                                        behavior: HitTestBehavior.opaque,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.speed,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.045,
                                              color: ping2Color,
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.005),
                                            bestPing2 == -2
                                                ? SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.045,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.045,
                                                    child:
                                                        const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : (bestPing2 == null ||
                                                        bestPing2 == -1 ||
                                                        bestPing2 < 0 ||
                                                        bestPing2 >= 1000)
                                                    ? Text(
                                                        bestPing2 == null
                                                            ? 'N/A'
                                                            : '---',
                                                        style: TextStyle(
                                                          color: ping2Color,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      )
                                                    : Text(
                                                        '$bestPing2 ms',
                                                        style: TextStyle(
                                                          color: ping2Color,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                            if (bestPing2 != null &&
                                                bestPing2 > 0 &&
                                                bestPing2 < 80)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 2,
                                                ),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.055,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.055,
                                                child: Lottie.asset(
                                                  'assets/icone/Fire.json',
                                                  repeat: true,
                                                  animate: true,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isSelected && isLoading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.06,
                          height: MediaQuery.of(context).size.width * 0.06,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
