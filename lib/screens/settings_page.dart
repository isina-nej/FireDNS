import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'تنظیمات',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingSection(
            title: 'عمومی',
            items: [
              _buildSettingItem(
                icon: Icons.language,
                title: 'زبان برنامه',
                subtitle: 'فارسی',
                onTap: () {
                  // TODO: نمایش دیالوگ تغییر زبان
                },
              ),
              _buildSettingItem(
                icon: Icons.dark_mode,
                title: 'تم برنامه',
                subtitle: 'روشن',
                onTap: () {
                  // TODO: تغییر تم برنامه
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            title: 'اعلان‌ها',
            items: [
              _buildSettingItem(
                icon: Icons.notifications,
                title: 'اعلان‌های برنامه',
                isSwitch: true,
                onChanged: (value) {
                  // TODO: تغییر وضعیت اعلان‌ها
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            title: 'درباره ما',
            items: [
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'نسخه برنامه',
                subtitle: '1.0.0',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isSwitch = false,
    ValueChanged<bool>? onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSwitch ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSwitch)
                Switch(
                  value: false, // مقدار پیش‌فرض
                  onChanged: onChanged,
                  activeColor: Colors.blue,
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
