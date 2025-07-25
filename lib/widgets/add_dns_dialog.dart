import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../path/path.dart';

class AddDnsDialog extends StatefulWidget {
  final void Function(DnsRecord) onAdd;
  final DnsRecord? initialRecord;
  const AddDnsDialog({Key? key, required this.onAdd, this.initialRecord})
    : super(key: key);

  @override
  State<AddDnsDialog> createState() => _AddDnsDialogState();
}

class _AddDnsDialogState extends State<AddDnsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _ip1Controller;
  late final TextEditingController _ip2Controller;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    final userDnsJson = prefs.getString('user_dns_list');
    List<dynamic> jsonList = [];
    if (userDnsJson != null) {
      try {
        jsonList = List<Map<String, dynamic>>.from(jsonDecode(userDnsJson));
      } catch (_) {}
    }

    // Load all displayed DNS names (from cache and API)
    final cachedJson = prefs.getString('cached_dns_list');
    List<String> allNames = [];
    List<String> allIps = [];
    if (cachedJson != null) {
      try {
        final List<dynamic> cachedList = List.from(jsonDecode(cachedJson));
        allNames.addAll(
          cachedList.map((e) => (e['label'] as String).trim().toLowerCase()),
        );
        allIps.addAll(cachedList.map((e) => (e['ip1'] as String).trim()));
        allIps.addAll(cachedList.map((e) => (e['ip2'] as String).trim()));
      } catch (_) {}
    }
    // Add user DNS names and IPs
    allNames.addAll(
      jsonList.map((e) => (e['label'] as String).trim().toLowerCase()),
    );
    allIps.addAll(jsonList.map((e) => (e['ip1'] as String).trim()));
    allIps.addAll(jsonList.map((e) => (e['ip2'] as String).trim()));

    // If editing, remove the current name and IPs from check
    String currentName = widget.initialRecord?.label.trim().toLowerCase() ?? '';
    String currentIp1 = widget.initialRecord?.ip1.trim() ?? '';
    String currentIp2 = widget.initialRecord?.ip2.trim() ?? '';
    allNames = allNames.where((n) => n != currentName).toList();
    allIps = allIps
        .where((ip) => ip != currentIp1 && ip != currentIp2)
        .toList();

    String newName = _labelController.text.trim().toLowerCase();
    String newIp1 = _ip1Controller.text.trim();
    String newIp2 = _ip2Controller.text.trim();

    // Check for duplicate name
    if (allNames.contains(newName)) {
      setState(() => _saving = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خطا'),
          content: const Text(
            'نام وارد شده تکراری است. لطفاً نام دیگری انتخاب کنید.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('باشه'),
            ),
          ],
        ),
      );
      return;
    }

    // Check for duplicate IPs
    bool ipConflict = allIps.contains(newIp1) || allIps.contains(newIp2);
    if (ipConflict) {
      setState(() => _saving = false);
      // پیدا کردن اولین DNS موجود با IP تکراری
      DnsRecord? existingDns;
      // جستجو در کش و لیست کاربر
      final List<Map<String, dynamic>> allRecords = [];
      if (cachedJson != null) {
        try {
          final List<dynamic> cachedList = List.from(jsonDecode(cachedJson));
          allRecords.addAll(
            cachedList.map((e) => Map<String, dynamic>.from(e)),
          );
        } catch (_) {}
      }
      allRecords.addAll(jsonList.map((e) => Map<String, dynamic>.from(e)));
      for (var e in allRecords) {
        if (e['ip1'] == newIp1 ||
            e['ip2'] == newIp1 ||
            e['ip1'] == newIp2 ||
            e['ip2'] == newIp2) {
          existingDns = DnsRecord.fromJson(e);
          break;
        }
      }
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('IP تکراری'),
          content: const Text(
            'حداقل یکی از IPهای وارد شده قبلاً در یک DNS دیگر ثبت شده است. چه کاری می‌خواهید انجام دهید؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('لغو'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('connect'),
              child: const Text('وصل شدن به DNS موجود'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('add'),
              child: const Text('ثبت'),
            ),
          ],
        ),
      );
      if (result == 'cancel' || result == null) return;
      if (result == 'connect' && existingDns != null) {
        // ارسال رکورد موجود به والد و بستن دیالوگ
        widget.onAdd(existingDns);
        // فقط pop کافی است، چون والد (dns_list.dart) با دریافت رکورد، آن را انتخاب و به صفحه قبلی برمی‌گردد
        if (mounted) Navigator.pop(context, existingDns);
        return;
      }
      setState(() => _saving = true);
    }

    DnsRecord newRecord;
    if (widget.initialRecord != null) {
      // Edit mode: keep id/type/createdAt, update label/ip1/ip2
      newRecord = widget.initialRecord!.copyWith(
        label: _labelController.text.trim(),
        ip1: _ip1Controller.text.trim(),
        ip2: _ip2Controller.text.trim(),
      );
      // Remove old record by id
      jsonList.removeWhere((e) => e['id'] == widget.initialRecord!.id);
    } else {
      // Add mode
      newRecord = DnsRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _labelController.text.trim(),
        ip1: _ip1Controller.text.trim(),
        ip2: _ip2Controller.text.trim(),
        type: DnsType.other,
        createdAt: DateTime.now(),
      );
    }
    // Prevent duplicate by ip1+ip2 (except for edit mode, already removed old)
    final newKey = (newRecord.ip1 + '_' + newRecord.ip2)
        .replaceAll(' ', '')
        .toLowerCase();
    jsonList.removeWhere((e) {
      final key = (e['ip1'] + '_' + e['ip2']).replaceAll(' ', '').toLowerCase();
      return key == newKey;
    });
    jsonList.add(newRecord.toJson());
    await prefs.setString('user_dns_list', jsonEncode(jsonList));
    // Add to order (only for add mode)
    final cachedOrder = prefs.getStringList('cached_dns_order') ?? [];
    if (widget.initialRecord == null) {
      cachedOrder.add(newRecord.id);
      await prefs.setStringList('cached_dns_order', cachedOrder);
    }
    setState(() => _saving = false);
    widget.onAdd(newRecord);
    if (mounted) Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.initialRecord?.label ?? '',
    );
    _ip1Controller = TextEditingController(
      text: widget.initialRecord?.ip1 ?? '',
    );
    _ip2Controller = TextEditingController(
      text: widget.initialRecord?.ip2 ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialRecord != null;
    return AlertDialog(
      title: Text(isEdit ? 'ویرایش DNS' : 'افزودن DNS جدید'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'نام'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'نام را وارد کنید' : null,
            ),
            TextFormField(
              controller: _ip1Controller,
              decoration: const InputDecoration(labelText: 'DNS1'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'DNS1 را وارد کنید' : null,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextFormField(
              controller: _ip2Controller,
              decoration: const InputDecoration(labelText: 'DNS2'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'DNS2 را وارد کنید' : null,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'ثبت ویرایش' : 'افزودن'),
        ),
      ],
    );
  }
}
