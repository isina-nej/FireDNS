import 'package:flutter/material.dart';
import '../path/path.dart';

/// ویجت نمایش مصرف داده
class DataUsageWidget extends StatelessWidget {
  final int downloadBytes;
  final int uploadBytes;
  final bool showDetails;

  const DataUsageWidget({
    Key? key,
    required this.downloadBytes,
    required this.uploadBytes,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: showDetails ? _buildDetailedView() : _buildSimpleView(),
    );
  }

  Widget _buildSimpleView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.arrow_downward, color: Colors.blue, size: 20),
        const SizedBox(width: 4),
        Text(
          FormatUtils.formatBytes(downloadBytes),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.arrow_upward, color: Colors.orange, size: 20),
        const SizedBox(width: 4),
        Text(
          FormatUtils.formatBytes(uploadBytes),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailedView() {
    final totalBytes = downloadBytes + uploadBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مصرف داده',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // دانلود
        _buildDataRow(
          'دانلود',
          Icons.arrow_downward,
          Colors.blue,
          downloadBytes,
        ),
        const SizedBox(height: 4),

        // آپلود
        _buildDataRow('آپلود', Icons.arrow_upward, Colors.orange, uploadBytes),
        const SizedBox(height: 8),

        // خط جداکننده
        Container(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 8),

        // مجموع
        _buildDataRow('مجموع', Icons.data_usage, Colors.green, totalBytes),
      ],
    );
  }

  Widget _buildDataRow(String label, IconData icon, Color color, int bytes) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text(
          FormatUtils.formatBytes(bytes),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// ویجت نمایش آمار مصرف داده
class DataUsageStatsWidget extends StatelessWidget {
  final List<Map<String, int>> usageHistory;
  final Duration timePeriod;

  const DataUsageStatsWidget({
    Key? key,
    required this.usageHistory,
    this.timePeriod = const Duration(hours: 24),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (usageHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalDownload = usageHistory.fold<int>(
      0,
      (sum, usage) => sum + (usage['download'] ?? 0),
    );

    final totalUpload = usageHistory.fold<int>(
      0,
      (sum, usage) => sum + (usage['upload'] ?? 0),
    );

    final averageDownload = totalDownload / usageHistory.length;
    final averageUpload = totalUpload / usageHistory.length;

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
          Text(
            'آمار مصرف (${FormatUtils.formatDuration(timePeriod)})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // آمار کلی
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'مجموع دانلود',
                FormatUtils.formatBytes(totalDownload),
                Icons.download,
                Colors.blue,
              ),
              _buildStatColumn(
                'مجموع آپلود',
                FormatUtils.formatBytes(totalUpload),
                Icons.upload,
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // آمار میانگین
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'میانگین دانلود',
                FormatUtils.formatBytes(averageDownload.round()),
                Icons.trending_down,
                Colors.blue.shade300,
              ),
              _buildStatColumn(
                'میانگین آپلود',
                FormatUtils.formatBytes(averageUpload.round()),
                Icons.trending_up,
                Colors.orange.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
