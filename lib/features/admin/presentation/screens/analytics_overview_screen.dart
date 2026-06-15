import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../data/models/analytics_overview.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Màn hình "Analytics Overview" — dashboard tổng quan cho admin.
///
/// Dữ liệu lấy qua [AnalyticsRepository] (hiện là mock). Gồm các section:
/// chỉ số KPI, System Health, System Controls, Moderation Queue, Security Log.
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
        content: Text("$label (coming soon)"),
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
          _sectionTitle("System Health", onRefresh: _loadData),
          const SizedBox(height: 12),
          _healthSection(data.health),
          const SizedBox(height: 20),
          _sectionTitle("System Controls", trailingIcon: Icons.settings),
          const SizedBox(height: 12),
          _controlsSection(),
          const SizedBox(height: 20),
          _sectionTitle("Moderation Queue"),
          const SizedBox(height: 12),
          _moderationSection(data.moderation),
          const SizedBox(height: 20),
          _sectionTitle("Security & System Log",
              trailingText: "See All", onTrailingTap: () => _notImplemented("Full log")),
          const SizedBox(height: 12),
          _logSection(data.logs),
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
          "Analytics Overview",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "System status and key metrics for today.",
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

  // ---------- System Health ----------

  Widget _healthSection(List<HealthIndicator> items) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map(_healthGauge).toList(),
      ),
    );
  }

  Widget _healthGauge(HealthIndicator item) {
    final hasLoad = item.loadPercent != null;
    final value = hasLoad ? item.loadPercent! / 100 : 1.0;
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(item.status.color),
                ),
              ),
              hasLoad
                  ? Text(
                      "${item.loadPercent}%",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: item.status.color,
                      ),
                    )
                  : Icon(item.icon, size: 22, color: item.status.color),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasLoad ? "Processing Load" : item.status.label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ---------- System Controls ----------

  Widget _controlsSection() {
    final controls = [
      (Icons.cleaning_services_outlined, "Clear Cache"),
      (Icons.receipt_long_outlined, "Request Logs"),
      (Icons.backup_outlined, "Backup Now"),
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
            "Flagged Meal Reports",
            summary.flaggedMealReports,
          ),
          const Divider(height: 24),
          _moderationRow(
            Icons.smart_toy_outlined,
            const Color(0xFFDD6B20),
            "AI Chat Anomalies",
            summary.aiChatAnomalies,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onOpenModeration ??
                  () => _notImplemented("Review queue"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Review queue",
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

  // ---------- Security log ----------

  Widget _logSection(List<SecurityLog> logs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: _cardDecoration(),
      child: logs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.event_note_outlined,
                      size: 36, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    "No recent system events",
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < logs.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey[100]),
                  _logRow(logs[i]),
                ],
              ],
            ),
    );
  }

  Widget _logRow(SecurityLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(log.type.icon, size: 18, color: log.type.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatTime(log.time),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.type.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: log.type.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.description,
                  style: const TextStyle(fontSize: 13, color: _textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helpers ----------

  Widget _sectionTitle(
    String title, {
    IconData? trailingIcon,
    String? trailingText,
    VoidCallback? onRefresh,
    VoidCallback? onTrailingTap,
  }) {
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
        if (onRefresh != null)
          InkWell(
            onTap: onRefresh,
            child: Icon(Icons.refresh, size: 20, color: Colors.grey[500]),
          )
        else if (trailingIcon != null)
          Icon(trailingIcon, size: 20, color: Colors.grey[500])
        else if (trailingText != null)
          InkWell(
            onTap: onTrailingTap,
            child: Text(
              trailingText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _primaryGreen,
              ),
            ),
          ),
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
      "Monday", "Tuesday", "Wednesday", "Thursday",
      "Friday", "Saturday", "Sunday",
    ];
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];
    return "${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}";
  }

  String _formatTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? "AM" : "PM";
    final minute = t.minute.toString().padLeft(2, '0');
    return "$hour12:$minute $period";
  }
}
