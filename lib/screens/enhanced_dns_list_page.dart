import 'dart:convert';

import 'package:firedns/controllers/theme_controller.dart';
import 'package:firedns/models/dns_management.dart';
import 'package:firedns/path/path.dart';
import 'package:firedns/screens/dns_management_page.dart';
import 'package:firedns/widgets/enhanced_dns_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedDnsListPage extends StatefulWidget {
  const EnhancedDnsListPage({super.key});

  @override
  State<EnhancedDnsListPage> createState() => _EnhancedDnsListPageState();
}

class _EnhancedDnsListPageState extends State<EnhancedDnsListPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late ThemeController themeController;
  late DnsSelectionService _selectionService;
  late DnsManagementService _managementService;

  Set<String> _userDnsIds = {};
  Map<String, int> _pingCache = {};
  final bool _isLoading = false;

  // Snackbar management state
  DateTime? _lastSnackBarTime;
  String? _lastSnackBarMessage;

  @override
  void initState() {
    super.initState();
    themeController = Get.find<ThemeController>();
    _selectionService = DnsSelectionService();
    _managementService = DnsManagementService();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _loadData();
    _managementService.loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _selectionService.dispose();
    _managementService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserDnsIds(),
      _loadPingCache(),
    ]);
    setState(() {});
  }

  Future<void> _loadUserDnsIds() async {
    final prefs = await SharedPreferences.getInstance();
    final userDnsJson = prefs.getString('user_dns_list');
    final ids = <String>{};
    if (userDnsJson != null) {
      try {
        final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
        for (var e in userList) {
          ids.add(e['id']);
        }
      } catch (_) {}
    }
    _userDnsIds = ids;
  }

  Future<void> _loadPingCache() async {
    final prefs = await SharedPreferences.getInstance();
    final pingCacheJson = prefs.getString('dns_ping_cache');
    if (pingCacheJson != null) {
      try {
        final Map<String, dynamic> cache = jsonDecode(pingCacheJson);
        _pingCache = cache.map((key, value) => MapEntry(key, value as int));
      } catch (_) {}
    }
  }

  bool _isUserDns(DnsRecord record) => _userDnsIds.contains(record.id);

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkModeActive(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _selectionService),
        ChangeNotifierProvider.value(value: _managementService),
      ],
      child: Consumer2<DnsSelectionService, DnsManagementService>(
        builder: (context, selectionService, dnsManagement, child) {
          return Scaffold(
            appBar: _buildAppBar(isDark, selectionService, dnsManagement),
            body: _buildBody(selectionService, dnsManagement, isDark),
            floatingActionButton: _buildFloatingActionButton(selectionService),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    bool isDark,
    DnsSelectionService selectionService,
    DnsManagementService dnsManagement,
  ) {
    if (selectionService.isSelectionMode) {
      return AppBar(
        backgroundColor: AppColors.brightBlue,
        title: Text(
          '${selectionService.selectedCount} انتخاب شده',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => selectionService.exitSelectionMode(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all, color: Colors.white),
            onPressed: () => _selectAll(selectionService),
          ),
          IconButton(
            icon: const Icon(Icons.deselect, color: Colors.white),
            onPressed: () => selectionService.deselectAll(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) =>
                _handleBulkAction(value, selectionService, dnsManagement),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Text('کپی کردن'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('حذف کردن'),
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
          ),
        ],
      );
    }

    return AppBar(
      title: Text(
        'لیست DNS',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.settings,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
          onPressed: () => _navigateToSettings(),
        ),
        IconButton(
          icon: Icon(
            Icons.manage_accounts,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
          onPressed: () => _navigateToDnsManagement(),
        ),
      ],
    );
  }

  Widget _buildBody(
    DnsSelectionService selectionService,
    DnsManagementService dnsManagement,
    bool isDark,
  ) {
    return FutureBuilder<List<DnsRecord>>(
      future: _getFilteredDnsRecords(dnsManagement),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطا در بارگذاری داده‌ها: ${snapshot.error}'),
          );
        }

        final dnsRecords = snapshot.data ?? [];

        if (dnsRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dns,
                  size: 64,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'هیچ DNS یافت نشد',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: dnsRecords.length,
          itemBuilder: (context, index) {
            final record = dnsRecords[index];
            return EnhancedDnsCard(
              record: record,
              index: index,
              pingCache: _pingCache,
              isUserDns: _isUserDns(record),
              onConnect: (record) => _connectToDns(record),
              onRePing: (record) => _rePingDns(record),
              onToggleLike: (dnsId) => _toggleLike(dnsId),
              onEdit: (record) => _editDns(record),
              onDelete: (record) => _deleteDns(record),
              isLoading: _isLoading,
              likedDnsIds: const [], // TODO: Implement liked DNS
              selectionService: selectionService,
              dnsManagementService: dnsManagement,
              lastSnackBarTime: _lastSnackBarTime,
              lastSnackBarMessage: _lastSnackBarMessage,
              setLastSnackBarTime: (time) =>
                  setState(() => _lastSnackBarTime = time),
              setLastSnackBarMessage: (message) =>
                  setState(() => _lastSnackBarMessage = message),
            );
          },
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(DnsSelectionService selectionService) {
    if (selectionService.isSelectionMode) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () => _addNewDns(),
      backgroundColor: AppColors.brightBlue,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Future<List<DnsRecord>> _getFilteredDnsRecords(
      DnsManagementService dnsManagement) async {
    // Get all DNS records (from cache and user DNS)
    final allRecords = await _getAllDnsRecords();

    // Filter out reported DNS (they should not be shown at all)
    // Blocked DNS are shown but with different styling
    return allRecords.where((record) {
      final status = dnsManagement.getDnsStatus(record.id);
      return status != DnsManagementStatus.reported;
    }).toList();
  }

  Future<List<DnsRecord>> _getAllDnsRecords() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to load from cache first
    final cachedJson = prefs.getString('cached_dns_list');
    List<DnsRecord> cachedRecords = [];
    if (cachedJson != null) {
      try {
        final List<dynamic> jsonList = List.from(jsonDecode(cachedJson));
        cachedRecords = jsonList.map((e) => DnsRecord.fromJson(e)).toList();
      } catch (_) {}
    }

    // Load user DNS records
    final userDnsJson = prefs.getString('user_dns_list');
    List<DnsRecord> userDnsRecords = [];
    if (userDnsJson != null) {
      try {
        final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
        userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
      } catch (_) {}
    }

    // Combine both lists
    List<DnsRecord> allRecords = [...cachedRecords, ...userDnsRecords];

    // Remove duplicates
    final seen = <String>{};
    allRecords = allRecords.where((r) {
      final key = '${r.ip1}_${r.ip2 ?? ''}'.replaceAll(' ', '').toLowerCase();
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    return allRecords;
  }

  void _selectAll(DnsSelectionService selectionService) {
    _getFilteredDnsRecords(context.read<DnsManagementService>())
        .then((records) {
      selectionService.selectAll(records);
    });
  }

  void _handleBulkAction(
    String action,
    DnsSelectionService selectionService,
    DnsManagementService dnsManagement,
  ) {
    final selectedRecords = selectionService.getSelectedRecords([]);

    switch (action) {
      case 'copy':
        _copySelectedDns(selectedRecords);
        break;
      case 'delete':
        _bulkDeleteDns(selectedRecords, dnsManagement);
        break;
      case 'block':
        _bulkBlockDns(selectedRecords, dnsManagement);
        break;
      case 'report':
        _bulkReportDns(selectedRecords, dnsManagement);
        break;
    }

    selectionService.exitSelectionMode();
  }

  void _copySelectedDns(List<DnsRecord> records) async {
    final dnsInfo = records.map((r) => '${r.label}: ${r.ip1}').join('\n');
    await Clipboard.setData(ClipboardData(text: dnsInfo));
    SnackbarUtils.showSuccessSnackBar(
      context,
      '${records.length} DNS کپی شد',
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => setState(() => _lastSnackBarTime = time),
      setLastSnackBarMessage: (message) =>
          setState(() => _lastSnackBarMessage = message),
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _bulkDeleteDns(
      List<DnsRecord> records, DnsManagementService dnsManagement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف DNSها'),
        content: Text(
            'آیا مطمئن هستید که می‌خواهید ${records.length} DNS را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              for (final record in records) {
                dnsManagement.deleteDns(
                  record.id,
                  record.label,
                  record.ip1,
                  record.ip2,
                );
              }
              SnackbarUtils.showSuccessSnackBar(
                context,
                '${records.length} DNS حذف شد',
                lastSnackBarTime: _lastSnackBarTime,
                lastSnackBarMessage: _lastSnackBarMessage,
                setLastSnackBarTime: (time) =>
                    setState(() => _lastSnackBarTime = time),
                setLastSnackBarMessage: (message) =>
                    setState(() => _lastSnackBarMessage = message),
                isDarkModeActive: () =>
                    themeController.isDarkModeActive(context),
              );
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

  void _bulkBlockDns(
      List<DnsRecord> records, DnsManagementService dnsManagement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسدود کردن DNSها'),
        content: Text(
            'آیا مطمئن هستید که می‌خواهید ${records.length} DNS را مسدود کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              for (final record in records) {
                dnsManagement.blockDns(
                  record.id,
                  record.label,
                  record.ip1,
                  record.ip2,
                );
              }
              SnackbarUtils.showSuccessSnackBar(
                context,
                '${records.length} DNS مسدود شد',
                lastSnackBarTime: _lastSnackBarTime,
                lastSnackBarMessage: _lastSnackBarMessage,
                setLastSnackBarTime: (time) =>
                    setState(() => _lastSnackBarTime = time),
                setLastSnackBarMessage: (message) =>
                    setState(() => _lastSnackBarMessage = message),
                isDarkModeActive: () =>
                    themeController.isDarkModeActive(context),
              );
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

  void _bulkReportDns(
      List<DnsRecord> records, DnsManagementService dnsManagement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گزارش کردن DNSها'),
        content: Text(
            'آیا مطمئن هستید که می‌خواهید ${records.length} DNS را گزارش کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              for (final record in records) {
                dnsManagement.reportDns(
                  record.id,
                  record.label,
                  record.ip1,
                  record.ip2,
                );
              }
              SnackbarUtils.showSuccessSnackBar(
                context,
                '${records.length} DNS گزارش شد',
                lastSnackBarTime: _lastSnackBarTime,
                lastSnackBarMessage: _lastSnackBarMessage,
                setLastSnackBarTime: (time) =>
                    setState(() => _lastSnackBarTime = time),
                setLastSnackBarMessage: (message) =>
                    setState(() => _lastSnackBarMessage = message),
                isDarkModeActive: () =>
                    themeController.isDarkModeActive(context),
              );
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

  void _connectToDns(DnsRecord record) {
    // TODO: Implement DNS connection
    SnackbarUtils.showSuccessSnackBar(
      context,
      'اتصال به ${record.label}',
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => setState(() => _lastSnackBarTime = time),
      setLastSnackBarMessage: (message) =>
          setState(() => _lastSnackBarMessage = message),
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _rePingDns(DnsRecord record) {
    // TODO: Implement re-ping functionality
    SnackbarUtils.showSuccessSnackBar(
      context,
      'در حال تست مجدد ${record.label}',
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => setState(() => _lastSnackBarTime = time),
      setLastSnackBarMessage: (message) =>
          setState(() => _lastSnackBarMessage = message),
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _toggleLike(String dnsId) {
    // TODO: Implement like functionality
    SnackbarUtils.showSuccessSnackBar(
      context,
      'پسندیده شد',
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => setState(() => _lastSnackBarTime = time),
      setLastSnackBarMessage: (message) =>
          setState(() => _lastSnackBarMessage = message),
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _editDns(DnsRecord record) {
    // TODO: Implement edit functionality
    SnackbarUtils.showSuccessSnackBar(
      context,
      'ویرایش ${record.label}',
      lastSnackBarTime: null,
      lastSnackBarMessage: null,
      setLastSnackBarTime: (time) {},
      setLastSnackBarMessage: (message) {},
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _deleteDns(DnsRecord record) {
    // TODO: Implement delete functionality
    SnackbarUtils.showSuccessSnackBar(
      context,
      'حذف ${record.label}',
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => setState(() => _lastSnackBarTime = time),
      setLastSnackBarMessage: (message) =>
          setState(() => _lastSnackBarMessage = message),
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _addNewDns() {
    // TODO: Implement add new DNS functionality
    SnackbarUtils.showSuccessSnackBar(
      context,
      'افزودن DNS جدید',
      lastSnackBarTime: _lastSnackBarTime,
      lastSnackBarMessage: _lastSnackBarMessage,
      setLastSnackBarTime: (time) => setState(() => _lastSnackBarTime = time),
      setLastSnackBarMessage: (message) =>
          setState(() => _lastSnackBarMessage = message),
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _navigateToSettings() {
    // TODO: Navigate to settings page
    SnackbarUtils.showSuccessSnackBar(
      context,
      'تنظیمات',
      lastSnackBarTime: null,
      lastSnackBarMessage: null,
      setLastSnackBarTime: (time) {},
      setLastSnackBarMessage: (message) {},
      isDarkModeActive: () => themeController.isDarkModeActive(context),
    );
  }

  void _navigateToDnsManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DnsManagementPage(),
      ),
    );
  }
}
