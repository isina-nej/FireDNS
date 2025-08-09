import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/services/update_api_service.dart';
import '../api/models/update_info.dart';
import '../api/models/update_type.dart';
import '../path/path.dart';
import 'package:provider/provider.dart';

class ForceUpdatePage extends StatefulWidget {
  final String updateUrl;
  final String currentAppVersion;
  const ForceUpdatePage({super.key, required this.updateUrl, required this.currentAppVersion});

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  late UpdateApiService _updateApiService;
  UpdateInfo? _updateInfo;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _updateApiService = UpdateApiService();
    _fetchUpdateInfo();
  }

  @override
  void dispose() {
    _updateApiService.dispose();
    super.dispose();
  }

  Future<void> _fetchUpdateInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

final response = await _updateApiService.getUpdateInfo(widget.currentAppVersion);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _updateInfo = response.data!;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در دریافت اطلاعات آپدیت';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Launch the update URL
  Future<void> _launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
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
  }

  /// Build update buttons based on update type
  Widget _buildUpdateButtons(UpdateInfo updateInfo) {
    switch (updateInfo.updateType) {
      case UpdateType.mandatory:
        // Mandatory update - user must update
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ElevatedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('دریافت نسخه جدید'),
          onPressed: () => _launchUpdateUrl(updateInfo.updateUrl),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: isDark ? Colors.redAccent.shade200 : Colors.red,
            foregroundColor: Colors.white,
          ),
        );
      
      case UpdateType.important:
        // Important update - user can skip but will be reminded
        return Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('دریافت نسخه جدید'),
              onPressed: () => _launchUpdateUrl(updateInfo.updateUrl),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.brightBlue
                    : AppColors.brightBlue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Return to previous screen
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              child: const Text('فعلاً رد کردن'),
            ),
          ],
        );
      
      case UpdateType.minor:
        // Minor update - user can skip and choose not to see again
        return Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('دریافت نسخه جدید'),
              onPressed: () => _launchUpdateUrl(updateInfo.updateUrl),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.brightBlue
                    : AppColors.brightBlue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Return to previous screen
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              child: const Text('فعلاً رد کردن'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: Save preference to not show this update again
                // This would typically use SharedPreferences to save the version
                // that the user has chosen to ignore
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text('دیگر نشان نده'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey,
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? CircularProgressIndicator(
                  color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                )
              : _errorMessage.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUpdateInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBackground.withOpacity(0.7) : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.system_update,
                              size: 80,
                              color: isDark ? Colors.redAccent.shade100 : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'نسخه جدید برنامه در دسترس است!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'برای ادامه استفاده، لطفاً برنامه را به‌روزرسانی کنید.',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Version information
                          if (_updateInfo != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCardBackground
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkTextSecondary.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'نسخه فعلی: ${_updateInfo!.currentVersion}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'نسخه جدید: ${_updateInfo!.latestVersion}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.greenAccent : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Description
                            if (_updateInfo!.description.isNotEmpty) ...[
                              Text(
                                _updateInfo!.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Features
                            if (_updateInfo!.features.isNotEmpty) ...[
                              Text(
                                'ویژگی‌های جدید:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ..._updateInfo!.features.map((feature) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: isDark ? Colors.greenAccent : Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            feature,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 16),
                            ],
                            // Changes
                            if (_updateInfo!.changes.isNotEmpty) ...[
                              Text(
                                'تغییرات:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ..._updateInfo!.changes.map((change) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Icon(
                                          Icons.update,
                                          size: 16,
                                          color: isDark ? AppColors.brightBlue : Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            change,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 24),
                            ],
                          ],
                          // Update buttons based on update type
                          if (_updateInfo != null) ...[
                            _buildUpdateButtons(_updateInfo!),
                          ] else ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('دریافت نسخه جدید'),
                              onPressed: () => _launchUpdateUrl(widget.updateUrl),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(fontSize: 18),
                                backgroundColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
