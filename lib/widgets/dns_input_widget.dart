import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../path/path.dart';


/// ویجت ورودی DNS
class DnsInputWidget extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool showValidation;

  const DnsInputWidget({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.onChanged,
    this.enabled = true,
    this.showValidation = true,
  }) : super(key: key);

  @override
  State<DnsInputWidget> createState() => _DnsInputWidgetState();
}

class _DnsInputWidgetState extends State<DnsInputWidget> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    if (!widget.showValidation) return;

    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = null;
      });
      return;
    }

    final error = DnsValidator.getValidationError(text);
    setState(() {
      _errorText = error.isEmpty ? null : error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        LengthLimitingTextInputFormatter(15), // حداکثر طول IP
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
        errorText: _errorText,
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: widget.enabled
                    ? () {
                        widget.controller.clear();
                        widget.onChanged?.call('');
                      }
                    : null,
              )
            : null,
      ),
      onTap: () {
        if (widget.enabled) {
          widget.controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: widget.controller.text.length,
          );
        }
      },
      onChanged: widget.onChanged,
    );
  }
}

/// ویجت انتخاب DNS از لیست محبوب
class DnsPresetSelector extends StatelessWidget {
  final ValueChanged<Map<String, String>>? onDnsSelected;

  const DnsPresetSelector({Key? key, this.onDnsSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DNS های محبوب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...DnsConstants.popularDnsServers.entries.map(
            (entry) => _buildDnsPresetItem(
              context,
              entry.key,
              entry.value['primary']!,
              entry.value['secondary']!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDnsPresetItem(
    BuildContext context,
    String name,
    String primary,
    String secondary,
  ) {
    return InkWell(
      onTap: () {
        onDnsSelected?.call({
          'name': name,
          'primary': primary,
          'secondary': secondary,
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اصلی: $primary',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'فرعی: $secondary',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// ویجت نمایش تنظیمات DNS
class DnsSettingsWidget extends StatefulWidget {
  final TextEditingController dns1Controller;
  final TextEditingController dns2Controller;
  final bool enabled;
  final ValueChanged<String>? onDns1Changed;
  final ValueChanged<String>? onDns2Changed;

  const DnsSettingsWidget({
    Key? key,
    required this.dns1Controller,
    required this.dns2Controller,
    this.enabled = true,
    this.onDns1Changed,
    this.onDns2Changed,
  }) : super(key: key);

  @override
  State<DnsSettingsWidget> createState() => _DnsSettingsWidgetState();
}

class _DnsSettingsWidgetState extends State<DnsSettingsWidget> {
  bool _showPresets = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DnsInputWidget(
          label: DnsConstants.uiTexts['dns1Label']!,
          hint: DnsConstants.defaultPrimaryDns,
          controller: widget.dns1Controller,
          enabled: widget.enabled,
          onChanged: widget.onDns1Changed,
        ),
        const SizedBox(height: 16),
        DnsInputWidget(
          label: DnsConstants.uiTexts['dns2Label']!,
          hint: DnsConstants.defaultSecondaryDns,
          controller: widget.dns2Controller,
          enabled: widget.enabled,
          onChanged: widget.onDns2Changed,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _showPresets = !_showPresets;
            });
          },
          icon: Icon(_showPresets ? Icons.expand_less : Icons.expand_more),
          label: Text(_showPresets ? 'مخفی کردن' : 'انتخاب از لیست'),
        ),
        if (_showPresets) ...[
          const SizedBox(height: 16),
          DnsPresetSelector(
            onDnsSelected: (dns) {
              widget.dns1Controller.text = dns['primary']!;
              widget.dns2Controller.text = dns['secondary']!;
              widget.onDns1Changed?.call(dns['primary']!);
              widget.onDns2Changed?.call(dns['secondary']!);
              setState(() {
                _showPresets = false;
              });
            },
          ),
        ],
      ],
    );
  }
}
