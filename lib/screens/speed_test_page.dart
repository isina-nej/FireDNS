// import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:flutter_speed_test_plus/flutter_speed_test_plus.dart';
import '../path/path.dart';
import 'package:http/http.dart' as http;
import '../services/dns_service.dart';
import '../models/dns_status.dart';
import 'package:provider/provider.dart';
import '../styles/app_colors.dart';
import '../styles/theme_manager.dart';
import '../l10n/localization_extension.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  double downloadSpeed = 0;
  double uploadSpeed = 0;
  bool isTesting = true;
  String status = '';
  FlutterInternetSpeedTest? _speedTestInstance;
  double ping = 0;
  String server = '';
  String userIp = '';
  bool showDownloadGauge = true;

  // Variables to track average and max speeds
  double maxDownload = 0;
  double maxUpload = 0;
  double sumDownload = 0;
  double sumUpload = 0;
  int downloadCount = 0;
  int uploadCount = 0;
  double avgDownload = 0;
  double avgUpload = 0;

  DnsStatus? lastPingStatus;

  @override
  void initState() {
    super.initState();
    _fetchNetworkInfo();
    _fetchPing();
    _startSpeedTest();
  }

  Future<void> _fetchNetworkInfo() async {
    // For now, use placeholders
    setState(() {
      server = 'fast.com';
      userIp = context.tr('unknown');
    });
    try {
      final uri = Uri.parse('https://api.ipify.org');
      final response = await http.get(uri);
      setState(() {
        userIp =
            response.statusCode == 200 ? response.body : context.tr('unknown');
      });
    } catch (_) {
      setState(() {
        userIp = context.tr('unknown');
      });
    }
  }

  Future<void> _fetchPing() async {
    final status = await DnsService.testDns('8.8.8.8');
    setState(() {
      lastPingStatus = status;
      ping = status.ping.toDouble();
    });
  }

  void _startSpeedTest() {
    _speedTestInstance?.cancelTest();
    _speedTestInstance = null;
    setState(() {
      isTesting = true;
      status = context.tr('downloading');
      downloadSpeed = 0;
      uploadSpeed = 0;
      ping = 0;
      showDownloadGauge = true;
      // Reset stats for new test
      maxDownload = 0;
      maxUpload = 0;
      sumDownload = 0;
      sumUpload = 0;
      downloadCount = 0;
      uploadCount = 0;
      avgDownload = 0;
      avgUpload = 0;
    });
    final speedTest = FlutterInternetSpeedTest();
    _speedTestInstance = speedTest;
    speedTest.startTesting(
      useFastApi: true,
      onStarted: () {
        setState(() {
          status = context.tr('downloading');
          showDownloadGauge = true;
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          if (data.type == TestType.download) {
            downloadSpeed = data.transferRate;
            status = context.tr('downloading');
            showDownloadGauge = true;
            // Track download stats
            maxDownload =
                downloadSpeed > maxDownload ? downloadSpeed : maxDownload;
            sumDownload += downloadSpeed;
            downloadCount++;
            avgDownload = sumDownload / downloadCount;
          } else if (data.type == TestType.upload) {
            uploadSpeed = data.transferRate;
            status = context.tr('uploading');
            showDownloadGauge = false;
            // Track upload stats
            maxUpload = uploadSpeed > maxUpload ? uploadSpeed : maxUpload;
            sumUpload += uploadSpeed;
            uploadCount++;
            avgUpload = sumUpload / uploadCount;
          }
        });
      },
      onDownloadComplete: (TestResult data) {
        setState(() {
          downloadSpeed = data.transferRate;
          status = context.tr('uploading');
          showDownloadGauge = false;
        });
      },
      onUploadComplete: (TestResult data) {
        setState(() {
          uploadSpeed = data.transferRate;
        });
      },
      onCompleted: (TestResult download, TestResult upload) {
        setState(() {
          downloadSpeed = download.transferRate;
          uploadSpeed = upload.transferRate;
          isTesting = false;
          status = context.tr('testComplete');
          showDownloadGauge = true;
        });
      },
      onError: (String errorMessage, String speedTestError) {
        setState(() {
          isTesting = false;
          status = context.tr('speedTestError');
        });
      },
      onCancel: () {
        setState(() {
          isTesting = false;
          status = context.tr('testCancelled');
        });
      },
    );
  }

  @override
  void dispose() {
    _speedTestInstance?.cancelTest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                Colors.blueAccent,
                Colors.cyanAccent,
                Colors.purpleAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            context.tr('speedTestTitle'),
            style: TextStyle(
              fontFamily: Provider.of<LanguageManager>(context, listen: false)
                  .fontFamily,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Color(0xFF232526), Color(0xFF414345)]
                    : [Color(0xFF74ebd5), Color(0xFFACB6E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Glassmorphism Card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.white54,
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 18),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: showDownloadGauge
                                  ? SleekCircularSlider(
                                      min: 0,
                                      max: 200,
                                      initialValue: downloadSpeed,
                                      appearance: CircularSliderAppearance(
                                        customWidths: CustomSliderWidths(
                                          progressBarWidth: 20,
                                          trackWidth: 18,
                                        ),
                                        customColors: CustomSliderColors(
                                          progressBarColor: isTesting
                                              ? Colors.blueAccent
                                              : Colors.greenAccent,
                                          trackColor: isDark
                                              ? Colors.grey.shade900
                                              : Colors.grey.shade200,
                                          dotColor: Colors.white,
                                        ),
                                        infoProperties: InfoProperties(
                                          mainLabelStyle: TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black12,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          modifier: (double value) {
                                            return '${value.toStringAsFixed(1)} ${context.tr('speedUnit')}';
                                          },
                                          bottomLabelText:
                                              context.tr('downloadSpeed'),
                                          bottomLabelStyle: TextStyle(
                                            fontSize: 20,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        startAngle: 150,
                                        angleRange: 240,
                                        size: 240,
                                      ),
                                    )
                                  : SleekCircularSlider(
                                      min: 0,
                                      max: 200,
                                      initialValue: uploadSpeed,
                                      appearance: CircularSliderAppearance(
                                        customWidths: CustomSliderWidths(
                                          progressBarWidth: 20,
                                          trackWidth: 18,
                                        ),
                                        customColors: CustomSliderColors(
                                          progressBarColor: isTesting
                                              ? Colors.orangeAccent
                                              : Colors.greenAccent,
                                          trackColor: isDark
                                              ? Colors.grey.shade900
                                              : Colors.grey.shade200,
                                          dotColor: Colors.white,
                                        ),
                                        infoProperties: InfoProperties(
                                          mainLabelStyle: TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black12,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          modifier: (double value) {
                                            return '${value.toStringAsFixed(1)} ${context.tr('speedUnit')}';
                                          },
                                          bottomLabelText:
                                              context.tr('uploadSpeed'),
                                          bottomLabelStyle: TextStyle(
                                            fontSize: 20,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        startAngle: 150,
                                        angleRange: 240,
                                        size: 240,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InfoTile(
                                  icon: Icons.speed,
                                  label: context.tr('ping'),
                                  value: lastPingStatus == null
                                      ? '...'
                                      : lastPingStatus!.isReachable &&
                                              lastPingStatus!.ping >= 0
                                          ? '${lastPingStatus!.ping} ms'
                                          : context.tr('unknown'),
                                ),
                                InfoTile(
                                  icon: Icons.cloud,
                                  label: context.tr('server'),
                                  value: server,
                                ),
                                InfoTile(
                                  icon: Icons.person,
                                  label: context.tr('yourIp'),
                                  value: userIp,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: isTesting
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        status,
                                        key: ValueKey(status),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.blueGrey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 10),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: isTesting ? 1 : 0.0,
                              child: Text(
                                '${context.tr('uploadSpeed')}: ${uploadSpeed.toStringAsFixed(2)} ${context.tr('speedUnit')}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (!isTesting) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.white54,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 12),
                          child: Column(
                            children: [
                              Text(
                                context.tr('finalResults'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ResultTile(
                                    label: context.tr('averageDownload'),
                                    value:
                                        '${avgDownload.toStringAsFixed(2)} ${context.tr('speedUnit')}',
                                  ),
                                  ResultTile(
                                    label: context.tr('maxDownload'),
                                    value:
                                        '${maxDownload.toStringAsFixed(2)} ${context.tr('speedUnit')}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ResultTile(
                                    label: context.tr('averageUpload'),
                                    value:
                                        '${avgUpload.toStringAsFixed(2)} ${context.tr('speedUnit')}',
                                  ),
                                  ResultTile(
                                    label: context.tr('maxUpload'),
                                    value:
                                        '${maxUpload.toStringAsFixed(2)} ${context.tr('speedUnit')}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.blueAccent,
                                        Colors.purpleAccent,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      setState(() {
                                        lastPingStatus = null;
                                        ping = 0;
                                        userIp = context.tr('unknown');
                                        server = 'fast.com';
                                      });
                                      await _fetchNetworkInfo();
                                      await _fetchPing();
                                      _startSpeedTest();
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: Text(context.tr('retryTest')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 28,
          color: isDark ? AppColors.brightBlue : Colors.blueAccent,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class ResultTile extends StatelessWidget {
  final String label;
  final String value;

  const ResultTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : Colors.black87,
          ),
        ),
      ],
    );
  }
}
