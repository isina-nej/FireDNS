// import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:flutter_speed_test_plus/flutter_speed_test_plus.dart';
// import '../path/path.dart';

import 'package:http/http.dart' as http;
import '../services/dns_service.dart';
import '../models/dns_status.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  double downloadSpeed = 0;
  double uploadSpeed = 0;
  bool isTesting = true;
  String status = "در حال تست دانلود...";
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
      userIp = 'در حال دریافت...';
    });
    try {
      final uri = Uri.parse('https://api.ipify.org');
      final response = await http.get(uri);
      setState(() {
        userIp = response.statusCode == 200 ? response.body : 'نامشخص';
      });
    } catch (_) {
      setState(() {
        userIp = 'نامشخص';
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
      status = "در حال تست دانلود...";
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
          status = "در حال تست دانلود...";
          showDownloadGauge = true;
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          if (data.type == TestType.download) {
            downloadSpeed = data.transferRate;
            status = "در حال تست دانلود...";
            showDownloadGauge = true;
            // Track download stats
            maxDownload = downloadSpeed > maxDownload
                ? downloadSpeed
                : maxDownload;
            sumDownload += downloadSpeed;
            downloadCount++;
            avgDownload = sumDownload / downloadCount;
          } else if (data.type == TestType.upload) {
            uploadSpeed = data.transferRate;
            status = "در حال تست آپلود...";
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
          status = "در حال تست آپلود...";
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
          status = "تست تمام شد";
          showDownloadGauge = true;
        });
      },
      onError: (String errorMessage, String speedTestError) {
        setState(() {
          isTesting = false;
          status = "خطا در تست سرعت";
        });
      },
      onCancel: () {
        setState(() {
          isTesting = false;
          status = "تست لغو شد";
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'اسپید تست',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
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
                                      progressBarWidth: 18,
                                      trackWidth: 18,
                                    ),
                                    customColors: CustomSliderColors(
                                      progressBarColor: isTesting
                                          ? Colors.blue
                                          : Colors.green,
                                      trackColor: Colors.grey.shade200,
                                      dotColor: Colors.white,
                                    ),
                                    infoProperties: InfoProperties(
                                      mainLabelStyle: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      modifier: (double value) {
                                        return '${value.toStringAsFixed(1)} Mbps';
                                      },
                                      bottomLabelText: 'سرعت دانلود',
                                      bottomLabelStyle: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    startAngle: 150,
                                    angleRange: 240,
                                    size: 220,
                                  ),
                                )
                              : SleekCircularSlider(
                                  min: 0,
                                  max: 200,
                                  initialValue: uploadSpeed,
                                  appearance: CircularSliderAppearance(
                                    customWidths: CustomSliderWidths(
                                      progressBarWidth: 18,
                                      trackWidth: 18,
                                    ),
                                    customColors: CustomSliderColors(
                                      progressBarColor: isTesting
                                          ? Colors.orange
                                          : Colors.green,
                                      trackColor: Colors.grey.shade200,
                                      dotColor: Colors.white,
                                    ),
                                    infoProperties: InfoProperties(
                                      mainLabelStyle: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      modifier: (double value) {
                                        return '${value.toStringAsFixed(1)} Mbps';
                                      },
                                      bottomLabelText: 'سرعت آپلود',
                                      bottomLabelStyle: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    startAngle: 150,
                                    angleRange: 240,
                                    size: 220,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InfoTile(
                              icon: Icons.speed,
                              label: 'پینگ',
                              value: lastPingStatus == null
                                  ? '...'
                                  : lastPingStatus!.isReachable &&
                                        lastPingStatus!.ping >= 0
                                  ? '${lastPingStatus!.ping} ms'
                                  : 'نامشخص',
                            ),
                            InfoTile(
                              icon: Icons.cloud,
                              label: 'سرور',
                              value: server,
                            ),
                            InfoTile(
                              icon: Icons.person,
                              label: 'آی‌پی شما',
                              value: userIp,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'آپلود: ${uploadSpeed.toStringAsFixed(2)} Mbps',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isTesting
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    status,
                                    key: ValueKey(status),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (!isTesting) ...[
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'نتایج نهایی',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ResultTile(
                                label: 'میانگین دانلود',
                                value: '${avgDownload.toStringAsFixed(2)} Mbps',
                              ),
                              ResultTile(
                                label: 'رکورد دانلود',
                                value: '${maxDownload.toStringAsFixed(2)} Mbps',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ResultTile(
                                label: 'میانگین آپلود',
                                value: '${avgUpload.toStringAsFixed(2)} Mbps',
                              ),
                              ResultTile(
                                label: 'رکورد آپلود',
                                value: '${maxUpload.toStringAsFixed(2)} Mbps',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _startSpeedTest,
                              icon: const Icon(Icons.refresh),
                              label: const Text('تست مجدد'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: Colors.blueAccent),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
