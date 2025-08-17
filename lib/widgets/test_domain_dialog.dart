// lib/widgets/test_domain_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../path/path.dart'; // Assuming AppColors, context.tr are defined here
import 'dns_test_tile.dart';

class TestDomainWithAllDnsDialog extends StatefulWidget {
  final String domain;
  final List<DnsRecord> dnsRecords;
  const TestDomainWithAllDnsDialog({
    required this.domain,
    required this.dnsRecords,
  });

  @override
  State<TestDomainWithAllDnsDialog> createState() =>
      _TestDomainWithAllDnsDialogState();
}

class _TestDomainWithAllDnsDialogState
    extends State<TestDomainWithAllDnsDialog> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      title: Text(
        '${context.tr('testDomainWithAllDns')}: "${widget.domain}"',
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.dnsRecords.length,
          itemBuilder: (context, index) {
            final record = widget.dnsRecords[index];
            return DnsTestTile(domain: widget.domain, record: record);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.tr('close'),
            style: TextStyle(
              color:
                  isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
            ),
          ),
        ),
      ],
    );
  }
}