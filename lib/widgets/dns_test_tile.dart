// lib/widgets/dns_test_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../path/path.dart'; // Assuming AppColors, context.tr are imported
// import '../utils/dns_service.dart'; // Assuming DnsService is here

class DnsTestTile extends StatefulWidget {
  final String domain;
  final DnsRecord record;
  const DnsTestTile({required this.domain, required this.record});

  @override
  State<DnsTestTile> createState() => _DnsTestTileState();
}

class _DnsTestTileState extends State<DnsTestTile> {
  dynamic status;
  bool _loading = true;

  late final ThemeManager themeManager;
  late final bool isDark;

  @override
  void initState() {
    themeManager = Provider.of<ThemeManager>(context, listen: false);
    isDark = themeManager.isDarkModeActive(context);
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    final result = await DnsService.testDnsWithDns(
      widget.domain,
      widget.record.ip1,
    );
    if (!mounted) return;
    setState(() {
      status = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.record.label,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
        ),
      ),
      subtitle: Text(
        widget.record.ip1,
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : Colors.grey[600],
        ),
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : status != null
              ? Text(
                  status.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : Text(context.tr('error'),
                  style: const TextStyle(color: Colors.red)),
    );
  }
}