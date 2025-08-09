import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/update_checker.dart';
import 'force_update_page.dart';
import '../path/path.dart';
import 'package:provider/provider.dart';

class CheckUpdatePage extends StatefulWidget {
  const CheckUpdatePage({Key? key}) : super(key: key);

  @override
  State<CheckUpdatePage> createState() => _CheckUpdatePageState();
}

class _CheckUpdatePageState extends State<CheckUpdatePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLatestVersion = true;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _checkForUpdates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isLatest = await UpdateChecker.isLatestVersion();
      
      setState(() {
        _isLatestVersion = isLatest;
        _isLoading = false;
      });

      if (!isLatest && mounted) {
        // اگر نسخه جدید موجود باشد، صفحه بروزرسانی اجباری را نمایش می‌دهیم
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ForceUpdatePage(
              updateUrl: UpdateChecker.updateUrl,
              currentAppVersion: UpdateChecker.currentVersion,
            ),
          ),
        );
      } else if (isLatest) {
        // اگر آخرین نسخه باشد، انیمیشن را پخش می‌کنیم
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${context.tr('updateCheckError')}: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('checkForUpdates'),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundLight,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
        ),
        elevation: 0,
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('checkingForUpdates'),
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : _errorMessage.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(context.tr('tryAgain')),
                          onPressed: _checkForUpdates,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _isLatestVersion
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: Lottie.asset(
                                'assets/icone/check_animation.json', // مسیر فایل انیمیشن
                                controller: _animationController,
                                repeat: false,
                                onLoaded: (composition) {
                                  _animationController.duration = composition.duration;
                                  _animationController.forward();
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    context.tr('usingLatestVersion'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${context.tr('currentVersion')}: ${UpdateChecker.currentVersion}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.home),
                              label: Text(context.tr('returnToHome')),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(), // این حالت هرگز اتفاق نمی‌افتد چون در صورت وجود آپدیت، به صفحه دیگری منتقل می‌شویم
        ),
      ),
    );
  }
}