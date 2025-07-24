import 'package:flutter/material.dart';
import '../path/path.dart';


/// صفحه نمایش نحوه استفاده از API
class DnsApiDemoScreen extends StatefulWidget {
  const DnsApiDemoScreen({Key? key}) : super(key: key);

  @override
  State<DnsApiDemoScreen> createState() => _DnsApiDemoScreenState();
}

class _DnsApiDemoScreenState extends State<DnsApiDemoScreen> {
  final DnsApiService _dnsApiService = DnsApiService();
  final TextEditingController _outputController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _outputController.dispose();
    _dnsApiService.dispose();
    super.dispose();
  }

  void _addOutput(String text) {
    setState(() {
      _outputController.text += '$text\n';
    });
  }

  void _clearOutput() {
    setState(() {
      _outputController.clear();
    });
  }

  /// مثال GET - دریافت همه رکوردها
  Future<void> _getAllRecordsExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== GET /api/dns - دریافت همه رکوردها ===');

    try {
      final response = await _dnsApiService.getAllDnsRecords();

      if (response.status) {
        _addOutput('✅ موفق: ${response.data?.length ?? 0} رکورد دریافت شد');
        response.data?.take(3).forEach((record) {
          _addOutput('- ${record.label}: ${record.ip1}, ${record.ip2}');
        });
      } else {
        _addOutput('❌ خطا: ${response.message}');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  /// مثال GET با فیلتر - دریافت رکوردهای نوع خاص
  Future<void> _getRecordsByTypeExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== GET /api/dns?type=SHEKAN - فیلتر بر اساس نوع ===');

    try {
      final response = await _dnsApiService.getDnsRecordsByType(DnsType.shekan);

      if (response.status) {
        _addOutput('✅ موفق: ${response.data?.length ?? 0} رکورد نوع SHEKAN');
        response.data?.forEach((record) {
          _addOutput('- ${record.label}: ${record.ip1}, ${record.ip2}');
        });
      } else {
        _addOutput('❌ خطا: ${response.message}');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  /// مثال POST - ایجاد رکورد جدید
  Future<void> _createRecordExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== POST /api/dns - ایجاد رکورد جدید ===');

    try {
      final request = DnsRecordRequest(
        label: 'تست DNS - ${DateTime.now().millisecondsSinceEpoch}',
        ip1: '8.8.8.8',
        ip2: '8.8.4.4',
        type: DnsType.google,
      );

      final response = await _dnsApiService.createDnsRecord(request);

      if (response.status) {
        _addOutput('✅ موفق: رکورد با ID ${response.data?.id} ایجاد شد');
        _addOutput('- نام: ${response.data?.label}');
        _addOutput('- نوع: ${response.data?.type.displayName}');
      } else {
        _addOutput('❌ خطا: ${response.message}');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  /// مثال PATCH - ویرایش رکورد
  Future<void> _updateRecordExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== PATCH /api/dns/:id - ویرایش رکورد ===');

    try {
      // ابتدا یک رکورد دریافت کنیم
      final getAllResponse = await _dnsApiService.getAllDnsRecords();

      if (getAllResponse.status &&
          getAllResponse.data != null &&
          getAllResponse.data!.isNotEmpty) {
        final recordToUpdate = getAllResponse.data!.first;

        final request = DnsRecordRequest(
          label: '${recordToUpdate.label} - ویرایش شده',
          ip1: recordToUpdate.ip1,
          ip2: recordToUpdate.ip2,
          type: recordToUpdate.type,
        );

        final response = await _dnsApiService.updateDnsRecord(
          recordToUpdate.id,
          request,
        );

        if (response.status) {
          _addOutput('✅ موفق: رکورد ${recordToUpdate.id} ویرایش شد');
          _addOutput('- نام جدید: ${response.data?.label}');
        } else {
          _addOutput('❌ خطا: ${response.message}');
        }
      } else {
        _addOutput('❌ رکوردی برای ویرایش یافت نشد');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  /// مثال DELETE - حذف رکورد
  Future<void> _deleteRecordExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== DELETE /api/dns/:id - حذف رکورد ===');

    try {
      // ابتدا یک رکورد دریافت کنیم
      final getAllResponse = await _dnsApiService.getAllDnsRecords();

      if (getAllResponse.status &&
          getAllResponse.data != null &&
          getAllResponse.data!.isNotEmpty) {
        final recordToDelete = getAllResponse.data!.last;

        final response = await _dnsApiService.deleteDnsRecord(
          recordToDelete.id,
        );

        if (response.status) {
          _addOutput('✅ موفق: رکورد ${recordToDelete.id} حذف شد');
          _addOutput('- نام حذف شده: ${recordToDelete.label}');
        } else {
          _addOutput('❌ خطا: ${response.message}');
        }
      } else {
        _addOutput('❌ رکوردی برای حذف یافت نشد');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  /// مثال فیلتر پیشرفته
  Future<void> _filterRecordsExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== فیلتر پیشرفته - چندین معیار ===');

    try {
      final response = await _dnsApiService.filterDnsRecords(
        type: DnsType.shekan,
        label: 'شکن',
      );

      if (response.status) {
        _addOutput('✅ موفق: ${response.data?.length ?? 0} رکورد یافت شد');
        response.data?.forEach((record) {
          _addOutput('- ${record.label}: ${record.type.displayName}');
        });
      } else {
        _addOutput('❌ خطا: ${response.message}');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  /// مثال بررسی دسترسی DNS
  Future<void> _checkDnsAccessExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== بررسی دسترسی DNS ===');

    try {
      final response = await _dnsApiService.checkDnsAccess(
        '8.8.8.8',
        '8.8.4.4',
      );

      if (response.status) {
        _addOutput(
          '✅ موفق: دسترسی ${response.data == true ? 'موجود' : 'غیرموجود'}',
        );
      } else {
        _addOutput('❌ خطا: ${response.message}');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  /// مثال دریافت آمار
  Future<void> _getStatsExample() async {
    setState(() => _isLoading = true);
    _addOutput('=== دریافت آمار DNS ===');

    try {
      final response = await _dnsApiService.getDnsStats();

      if (response.status) {
        _addOutput('✅ موفق: آمار دریافت شد');
        response.data?.forEach((key, value) {
          _addOutput('- $key: $value');
        });
      } else {
        _addOutput('❌ خطا: ${response.message}');
      }
    } catch (e) {
      _addOutput('❌ خطا: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال‌های API'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearOutput,
            tooltip: 'پاک کردن خروجی',
          ),
        ],
      ),
      body: Column(
        children: [
          // دکمه‌های مثال
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'مثال‌های استفاده از DNS Manager API',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // GET Examples
                  _buildExampleButton(
                    'GET همه رکوردها',
                    _getAllRecordsExample,
                    Icons.download,
                    Colors.blue,
                  ),
                  _buildExampleButton(
                    'GET با فیلتر (نوع)',
                    _getRecordsByTypeExample,
                    Icons.filter_list,
                    Colors.indigo,
                  ),

                  // POST Example
                  _buildExampleButton(
                    'POST ایجاد رکورد',
                    _createRecordExample,
                    Icons.add,
                    Colors.green,
                  ),

                  // PATCH Example
                  _buildExampleButton(
                    'PATCH ویرایش رکورد',
                    _updateRecordExample,
                    Icons.edit,
                    Colors.orange,
                  ),

                  // DELETE Example
                  _buildExampleButton(
                    'DELETE حذف رکورد',
                    _deleteRecordExample,
                    Icons.delete,
                    Colors.red,
                  ),

                  // Advanced Examples
                  _buildExampleButton(
                    'فیلتر پیشرفته',
                    _filterRecordsExample,
                    Icons.search,
                    Colors.purple,
                  ),
                  _buildExampleButton(
                    'بررسی دسترسی',
                    _checkDnsAccessExample,
                    Icons.network_check,
                    Colors.teal,
                  ),
                  _buildExampleButton(
                    'دریافت آمار',
                    _getStatsExample,
                    Icons.bar_chart,
                    Colors.brown,
                  ),
                ],
              ),
            ),
          ),

          // خروجی
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'خروجی API:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _outputController,
                      maxLines: null,
                      expands: true,
                      readOnly: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'خروجی API اینجا نمایش داده می‌شود...',
                      ),
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

  Widget _buildExampleButton(
    String title,
    VoidCallback onPressed,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
