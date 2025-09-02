import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/theme_controller.dart';
import '../path/path.dart';
import '../services/navigation_service.dart';
import '../utils/update_checker.dart';
import 'force_update_page.dart';

class CheckUpdatePage extends StatefulWidget {
  const CheckUpdatePage({super.key});

  @override
  State<CheckUpdatePage> createState() => _CheckUpdatePageState();
}

class _CheckUpdatePageState extends State<CheckUpdatePage>
    with SingleTickerProviderStateMixin {
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
    // فراخوانی چک آپدیت را به بعد از ساخت ویجت موکول می‌کنیم تا به context دسترسی داشته باشیم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
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
      final languageCode = Localizations.localeOf(context).languageCode;
      final (isLatest, updateInfo) =
          await UpdateChecker.checkForUpdates(languageCode: languageCode);

      setState(() {
        _isLatestVersion = isLatest;
        _isLoading = false;
      });

      if (!isLatest && updateInfo != null && mounted) {
        // اگر نسخه جدید موجود باشد، صفحه بروزرسانی اجباری را نمایش می‌دهیم
        NavigationService.navigateToPageReplacement(
          ForceUpdatePage(
            updateUrl: updateInfo.updateUrl,
            currentAppVersion: UpdateChecker.currentVersion,
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
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode;

    return PopScope(
        canPop: true,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            iconTheme: IconThemeData(
              color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
            ),
            title: Text(
              context.tr('checkForUpdates'),
              style: TextStyle(
                color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF232526), const Color(0xFF414345)]
                    : [const Color(0xFFe0eafc), const Color(0xFFcfdef3)],
              ),
            ),
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.width * 0.3,
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Lottie.asset(
                              'assets/icone/Fire.json', // مسیر صحیح انیمیشن موجود
                              repeat: true,
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.04),
                          Text(
                            context.tr('checkingForUpdates'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.brightBlue
                                  : AppColors.brightBlue,
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
                                size: MediaQuery.of(context).size.width * 0.225,
                                color: Colors.redAccent,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.04),
                              ElevatedButton.icon(
                                icon: Icon(Icons.refresh,
                                    size: MediaQuery.of(context).size.width *
                                        0.065),
                                label: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    context.tr('tryAgain'),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onPressed: _checkForUpdates,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.brightBlue
                                      : AppColors.brightBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 12),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          )
                        : _isLatestVersion
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.2),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius:
                                          MediaQuery.of(context).size.width *
                                              0.15,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.verified_rounded,
                                        color: Colors.green,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.175,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.03),
                                  Text(
                                    context.tr('usingLatestVersion'),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.brightBlue
                                          : AppColors.brightBlue,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.02),
                                  Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    color: isDark
                                        ? AppColors.darkCardBackground
                                        : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 18),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.info_outline,
                                                  color: isDark
                                                      ? AppColors.brightBlue
                                                      : AppColors.brightBlue),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.02),
                                              Text(
                                                '${context.tr('currentVersion')}: ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AppColors
                                                          .darkTextPrimary
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                UpdateChecker.currentVersion,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? AppColors.brightBlue
                                                      : AppColors.brightBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.04),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.home,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.065),
                                    label: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                        context.tr('returnToHome'),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? AppColors.brightBlue
                                          : AppColors.brightBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 36, vertical: 12),
                                      elevation: 4,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox(),
              ),
            ),
          ),
        ));
  }
}
