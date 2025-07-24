import 'package:flutter/material.dart';
import '../path/path.dart';


/// صفحه فرم ایجاد/ویرایش رکورد DNS
class DnsRecordFormScreen extends StatefulWidget {
  final DnsRecord? record;

  const DnsRecordFormScreen({Key? key, this.record}) : super(key: key);

  @override
  State<DnsRecordFormScreen> createState() => _DnsRecordFormScreenState();
}

class _DnsRecordFormScreenState extends State<DnsRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _ip1Controller = TextEditingController();
  final _ip2Controller = TextEditingController();
  final DnsApiService _dnsApiService = DnsApiService();

  DnsType _selectedType = DnsType.general;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.record != null;

    if (_isEditMode) {
      _labelController.text = widget.record!.label;
      _ip1Controller.text = widget.record!.ip1;
      _ip2Controller.text = widget.record!.ip2;
      _selectedType = widget.record!.type;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _ip1Controller.dispose();
    _ip2Controller.dispose();
    _dnsApiService.dispose();
    super.dispose();
  }

  /// ذخیره رکورد DNS
  Future<void> _saveDnsRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = DnsRecordRequest(
        label: _labelController.text.trim(),
        ip1: _ip1Controller.text.trim(),
        ip2: _ip2Controller.text.trim(),
        type: _selectedType,
      );

      ApiResponse<DnsRecord> response;

      if (_isEditMode) {
        response = await _dnsApiService.updateDnsRecord(
          widget.record!.id,
          request,
        );
      } else {
        response = await _dnsApiService.createDnsRecord(request);
      }

      if (response.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'رکورد با موفقیت ویرایش شد'
                  : 'رکورد با موفقیت ایجاد شد',
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ذخیره: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// نمایش انتخابگر نوع DNS
  Future<void> _showTypeSelector() async {
    final selectedType = await showDialog<DnsType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب نوع DNS'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: DnsType.values
                .map(
                  (type) => ListTile(
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(type.colorValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(type.displayName),
                    selected: _selectedType == type,
                    onTap: () => Navigator.pop(context, type),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    if (selectedType != null) {
      setState(() {
        _selectedType = selectedType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'ویرایش رکورد DNS' : 'ایجاد رکورد DNS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveDnsRecord),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // نام رکورد
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'نام رکورد',
                  hintText: 'مثال: شکن، رادار گیمز، ...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'نام رکورد الزامی است';
                  }
                  if (value.trim().length < 2) {
                    return 'نام رکورد باید حداقل ۲ کاراکتر باشد';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // IP اول
              TextFormField(
                controller: _ip1Controller,
                decoration: const InputDecoration(
                  labelText: 'DNS اول',
                  hintText: 'مثال: 8.8.8.8',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'DNS اول الزامی است';
                  }
                  if (!DnsValidator.isValidIp(value.trim())) {
                    return 'فرمت IP نامعتبر است';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // IP دوم
              TextFormField(
                controller: _ip2Controller,
                decoration: const InputDecoration(
                  labelText: 'DNS دوم',
                  hintText: 'مثال: 8.8.4.4',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'DNS دوم الزامی است';
                  }
                  if (!DnsValidator.isValidIp(value.trim())) {
                    return 'فرمت IP نامعتبر است';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // نوع DNS
              InkWell(
                onTap: _showTypeSelector,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(_selectedType.colorValue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedType.displayName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // دکمه ذخیره
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDnsRecord,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditMode ? 'ویرایش' : 'ایجاد'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
