import 'package:flutter/material.dart';

class DnsInfoPopup extends StatelessWidget {
  final String label;
  final String ip;
  final int? ping;

  const DnsInfoPopup({
    super.key,
    required this.label,
    required this.ip,
    this.ping,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.dns,
                size: MediaQuery.of(context).size.width * 0.12,
                color: Colors.blue.shade700),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language,
                    color: Colors.grey.shade700,
                    size: MediaQuery.of(context).size.width * 0.05),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Flexible(
                  child: Text(
                    ip,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
            if (ping != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed,
                      color: Colors.green.shade700,
                      size: MediaQuery.of(context).size.width * 0.05),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Text(
                    '$ping ms',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2), // Strong blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor: Colors.blue.shade100,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'بستن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
