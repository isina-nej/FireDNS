import 'package:flutter/material.dart';
import '../path/path.dart';

/// ویجت نمایش نتیجه تست اتصال Google
class GoogleConnectivityWidget extends StatelessWidget {
  final GoogleConnectivityResult? result;
  final VoidCallback? onTest;
  final bool isLoading;

  const GoogleConnectivityWidget({
    Key? key,
    this.result,
    this.onTest,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تست اتصال Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // دکمه تست
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onTest,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(isLoading ? 'در حال تست...' : 'تست Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // نتیجه تست
          if (result != null) ...[
            const SizedBox(height: 16),
            _buildResultContainer(result!),
          ],
        ],
      ),
    );
  }

  Widget _buildResultContainer(GoogleConnectivityResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.overallStatus
            ? Colors.green.shade100
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.overallStatus
              ? Colors.green.shade300
              : Colors.red.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // پیام کلی
          Row(
            children: [
              Icon(
                result.overallStatus ? Icons.check_circle : Icons.error,
                color: result.overallStatus
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: TextStyle(
                    color: result.overallStatus
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // جزئیات تست
          _buildTestDetail(
            'پینگ Google',
            result.googlePing,
            Icons.network_ping,
          ),
          const SizedBox(height: 6),
          _buildTestDetail('رزولوشن DNS', result.dnsResolution, Icons.dns),
          const SizedBox(height: 6),
          _buildTestDetail(
            'اتصال HTTPS',
            result.httpsConnectivity,
            Icons.https,
          ),
        ],
      ),
    );
  }

  Widget _buildTestDetail(String label, bool status, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text(
          FormatUtils.formatBooleanEmoji(status),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

/// ویجت نمایش آمار اتصال
class ConnectivityStatsWidget extends StatelessWidget {
  final List<GoogleConnectivityResult> testHistory;

  const ConnectivityStatsWidget({Key? key, required this.testHistory})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (testHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final successCount = testHistory.where((r) => r.overallStatus).length;
    final successRate = (successCount / testHistory.length) * 100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'آمار اتصال',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'تعداد تست',
                testHistory.length.toString(),
                Icons.assessment,
              ),
              _buildStatItem(
                'موفق',
                successCount.toString(),
                Icons.check_circle_outline,
              ),
              _buildStatItem(
                'نرخ موفقیت',
                '${successRate.toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
