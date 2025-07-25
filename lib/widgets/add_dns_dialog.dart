import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../path/path.dart';

class AddDnsDialog extends StatefulWidget {
  final void Function(DnsRecord) onAdd;
  const AddDnsDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddDnsDialog> createState() => _AddDnsDialogState();
}

class _AddDnsDialogState extends State<AddDnsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _ip1Controller = TextEditingController();
  final _ip2Controller = TextEditingController();
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
    final newRecord = DnsRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelController.text.trim(),
      ip1: _ip1Controller.text.trim(),
      ip2: _ip2Controller.text.trim(),
      type: DnsType.other, // custom DNS will be marked as 'other'
      createdAt: DateTime.now(),
    );
    // Prevent duplicate by ip1+ip2
    final newKey = (newRecord.ip1 + '_' + newRecord.ip2)
        .replaceAll(' ', '')
        .toLowerCase();
    jsonList.removeWhere((e) {
      final key = (e['ip1'] + '_' + e['ip2']).replaceAll(' ', '').toLowerCase();
      return key == newKey;
    });
    jsonList.add(newRecord.toJson());
    await prefs.setString('user_dns_list', jsonEncode(jsonList));
    // Add to order
    final cachedOrder = prefs.getStringList('cached_dns_order') ?? [];
    cachedOrder.add(newRecord.id);
    await prefs.setStringList('cached_dns_order', cachedOrder);
    setState(() => _saving = false);
    widget.onAdd(newRecord);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن DNS جدید'),
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
              : const Text('افزودن'),
        ),
      ],
    );
  }
}
