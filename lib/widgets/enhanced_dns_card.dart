import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/models/dns_management.dart';
import 'package:firedns/path/path.dart';
import 'package:firedns/widgets/animated_overflow_label.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// ویجت کارت DNS پیشرفته با قابلیت انتخاب و نمایش وضعیت مدیریت
class EnhancedDnsCard extends StatelessWidget {
  final DnsRecord record;
  final int index;
  final Map<String, int> pingCache;
  final bool isUserDns;
  final Function(DnsRecord) onConnect;
  final Function(DnsRecord) onRePing;
  final Function(String) onToggleLike;
  final Function(DnsRecord) onEdit;
  final Function(DnsRecord) onDelete;
  final bool isLoading;
  final List<String> likedDnsIds;
  final DnsSelectionService selectionService;
  final DnsManagementService dnsManagementService;

  // Snackbar management parameters
  final DateTime? lastSnackBarTime;
  final String? lastSnackBarMessage;
  final Function(DateTime?) setLastSnackBarTime;
  final Function(String?) setLastSnackBarMessage;

  const EnhancedDnsCard({
    super.key,
    required this.record,
    required this.index,
    required this.pingCache,
    required this.isUserDns,
    required this.onConnect,
    required this.onRePing,
    required this.onToggleLike,
    required this.onEdit,
    required this.onDelete,
    required this.isLoading,
    required this.likedDnsIds,
    required this.selectionService,
    required this.dnsManagementService,
    required this.lastSnackBarTime,
    required this.lastSnackBarMessage,
    required this.setLastSnackBarTime,
    required this.setLastSnackBarMessage,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive(context);

    return Consumer2<DnsSelectionService, DnsManagementService>(
        builder: (context, selectionService, dnsManagementService, child) {
      final isSelected = selectionService.isDnsSelected(record.id);
      final dnsStatus = dnsManagementService.getDnsStatus(record.id);
      final isBlocked = dnsStatus == DnsManagementStatus.blocked;

      return GestureDetector(
        onLongPress: () {
          if (!selectionService.isSelectionMode) {
            selectionService.enterSelectionMode();
          }
          selectionService.toggleDnsSelection(record.id);
        },
        onTap: () {
          if (selectionService.isSelectionMode) {
            selectionService.toggleDnsSelection(record.id);
          } else {
            // Normal tap behavior
            onConnect(record);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getCardColor(isDark, isSelected, isBlocked),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBorderColor(isDark, isSelected, isBlocked),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brightBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              _buildCardContent(context, isDark, isSelected, isBlocked),
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.brightBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (isBlocked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'مسدود',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCardContent(
    BuildContext context,
    bool isDark,
    bool isSelected,
    bool isBlocked,
  ) {
    final ping1 = pingCache['${record.id}_1'] ?? pingCache[record.id];
    final ping2 = pingCache['${record.id}_2'] ?? pingCache[record.id];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and actions
          Row(
            children: [
              Expanded(
                child: AnimatedOverflowLabel(
                  label: record.label,
                  width: MediaQuery.of(context).size.width * 0.5,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(isDark, isBlocked),
                  ),
                ),
              ),
              if (!selectionService.isSelectionMode) ...[
                _buildLikeButton(isDark),
                _buildMoreActionsButton(context, isDark),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // DNS IPs
          Text(
            record.ip1,
            style: TextStyle(
              fontSize: 14,
              color: _getSecondaryTextColor(isDark, isBlocked),
              fontFamily: 'monospace',
            ),
          ),
          if (record.ip2 != null) ...[
            const SizedBox(height: 2),
            Text(
              record.ip2!,
              style: TextStyle(
                fontSize: 14,
                color: _getSecondaryTextColor(isDark, isBlocked),
                fontFamily: 'monospace',
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Ping results and connect button
          Row(
            children: [
              Expanded(
                child: _buildPingDisplay(ping1, ping2, isDark, isBlocked),
              ),
              if (!selectionService.isSelectionMode)
                _buildConnectButton(context, isDark),
            ],
          ),

          // User DNS indicator
          if (isUserDns) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.brightBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'DNS شخصی',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.brightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLikeButton(bool isDark) {
    final isLiked = likedDnsIds.contains(record.id);
    return IconButton(
      onPressed: () => onToggleLike(record.id),
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked
            ? Colors.red
            : (isDark ? Colors.white70 : Colors.grey.shade600),
        size: 20,
      ),
    );
  }

  Widget _buildMoreActionsButton(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleAction(context, value),
      icon: Icon(
        Icons.more_vert,
        color: isDark ? Colors.white70 : Colors.grey.shade600,
        size: 20,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Text('ویرایش'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('حذف'),
        ),
        const PopupMenuItem(
          value: 'block',
          child: Text('مسدود کردن'),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Text('گزارش کردن'),
        ),
      ],
    );
  }

  Widget _buildPingDisplay(
      int? ping1, int? ping2, bool isDark, bool isBlocked) {
    return Row(
      children: [
        if (ping1 != null) ...[
          _buildPingChip(ping1, '1', isDark, isBlocked),
          const SizedBox(width: 8),
        ],
        if (ping2 != null) ...[
          _buildPingChip(ping2, '2', isDark, isBlocked),
        ],
      ],
    );
  }

  Widget _buildPingChip(int ping, String label, bool isDark, bool isBlocked) {
    final pingStatus = DnsStatus(ping, ping > 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pingStatus.backgroundColor.withOpacity(isBlocked ? 0.5 : 1.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$ping ms',
        style: TextStyle(
          fontSize: 12,
          color: pingStatus.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context, bool isDark) {
    return ElevatedButton(
      onPressed: isLoading ? null : () => onConnect(record),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brightBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('اتصال'),
    );
  }

  Color _getCardColor(bool isDark, bool isSelected, bool isBlocked) {
    if (isSelected) {
      return AppColors.brightBlue.withOpacity(0.1);
    }
    if (isBlocked) {
      return (isDark ? AppColors.darkCardBackground : Colors.white)
          .withOpacity(0.7);
    }
    return isDark ? AppColors.darkCardBackground : Colors.white;
  }

  Color _getBorderColor(bool isDark, bool isSelected, bool isBlocked) {
    if (isSelected) {
      return AppColors.brightBlue;
    }
    if (isBlocked) {
      return Colors.orange.withOpacity(0.5);
    }
    return isDark ? Colors.white12 : Colors.grey.shade200;
  }

  Color _getTextColor(bool isDark, bool isBlocked) {
    if (isBlocked) {
      return (isDark ? Colors.white : Colors.black87).withOpacity(0.7);
    }
    return isDark ? Colors.white : Colors.black87;
  }

  Color _getSecondaryTextColor(bool isDark, bool isBlocked) {
    if (isBlocked) {
      return (isDark ? Colors.white70 : Colors.grey.shade600).withOpacity(0.7);
    }
    return isDark ? Colors.white70 : Colors.grey.shade600;
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onEdit(record);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
      case 'block':
        _showBlockDialog(context);
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف DNS'),
        content:
            Text('آیا مطمئن هستید که می‌خواهید "${record.label}" را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete(record);
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسدود کردن DNS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'آیا مطمئن هستید که می‌خواهید "${record.label}" را مسدود کنید؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'دلیل مسدودسازی (اختیاری)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              dnsManagementService
                  .blockDns(
                record.id,
                record.label,
                record.ip1,
                record.ip2,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              )
                  .then((result) {
                SnackbarUtils.showSuccessSnackBar(
                  context,
                  result.message,
                  lastSnackBarTime: lastSnackBarTime,
                  lastSnackBarMessage: lastSnackBarMessage,
                  setLastSnackBarTime: setLastSnackBarTime,
                  setLastSnackBarMessage: setLastSnackBarMessage,
                  isDarkModeActive: () =>
                      ThemeController().isDarkModeActive(context),
                );
              });
            },
            child: const Text(
              'مسدود کردن',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گزارش کردن DNS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'آیا مطمئن هستید که می‌خواهید "${record.label}" را گزارش کنید؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'دلیل گزارش (اختیاری)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              dnsManagementService
                  .reportDns(
                record.id,
                record.label,
                record.ip1,
                record.ip2,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              )
                  .then((result) {
                SnackbarUtils.showSuccessSnackBar(
                  context,
                  result.message,
                  lastSnackBarTime: lastSnackBarTime,
                  lastSnackBarMessage: lastSnackBarMessage,
                  setLastSnackBarTime: setLastSnackBarTime,
                  setLastSnackBarMessage: setLastSnackBarMessage,
                  isDarkModeActive: () =>
                      ThemeController().isDarkModeActive(context),
                );
              });
            },
            child: const Text(
              'گزارش کردن',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
