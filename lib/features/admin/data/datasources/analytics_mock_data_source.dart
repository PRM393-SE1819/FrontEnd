import 'package:flutter/material.dart';
import '../models/analytics_overview.dart';

/// Hợp đồng nguồn dữ liệu cho Analytics. Mock và Remote cùng implement.
abstract class AnalyticsDataSource {
  Future<AnalyticsOverview> fetchOverview();
}

/// Nguồn dữ liệu GIẢ (mock) cho màn hình Analytics Overview.
///
/// =====================  XÓA KHI CÓ API  =====================
/// Khi backend sẵn sàng:
///   1. Tạo `AnalyticsRemoteDataSource` gọi `ApiService` thật.
///   2. Đổi đăng ký trong `dependency_injection.dart` sang remote.
///   3. Xóa file này.
/// ============================================================
class AnalyticsMockDataSource implements AnalyticsDataSource {
  const AnalyticsMockDataSource();

  static const _fakeDelay = Duration(milliseconds: 600);

  @override
  Future<AnalyticsOverview> fetchOverview() async {
    await Future.delayed(_fakeDelay);
    final now = DateTime.now();
    return AnalyticsOverview(
      metrics: const [
        MetricStat(
          label: "Total Users",
          value: "1.2M",
          changePercent: 12.5,
          isUp: true,
        ),
        MetricStat(
          label: "Active Today",
          value: "845K",
          changePercent: 8.3,
          isUp: true,
        ),
        MetricStat(
          label: "AI Scans Today",
          value: "4,209",
          changePercent: 2.1,
          isUp: false,
        ),
      ],
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
          loadPercent: 25,
        ),
      ],
      moderation: const ModerationSummary(
        flaggedMealReports: 24,
        aiChatAnomalies: 7,
      ),
      logs: [
        SecurityLog(
          time: DateTime(now.year, now.month, now.day, 10, 42),
          type: LogType.login,
          description: "Multiple failed admin login attempts",
        ),
        SecurityLog(
          time: DateTime(now.year, now.month, now.day, 9, 15),
          type: LogType.system,
          description: "AI model v3.1 loaded successfully",
        ),
        SecurityLog(
          time: DateTime(now.year, now.month, now.day, 8, 30),
          type: LogType.database,
          description: "Automated encrypted snapshot completed",
        ),
        SecurityLog(
          time: DateTime(now.year, now.month, now.day, 7, 5),
          type: LogType.system,
          description: "Cache cleared by scheduler",
        ),
      ],
    );
  }
}
