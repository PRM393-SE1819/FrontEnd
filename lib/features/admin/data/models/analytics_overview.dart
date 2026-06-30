/// Một chỉ số KPI ở đầu trang (Total Users, Active Today, ...).
class MetricStat {
  final String label;
  final String value;

  /// % thay đổi. `null` khi backend không cung cấp xu hướng -> ẩn pill.
  final double? changePercent;
  final bool isUp;

  const MetricStat({
    required this.label,
    required this.value,
    this.changePercent,
    this.isUp = true,
  });

  factory MetricStat.fromJson(Map<String, dynamic> json) {
    return MetricStat(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      isUp: json['isUp'] as bool? ?? true,
    );
  }
}

/// Tóm tắt hàng đợi kiểm duyệt hiển thị trên dashboard.
class ModerationSummary {
  final int flaggedMealReports;
  final int aiChatAnomalies;

  const ModerationSummary({
    required this.flaggedMealReports,
    required this.aiChatAnomalies,
  });

  factory ModerationSummary.fromJson(Map<String, dynamic> json) {
    return ModerationSummary(
      flaggedMealReports: json['flaggedMealReports'] as int? ?? 0,
      aiChatAnomalies: json['aiChatAnomalies'] as int? ?? 0,
    );
  }
}

/// Gói toàn bộ dữ liệu cho màn hình Analytics Overview.
class AnalyticsOverview {
  final List<MetricStat> metrics;
  final ModerationSummary moderation;

  const AnalyticsOverview({
    required this.metrics,
    required this.moderation,
  });
}
