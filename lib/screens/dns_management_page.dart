import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/models/dns_management.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// صفحه مدیریت DNS برای مشاهده و مدیریت DNSهای مسدود شده، حذف شده و گزارش شده
class DnsManagementPage extends StatefulWidget {
  const DnsManagementPage({super.key});

  @override
  State<DnsManagementPage> createState() => _DnsManagementPageState();
}

class _DnsManagementPageState extends State<DnsManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ThemeController themeController;
  late DnsManagementService _dnsManagementService;

  // Snackbar management state
  DateTime? _lastSnackBarTime;
  String? _lastSnackBarMessage;

  @override
  void initState() {
    super.initState();
    themeController = Get.find<ThemeController>();
    _dnsManagementService = DnsManagementService();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _dnsManagementService.loadData();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkModeActive(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مدیریت DNS',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brightBlue,
          labelColor: AppColors.brightBlue,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.grey.shade600,
          tabs: const [
            Tab(text: 'مسدود شده'),
            Tab(text: 'حذف شده'),
            Tab(text: 'گزارش شده'),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              final stats = _dnsManagementService.stats;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'clear_all':
                      _showClearAllDialog();
                      break;
                    case 'stats':
                      _showStatsDialog(stats);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'stats',
                    child: Text('آمار'),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Text('پاک کردن همه'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildManagementList(
                _dnsManagementService
                    .getRecordsByStatus(DnsManagementStatus.blocked),
                DnsManagementStatus.blocked,
                isDark,
              ),
              _buildManagementList(
                _dnsManagementService
                    .getRecordsByStatus(DnsManagementStatus.deleted),
                DnsManagementStatus.deleted,
                isDark,
              ),
              _buildManagementList(
                _dnsManagementService
                    .getRecordsByStatus(DnsManagementStatus.reported),
                DnsManagementStatus.reported,
                isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildManagementList(
    List<DnsManagementRecord> records,
    DnsManagementStatus status,
    bool isDark,
  ) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 64,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(status),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildManagementCard(record, status, isDark);
      },
    );
  }

  Widget _buildManagementCard(
    DnsManagementRecord record,
    DnsManagementStatus status,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.dnsLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, record),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('بازگردانی'),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('کپی کردن'),
                    ),
                    if (status != DnsManagementStatus.reported)
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('گزارش کردن'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'IP: ${record.dnsIp1}${record.dnsIp2 != null ? ', ${record.dnsIp2}' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            if (record.reason != null && record.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'دلیل: ${record.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'تاریخ: ${_formatDateTime(record.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(DnsManagementStatus status) {
    switch (status) {
      case DnsManagementStatus.blocked:
        return Icons.block;
      case DnsManagementStatus.deleted:
        return Icons.delete;
      case DnsManagementStatus.reported:
        return Icons.report;
      case DnsManagementStatus.active:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(DnsManagementStatus status) {
    switch (status) {
      case DnsManagementStatus.blocked:
        return Colors.orange;
      case DnsManagementStatus.deleted:
        return Colors.red;
      case DnsManagementStatus.reported:
        return Colors.red.shade700;
      case DnsManagementStatus.active:
        return Colors.green;
    }
  }

  String _getEmptyMessage(DnsManagementStatus status) {
    switch (status) {
      case DnsManagementStatus.blocked:
        return 'هیچ DNS مسدود شده‌ای وجود ندارد';
      case DnsManagementStatus.deleted:
        return 'هیچ DNS حذف شده‌ای وجود ندارد';
      case DnsManagementStatus.reported:
        return 'هیچ DNS گزارش شده‌ای وجود ندارد';
      case DnsManagementStatus.active:
        return 'تمام DNSها فعال هستند';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقیقه پیش';
    } else {
      return 'همین الان';
    }
  }

  void _handleMenuAction(String action, DnsManagementRecord record) {
    final dnsManagement = context.read<DnsManagementService>();

    switch (action) {
      case 'restore':
        _dnsManagementService.restoreDns(record.dnsId).then((result) {
          SnackbarUtils.showSuccessSnackBar(
            context,
            result.message,
            lastSnackBarTime: _lastSnackBarTime,
            lastSnackBarMessage: _lastSnackBarMessage,
            setLastSnackBarTime: (time) =>
                setState(() => _lastSnackBarTime = time),
            setLastSnackBarMessage: (message) =>
                setState(() => _lastSnackBarMessage = message),
            isDarkModeActive: () => themeController.isDarkModeActive(context),
          );
        });
        break;
      case 'copy':
        _copyDnsInfo(record);
        break;
      case 'report':
        if (record.status != DnsManagementStatus.reported) {
          dnsManagement
              .reportDns(
            record.dnsId,
            record.dnsLabel,
            record.dnsIp1,
            record.dnsIp2,
          )
              .then((result) {
            SnackbarUtils.showSuccessSnackBar(
              context,
              result.message,
              lastSnackBarTime: _lastSnackBarTime,
              lastSnackBarMessage: _lastSnackBarMessage,
              setLastSnackBarTime: (time) =>
                  setState(() => _lastSnackBarTime = time),
              setLastSnackBarMessage: (message) =>
                  setState(() => _lastSnackBarMessage = message),
              isDarkModeActive: () => themeController.isDarkModeActive(context),
            );
          });
        }
        break;
    }
  }

  void _copyDnsInfo(DnsManagementRecord record) {
    final dnsInfo =
        '${record.dnsLabel}\nIP1: ${record.dnsIp1}${record.dnsIp2 != null ? '\nIP2: ${record.dnsIp2}' : ''}';
    // TODO: Implement clipboard functionality with dnsInfo
    Clipboard.setData(ClipboardData(text: dnsInfo));
    SnackbarUtils.showSuccessSnackBar(
      context,
      'اطلاعات DNS کپی شد',
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => setState(() => _lastSnackBarTime = time),
      setLastSnackBarMessage: (message) =>
          setState(() => _lastSnackBarMessage = message),
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک کردن همه داده‌ها'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید تمام داده‌های مدیریت DNS را پاک کنید؟\nاین عملیات قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dnsManagementService.clearAllData().then((result) {
                SnackbarUtils.showSuccessSnackBar(
                  context,
                  result.message,
                  lastSnackBarTime: _lastSnackBarTime,
                  lastSnackBarMessage: _lastSnackBarMessage,
                  setLastSnackBarTime: (time) =>
                      setState(() => _lastSnackBarTime = time),
                  setLastSnackBarMessage: (message) =>
                      setState(() => _lastSnackBarMessage = message),
                  isDarkModeActive: () =>
                      themeController.isDarkModeActive(context),
                );
              });
            },
            child: const Text(
              'پاک کردن',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(DnsManagementStats stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('آمار مدیریت DNS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مسدود شده: ${stats.totalBlocked}'),
            Text('حذف شده: ${stats.totalDeleted}'),
            Text('گزارش شده: ${stats.totalReported}'),
            const Divider(),
            Text(
              'مجموع: ${stats.total}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}
