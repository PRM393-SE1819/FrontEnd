import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../data/models/analytics_overview.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Màn hình "Analytics Overview" — dashboard tổng quan cho admin.
///
/// Dữ liệu lấy qua [AnalyticsRepository] (API `GET /api/admin/dashboard`).
/// Gồm các section: chỉ số KPI, System Controls, Moderation Queue.
class AnalyticsOverviewScreen extends StatefulWidget {
  /// Gọi khi bấm "Review queue" -> chuyển sang tab Moderation của shell.
  final VoidCallback? onOpenModeration;

  const AnalyticsOverviewScreen({super.key, this.onOpenModeration});

  @override
  State<AnalyticsOverviewScreen> createState() =>
      _AnalyticsOverviewScreenState();
}

class _AnalyticsOverviewScreenState extends State<AnalyticsOverviewScreen> {
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF2D3748);

  final AnalyticsRepository _repo = getIt<AnalyticsRepository>();

  AnalyticsOverview? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getOverview();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  void _notImplemented(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label (sắp ra mắt)"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primaryGreen));
    }
    final data = _data!;
    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ...data.metrics.map(_metricCard),
          const SizedBox(height: 8),
          _sectionTitle("Điều khiển hệ thống", trailingIcon: Icons.settings),
          const SizedBox(height: 12),
          _controlsSection(),
          const SizedBox(height: 20),
          _sectionTitle("Hàng đợi kiểm duyệt"),
          const SizedBox(height: 12),
          _moderationSection(data.moderation),
        ],
      ),
    );
  }

  // ---------- Header ----------

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tổng quan thống kê",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Tình trạng hệ thống và chỉ số chính hôm nay.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(DateTime.now()),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // ---------- Metric cards ----------

  Widget _metricCard(MetricStat metric) {
    final trendColor =
        metric.isUp ? _primaryGreen : const Color(0xFFE53E3E);
    final change = metric.changePercent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
          if (change != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    metric.isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${change.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------- System Controls ----------

  Widget _controlsSection() {
    final controls = [
      (Icons.cleaning_services_outlined, "Xóa bộ nhớ đệm"),
      (Icons.receipt_long_outlined, "Yêu cầu nhật ký"),
      (Icons.backup_outlined, "Sao lưu ngay"),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: controls.map((c) {
          return InkWell(
            onTap: () => _notImplemented(c.$2),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(c.$1, color: _primaryGreen, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.$2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- Moderation summary ----------

  Widget _moderationSection(ModerationSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _moderationRow(
            Icons.flag,
            const Color(0xFFE53E3E),
            "Báo cáo bữa ăn bị gắn cờ",
            summary.flaggedMealReports,
          ),
          const Divider(height: 24),
          _moderationRow(
            Icons.smart_toy_outlined,
            const Color(0xFFDD6B20),
            "Bất thường trò chuyện AI",
            summary.aiChatAnomalies,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onOpenModeration ??
                  () => _notImplemented("Xem hàng đợi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Xem hàng đợi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moderationRow(IconData icon, Color color, String label, int count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$count",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Helpers ----------

  Widget _sectionTitle(String title, {IconData? trailingIcon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        if (trailingIcon != null)
          Icon(trailingIcon, size: 20, color: Colors.grey[500]),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const weekdays = [
      "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm",
      "Thứ Sáu", "Thứ Bảy", "Chủ Nhật",
    ];
    return "${weekdays[d.weekday - 1]}, ngày ${d.day} tháng ${d.month} năm ${d.year}";
  }
}
