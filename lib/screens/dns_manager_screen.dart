import 'package:flutter/material.dart';
import '../api/models/dns_record.dart';
// import '../api/models/api_response.dart';
import '../api/services/dns_api_service.dart';
import '../widgets/dns_record_card.dart';
import '../widgets/dns_type_filter.dart';
import 'dns_record_form_screen.dart';

/// صفحه جامع مدیریت DNS با تمام امکانات API
class DnsManagerScreen extends StatefulWidget {
  const DnsManagerScreen({Key? key}) : super(key: key);

  @override
  State<DnsManagerScreen> createState() => _DnsManagerScreenState();
}

class _DnsManagerScreenState extends State<DnsManagerScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final DnsApiService _dnsApiService = DnsApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  List<DnsRecord> _allRecords = [];
  List<DnsRecord> _filteredRecords = [];
  Map<String, int> _statsData = {};
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  DnsType? _selectedType;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadInitialData();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _dnsApiService.dispose();
    super.dispose();
  }

  /// بارگذاری داده‌های اولیه
  Future<void> _loadInitialData() async {
    await Future.wait([_loadAllRecords(), _loadStats()]);
  }

  /// بارگذاری تمام رکوردها
  Future<void> _loadAllRecords() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _dnsApiService.getAllDnsRecords();

      if (response.status && response.data != null) {
        setState(() {
          _allRecords = response.data!;
          _filteredRecords = List.from(_allRecords);
          _isLoading = false;
        });
        _filterRecords();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'خطا در بارگذاری داده‌ها: $e';
        _isLoading = false;
      });
    }
  }

  /// بارگذاری آمار
  Future<void> _loadStats() async {
    try {
      final response = await _dnsApiService.getDnsStats();
      if (response.status && response.data != null) {
        setState(() {
          _statsData = response.data!;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  /// فیلتر کردن رکوردها
  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    List<DnsRecord> filtered = _allRecords;

    // فیلتر بر اساس نوع
    if (_selectedType != null) {
      filtered = filtered
          .where((record) => record.type == _selectedType)
          .toList();
    }

    // فیلتر بر اساس جستجو
    if (query.isNotEmpty) {
      filtered = filtered.where((record) {
        return record.label.toLowerCase().contains(query) ||
            record.ip1.contains(query) ||
            record.ip2.contains(query);
      }).toList();
    }

    setState(() {
      _filteredRecords = filtered;
    });
  }

  /// فیلتر بر اساس نوع
  void _filterByType(DnsType? type) {
    setState(() {
      _selectedType = type;
    });
    _filterRecords();
  }

  /// حذف رکورد
  Future<void> _deleteRecord(DnsRecord record) async {
    final confirmed = await _showDeleteConfirmation(record);
    if (!confirmed) return;

    final response = await _dnsApiService.deleteDnsRecord(record.id);

    if (response.status) {
      _showSuccessSnackBar('رکورد با موفقیت حذف شد');
      _loadAllRecords();
    } else {
      _showErrorSnackBar('خطا در حذف: ${response.message}');
    }
  }

  /// نمایش تأیید حذف
  Future<bool> _showDeleteConfirmation(DnsRecord record) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأیید حذف'),
            content: Text('آیا از حذف رکورد "${record.label}" اطمینان دارید؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لغو'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// ویرایش رکورد
  Future<void> _editRecord(DnsRecord record) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DnsRecordFormScreen(record: record),
      ),
    );

    if (result == true) {
      _loadAllRecords();
    }
  }

  /// ایجاد رکورد جدید
  Future<void> _createNewRecord() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const DnsRecordFormScreen()),
    );

    if (result == true) {
      _loadAllRecords();
    }
  }

  /// نمایش پیام موفقیت
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// نمایش پیام خطا
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// جستجو پیشرفته
  Future<void> _showAdvancedSearch() async {
    await showDialog(
      context: context,
      builder: (context) => _AdvancedSearchDialog(
        onSearch: (filters) async {
          final response = await _dnsApiService.filterDnsRecords(
            type: filters['type'] as DnsType?,
            label: filters['label'] as String?,
            ip: filters['ip'] as String?,
            fromDate: filters['fromDate'] as DateTime?,
            toDate: filters['toDate'] as DateTime?,
          );

          if (response.status && response.data != null) {
            setState(() {
              _filteredRecords = response.data!;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت DNS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'لیست رکوردها', icon: Icon(Icons.list)),
            Tab(text: 'آمار', icon: Icon(Icons.analytics)),
            Tab(text: 'تست DNS', icon: Icon(Icons.speed)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showAdvancedSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRecordsList(), _buildStatsTab(), _buildTestTab()],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: _createNewRecord,
              tooltip: 'افزودن رکورد جدید',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// ساخت لیست رکوردها
  Widget _buildRecordsList() {
    return Column(
      children: [
        // قسمت جستجو و فیلتر
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'جستجو در رکوردها',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DnsTypeFilter(
                selectedType: _selectedType,
                onTypeChanged: _filterByType,
              ),
            ],
          ),
        ),
        const Divider(),

        // لیست رکوردها
        Expanded(child: _buildRecordsBody()),
      ],
    );
  }

  /// ساخت بدنه لیست رکوردها
  Widget _buildRecordsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllRecords,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (_filteredRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('هیچ رکوردی یافت نشد', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllRecords,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRecords.length,
        itemBuilder: (context, index) {
          final record = _filteredRecords[index];
          return DnsRecordCard(
            record: record,
            onEdit: () => _editRecord(record),
            onDelete: () => _deleteRecord(record),
          );
        },
      ),
    );
  }

  /// ساخت تب آمار
  Widget _buildStatsTab() {
    if (_statsData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('در حال بارگذاری آمار...'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'آمار رکوردهای DNS',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _statsData.length,
              itemBuilder: (context, index) {
                final entry = _statsData.entries.elementAt(index);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ساخت تب تست
  Widget _buildTestTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'تست دسترسی DNS',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'در حال توسعه...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// دیالوگ جستجو پیشرفته
class _AdvancedSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSearch;

  const _AdvancedSearchDialog({required this.onSearch});

  @override
  State<_AdvancedSearchDialog> createState() => __AdvancedSearchDialogState();
}

class __AdvancedSearchDialogState extends State<_AdvancedSearchDialog> {
  final _labelController = TextEditingController();
  final _ipController = TextEditingController();
  DnsType? _selectedType;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _labelController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('جستجو پیشرفته'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'نام رکورد',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'آدرس IP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DnsType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع DNS',
                border: OutlineInputBorder(),
              ),
              items: DnsType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            // می‌توانید فیلدهای تاریخ را نیز اضافه کنید
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        TextButton(
          onPressed: () {
            widget.onSearch({
              'type': _selectedType,
              'label': _labelController.text.trim(),
              'ip': _ipController.text.trim(),
              'fromDate': _fromDate,
              'toDate': _toDate,
            });
            Navigator.pop(context);
          },
          child: const Text('جستجو'),
        ),
      ],
    );
  }
}
