import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdatePage extends StatelessWidget {
  final String updateUrl;
  const ForceUpdatePage({super.key, required this.updateUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.system_update, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'نسخه جدید برنامه در دسترس است!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'برای ادامه استفاده، لطفاً برنامه را به‌روزرسانی کنید.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('دریافت نسخه جدید'),
                onPressed: () async {
                  final uri = Uri.parse(updateUrl);
                  try {
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('امکان باز کردن وبسایت وجود ندارد!'),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('خطا در باز کردن وبسایت!'),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
