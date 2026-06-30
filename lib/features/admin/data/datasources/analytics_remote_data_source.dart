import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/analytics_overview.dart';

/// Nguồn dữ liệu cho Analytics — gọi `GET /api/admin/dashboard`
/// (trả về `DashboardDto`) rồi map sang [AnalyticsOverview] mà UI đang dùng.
///
/// Tự gọi HTTP qua [http.Client] inject vào (dễ test/mock), tự đính kèm
/// Bearer token đọc từ [FlutterSecureStorage].
class AnalyticsRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const AnalyticsRemoteDataSource({
    required this.client,
    required this.storage,
  });

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: 'jwt_token');
    return {
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<AnalyticsOverview> fetchOverview() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/admin/dashboard"),
      headers: headers,
    );
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
          label: "Tổng người dùng",
          value: _compact(totalUsers),
          changePercent: _pct(newThisWeek, totalUsers),
          isUp: true,
        ),
        MetricStat(
          label: "Đang hoạt động",
          value: _compact((summary['activeUsers'] as num?)?.toInt() ?? 0),
          changePercent: _pct(newToday, totalUsers),
          isUp: true,
        ),
        MetricStat(
          label: "Yêu cầu AI",
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
