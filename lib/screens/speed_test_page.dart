import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_speed_test_plus/flutter_speed_test_plus.dart';
import '../path/path.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({Key? key}) : super(key: key);

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  double downloadSpeed = 0;
  double uploadSpeed = 0;
  bool isTesting = true;
  String status = "در حال تست دانلود...";

  @override
  void initState() {
    super.initState();
    _startSpeedTest();
  }

  void _startSpeedTest() {
    setState(() {
      isTesting = true;
      status = "در حال تست دانلود...";
      downloadSpeed = 0;
      uploadSpeed = 0;
    });
    final speedTest = FlutterInternetSpeedTest();
    speedTest.startTesting(
      useFastApi: true,
      onStarted: () {
        setState(() {
          status = "در حال تست دانلود...";
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          if (data.type == TestType.download) {
            downloadSpeed = data.transferRate;
            status = "در حال تست دانلود...";
          } else if (data.type == TestType.upload) {
            uploadSpeed = data.transferRate;
            status = "در حال تست آپلود...";
          }
        });
      },
      onDownloadComplete: (TestResult data) {
        setState(() {
          downloadSpeed = data.transferRate;
          status = "در حال تست آپلود...";
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسپید تست')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 13.0,
              animation: true,
              percent: isTesting
                  ? 0.5
                  : 1.0, // Just for visual, can be improved
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isTesting ? status : "تست تمام شد",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "دانلود: ${downloadSpeed.toStringAsFixed(2)} Mbps",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "آپلود: ${uploadSpeed.toStringAsFixed(2)} Mbps",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: isTesting ? Colors.blue : Colors.green,
            ),
            const SizedBox(height: 40),
            if (!isTesting)
              ElevatedButton(
                onPressed: _startSpeedTest,
                child: const Text('تست مجدد'),
              ),
          ],
        ),
      ),
    );
  }
}
