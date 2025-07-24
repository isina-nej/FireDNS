import 'package:flutter/material.dart';
import '../path/path.dart';


/// ویجت نمایش وضعیت پینگ
class PingBox extends StatelessWidget {
  final DnsStatus? status;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool isLoading;

  const PingBox({
    Key? key,
    this.status,
    this.onTap,
    this.width = AppSizes.pingBoxWidth,
    this.height = AppSizes.pingBoxHeight,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSizes.spaceXS,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: AppSizes.iconS,
                  height: AppSizes.iconS,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.borderMedium,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                )
              : Text(
                  _getDisplayText(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: _getFontSize(),
                  ),
                ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isLoading) return AppColors.statusUnknown;
    return status?.backgroundColor ?? AppColors.backgroundGrey;
  }

  String _getDisplayText() {
    if (isLoading) return '...';
    return status?.displayText ?? '--';
  }

  double _getFontSize() {
    if (status?.isReachable == true) return 14;
    return 12;
  }
}

/// ویجت نمایش وضعیت پینگ با label
class LabeledPingBox extends StatelessWidget {
  final String label;
  final DnsStatus? status;
  final VoidCallback? onTap;
  final bool isLoading;

  const LabeledPingBox({
    Key? key,
    required this.label,
    this.status,
    this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spaceXS),
        PingBox(status: status, onTap: onTap, isLoading: isLoading),
      ],
    );
  }
}

/// ویجت نمایش آمار پینگ
class PingStatsWidget extends StatelessWidget {
  final List<DnsStatus> pingHistory;
  final String dnsAddress;

  const PingStatsWidget({
    Key? key,
    required this.pingHistory,
    required this.dnsAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pingHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final reachablePings = pingHistory.where((p) => p.isReachable).toList();
    final averagePing = reachablePings.isNotEmpty
        ? reachablePings.map((p) => p.ping).reduce((a, b) => a + b) /
              reachablePings.length
        : 0.0;

    final minPing = reachablePings.isNotEmpty
        ? reachablePings.map((p) => p.ping).reduce((a, b) => a < b ? a : b)
        : 0;

    final maxPing = reachablePings.isNotEmpty
        ? reachablePings.map((p) => p.ping).reduce((a, b) => a > b ? a : b)
        : 0;

    final successRate = pingHistory.isNotEmpty
        ? (reachablePings.length / pingHistory.length) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آمار پینگ: $dnsAddress',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('میانگین', '${averagePing.toStringAsFixed(1)} ms'),
              _buildStatItem('حداقل', '$minPing ms'),
              _buildStatItem('حداکثر', '$maxPing ms'),
              _buildStatItem('موفقیت', '${successRate.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: AppSizes.spaceXS),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
