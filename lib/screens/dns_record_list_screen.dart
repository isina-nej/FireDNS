import 'package:flutter/material.dart';
import '../api/models/dns_record.dart';
import '../api/models/api_response.dart';
import '../api/services/dns_api_service.dart';
import '../widgets/dns_record_card.dart';
import '../widgets/dns_type_filter.dart';
import 'dns_record_form_screen.dart';

/// صفحه لیست رکوردهای DNS
class DnsRecordListScreen extends StatefulWidget {
  const DnsRecordListScreen({Key? key}) : super(key: key);

  @override
  State<DnsRecordListScreen> createState() => _DnsRecordListScreenState();
}

class _DnsRecordListScreenState extends State<DnsRecordListScreen> {
  final DnsApiService _dnsApiService = DnsApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DnsRecord> _dnsRecords = [];
  List<DnsRecord> _filteredRecords = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  DnsType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadDnsRecords();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _dnsApiService.dispose();
    super.dispose();
  }

  /// بارگذاری رکوردهای DNS
  Future<void> _loadDnsRecords() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      ApiResponse<List<DnsRecord>> response;

      if (_selectedType != null) {
        response = await _dnsApiService.getDnsRecordsByType(_selectedType!);
      } else {
        response = await _dnsApiService.getAllDnsRecords();
      }

      if (response.status && response.data != null) {
        setState(() {
          _dnsRecords = response.data!;
          _filteredRecords = List.from(_dnsRecords);
          _isLoading = false;
        });
        _filterRecords();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response.message ?? 'خطا در بارگذاری داده‌ها';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'خطا در اتصال به سرور';
        _isLoading = false;
      });
    }
  }

  /// فیلتر کردن رکوردها
  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecords = _dnsRecords.where((record) {
        final matchesSearch =
            query.isEmpty ||
            record.label.toLowerCase().contains(query) ||
            record.ip1.contains(query) ||
            record.ip2.contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  /// فیلتر بر اساس نوع DNS
  void _filterByType(DnsType? type) {
    setState(() {
      _selectedType = type;
    });
    _loadDnsRecords();
  }

  /// حذف رکورد DNS
  Future<void> _deleteDnsRecord(DnsRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف رکورد DNS'),
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
    );

    if (confirmed == true) {
      final response = await _dnsApiService.deleteDnsRecord(record.id);

      if (response.status) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رکورد با موفقیت حذف شد')));
        _loadDnsRecords();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف: ${response.message}')),
        );
      }
    }
  }

  /// ویرایش رکورد DNS
  Future<void> _editDnsRecord(DnsRecord record) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DnsRecordFormScreen(record: record),
      ),
    );

    if (result == true) {
      _loadDnsRecords();
    }
  }

  /// ایجاد رکورد جدید
  Future<void> _createDnsRecord() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const DnsRecordFormScreen()),
    );

    if (result == true) {
      _loadDnsRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت DNS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDnsRecords,
          ),
        ],
      ),
      body: Column(
        children: [
          // قسمت جستجو و فیلتر
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // جستجو
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'جستجو در رکوردها',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // فیلتر نوع DNS
                DnsTypeFilter(
                  selectedType: _selectedType,
                  onTypeChanged: _filterByType,
                ),
              ],
            ),
          ),
          const Divider(),
          // لیست رکوردها
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDnsRecord,
        tooltip: 'افزودن رکورد جدید',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// ساخت بدنه اصلی صفحه
  Widget _buildBody() {
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
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDnsRecords,
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
            Text(
              'هیچ رکوردی یافت نشد',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDnsRecords,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRecords.length,
        itemBuilder: (context, index) {
          final record = _filteredRecords[index];
          return DnsRecordCard(
            record: record,
            onEdit: () => _editDnsRecord(record),
            onDelete: () => _deleteDnsRecord(record),
          );
        },
      ),
    );
  }
}
