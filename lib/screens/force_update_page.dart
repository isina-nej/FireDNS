import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/services/update_api_service.dart';
import '../api/models/update_info.dart';
import '../api/models/update_type.dart';
import '../path/path.dart';
import 'package:provider/provider.dart';

/// صفحه نمایش و مدیریت آپدیت برنامه
class ForceUpdatePage extends StatefulWidget {
  final String updateUrl;
  final String currentAppVersion;
  const ForceUpdatePage({
    super.key,
    required this.updateUrl,
    required this.currentAppVersion,
  });

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage>
    with SingleTickerProviderStateMixin {
  late UpdateApiService _updateApiService;
  UpdateInfo? _updateInfo;
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _updateApiService = UpdateApiService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchUpdateInfo();
  }

  @override
  void dispose() {
    _updateApiService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUpdateInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🔄 درخواست اطلاعات آپدیت برای نسخه ${widget.currentAppVersion}');
      final response =
          await _updateApiService.getUpdateInfo(widget.currentAppVersion);

      if (response.status && response.data != null) {
        print('✅ اطلاعات آپدیت دریافت شد');
        print('📝 توضیحات: ${response.data!.description}');
        print('🔄 نوع آپدیت: ${response.data!.updateType}');
        setState(() {
          _updateInfo = response.data!;
        });
        _animationController.forward();
      } else {
        print('❌ خطا در دریافت اطلاعات: ${response.message}');
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      print('⚠️ خطای غیرمنتظره: $e');
      setState(() {
        _errorMessage = context.tr('updateInfoError');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUpdateUrl(String url) async {
    print('🌐 باز کردن لینک آپدیت: $url');
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        print('❌ خطا در باز کردن لینک');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cannotOpenWebsite')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('⚠️ خطا در باز کردن لینک: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('errorOpeningWebsite')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildVersionRow(String label, String version, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              version,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      String title, List<String> items, IconData icon, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withOpacity(0.5)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.brightBlue
                            : AppColors.brightBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildUpdateButtons(UpdateInfo updateInfo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (updateInfo.updateType) {
      case UpdateType.mandatory:
        return ElevatedButton.icon(
          icon: const Icon(Icons.system_update),
          label: Text(context.tr('getNewVersion')),
          onPressed: () => _launchUpdateUrl(updateInfo.updateUrl),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: isDark ? Colors.redAccent.shade200 : Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case UpdateType.important:
        return Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.system_update),
              label: Text(context.tr('getNewVersion')),
              onPressed: () => _launchUpdateUrl(updateInfo.updateUrl),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: AppColors.brightBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.update),
              label: Text(context.tr('skipForNow')),
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                foregroundColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        );

      case UpdateType.minor:
        return Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.system_update),
              label: Text(context.tr('getNewVersion')),
              onPressed: () => _launchUpdateUrl(updateInfo.updateUrl),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: AppColors.brightBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.update),
              label: Text(context.tr('skipForNow')),
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                foregroundColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.do_not_disturb),
              label: Text(context.tr('dontShowAgain')),
              onPressed: () async {
                print(
                    '💾 ذخیره نسخه ${updateInfo.latestVersion} برای عدم نمایش مجدد');
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                    'ignored_update_version', updateInfo.latestVersion);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final isDark = themeManager.isDarkModeActive(context);

        return PopScope(
          canPop: _updateInfo?.updateType != UpdateType.mandatory,
          child: Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _updateInfo?.updateType == UpdateType.mandatory
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.brightBlue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('checkingForUpdates'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : _errorMessage.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: Text(context.tr('tryAgain')),
                                onPressed: _fetchUpdateInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brightBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScaleTransition(
                                  scale: _animation,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.05)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.system_update,
                                      size: 64,
                                      color: isDark
                                          ? Colors.redAccent.shade100
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FadeTransition(
                                  opacity: _animation,
                                  child: Column(
                                    children: [
                                      Text(
                                        context.tr('newVersionAvailable'),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.textPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_updateInfo != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _updateInfo!.description,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        // Version information
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey.shade900
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              _buildVersionRow(
                                                context.tr('currentVersion'),
                                                _updateInfo!.currentVersion,
                                                isDark,
                                              ),
                                              Divider(
                                                color: isDark
                                                    ? Colors.grey.shade800
                                                    : Colors.grey.shade300,
                                              ),
                                              _buildVersionRow(
                                                context.tr('newVersion'),
                                                _updateInfo!.latestVersion,
                                                isDark,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        if (_updateInfo!
                                            .features.isNotEmpty) ...[
                                          _buildInfoSection(
                                            context.tr('newFeatures'),
                                            _updateInfo!.features,
                                            Icons.star_outline,
                                            isDark,
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        if (_updateInfo!
                                            .changes.isNotEmpty) ...[
                                          _buildInfoSection(
                                            context.tr('changes'),
                                            _updateInfo!.changes,
                                            Icons.change_circle_outlined,
                                            isDark,
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        _buildUpdateButtons(_updateInfo!),
                                      ],
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
      },
    );
  }
}
