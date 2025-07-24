import 'package:flutter/material.dart';
import '../path/path.dart';

/// صفحه Config (کشیدن به راست)
class ConfigScreen extends StatefulWidget {
  final VoidCallback onDnsManagerPressed;

  const ConfigScreen({Key? key, required this.onDnsManagerPressed})
    : super(key: key);

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String selectedProvider = 'Google';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          // کشیدن به چپ برای برگشت
          if (details.delta.dx < -5) {
            Navigator.pop(context);
          }
        },
        child: Container(
          decoration: const BoxDecoration(color: AppColors.configBackground),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Header with config icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Network icon (green hexagon pattern)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hub,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const Text(
                        'config',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.apps,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Provider selection
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black,
                          size: 24,
                        ),
                        Row(
                          children: [
                            Text(
                              selectedProvider,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.vpn_key,
                              color: Colors.black,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Connect button
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Servers section
                  Row(
                    children: [
                      const Icon(Icons.refresh, color: Colors.green, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Servers (benchmark)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.speed, color: Colors.black, size: 24),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Servers list
                  Expanded(
                    child: ListView(
                      children: [
                        _buildServerItem('Google', '8.8.8.8', true),
                        _buildServerItem('Cloudflare', '1.1.1.1', false),
                        _buildServerItem('Quad9', '9.9.9.9', false),
                        _buildServerItem(
                          'OpenDNS Home',
                          '208.67.222.222',
                          false,
                        ),
                        _buildServerItem('Verisign', '64.6.64.6', false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerItem(String name, String ip, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                ip,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          Icon(
            Icons.wifi,
            color: isSelected ? Colors.green : Colors.grey,
            size: 24,
          ),
        ],
      ),
    );
  }
}
