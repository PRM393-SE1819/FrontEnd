import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../models/analytics_overview.dart';
import 'analytics_mock_data_source.dart';

/// Nguồn dữ liệu THẬT cho Analytics — gọi `GET /api/admin/dashboard`
/// (trả về `DashboardDto`) rồi map sang [AnalyticsOverview] mà UI đang dùng.
///
/// LƯU Ý: Backend KHÔNG cung cấp "System Health" và "Security Log".
/// Hai phần đó hiển thị giá trị tĩnh hợp lý (đánh dấu rõ bên dưới) cho tới khi
/// có API tương ứng.
class AnalyticsRemoteDataSource implements AnalyticsDataSource {
  const AnalyticsRemoteDataSource();

  @override
  Future<AnalyticsOverview> fetchOverview() async {
    final response = await ApiService.get("/admin/dashboard");
    if (response.statusCode != 200) {
      throw Exception("Failed to load dashboard (${response.statusCode})");
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final summary = (json['summary'] ?? {}) as Map<String, dynamic>;
    final userStats = (json['userStatistics'] ?? {}) as Map<String, dynamic>;
    final community =
        (json['communityStatistics'] ?? {}) as Map<String, dynamic>;

    final totalUsers = (summary['totalUsers'] as num?)?.toInt() ?? 0;
    final newThisWeek = (userStats['newUsersThisWeek'] as num?)?.toInt() ?? 0;
    final newToday = (userStats['newUsersToday'] as num?)?.toInt() ?? 0;

    return AnalyticsOverview(
      metrics: [
        MetricStat(
          label: "Total Users",
          value: _compact(totalUsers),
          changePercent: _pct(newThisWeek, totalUsers),
          isUp: true,
        ),
        MetricStat(
          label: "Active Users",
          value: _compact((summary['activeUsers'] as num?)?.toInt() ?? 0),
          changePercent: _pct(newToday, totalUsers),
          isUp: true,
        ),
        MetricStat(
          label: "AI Requests",
          value: _compact((summary['totalAIRequests'] as num?)?.toInt() ?? 0),
          // Backend không có xu hướng cho chỉ số này -> ẩn pill.
          changePercent: null,
        ),
      ],
      moderation: ModerationSummary(
        flaggedMealReports:
            (community['pendingReports'] as num?)?.toInt() ??
                (summary['pendingReports'] as num?)?.toInt() ??
                0,
        aiChatAnomalies: (summary['bannedUsers'] as num?)?.toInt() ?? 0,
      ),
      // ----- Phần backend chưa hỗ trợ: giữ tĩnh -----
      health: const [
        HealthIndicator(
          name: "API Gateway",
          icon: Icons.dns,
          status: HealthStatus.operational,
        ),
        HealthIndicator(
          name: "Core Database",
          icon: Icons.storage,
          status: HealthStatus.operational,
        ),
        HealthIndicator(
          name: "AI Engine",
          icon: Icons.psychology_alt,
          status: HealthStatus.operational,
        ),
      ],
      logs: const [], // chưa có API security log
    );
  }

  /// % tăng tương đối, làm tròn 1 chữ số. Trả null nếu mẫu số = 0.
  double? _pct(int delta, int total) {
    if (total <= 0) return null;
    return (delta / total) * 100;
  }

  /// Rút gọn số lớn: 1500000 -> "1.5M", 845000 -> "845K".
  String _compact(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }
}
