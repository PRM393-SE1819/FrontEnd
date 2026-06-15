import '../models/system_alert.dart';

/// Nguồn dữ liệu GIẢ (mock) cho màn hình System Alerts.
///
/// =====================  XÓA KHI CÓ API  =====================
/// Khi backend sẵn sàng:
///   1. Tạo `AlertsRemoteDataSource` gọi `ApiService` thật.
///   2. Đổi đăng ký trong `dependency_injection.dart` sang remote.
///   3. Xóa file này.
/// ============================================================
class AlertsMockDataSource {
  AlertsMockDataSource();

  static const _fakeDelay = Duration(milliseconds: 600);

  List<SystemAlert>? _cache;

  List<SystemAlert> get _alerts => _cache ??= _generate();

  Future<List<SystemAlert>> fetchAlerts() async {
    await Future.delayed(_fakeDelay);
    return List.unmodifiable(_alerts);
  }

  Future<void> dismiss(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _alerts.removeWhere((a) => a.id == id);
  }

  List<SystemAlert> _generate() {
    final now = DateTime.now();
    return [
      SystemAlert(
        id: "a1",
        severity: AlertSeverity.critical,
        category: AlertCategory.system,
        title: "API Latency Spike",
        description:
            "Nutrition Analysis API response time exceeded 2500ms for 5% of "
            "requests in the last hour. AI processing queue is backing up.",
        createdAt: now.subtract(const Duration(minutes: 2)),
        actionLabel: "Investigate",
        dismissible: true,
        unread: true,
      ),
      SystemAlert(
        id: "a2",
        severity: AlertSeverity.warning,
        category: AlertCategory.security,
        title: "Anomalous Diet Pattern",
        description:
            "Vitality Core AI detected unusually low caloric intake entries "
            "clustered among 40 new users in the last 24 hours. Potential bot "
            "activity or dangerous trend.",
        createdAt: now.subtract(const Duration(minutes: 15)),
        actionLabel: "View Analysis",
        dismissible: false,
        unread: true,
      ),
      SystemAlert(
        id: "a3",
        severity: AlertSeverity.moderation,
        category: AlertCategory.moderation,
        title: "New Flagged Content",
        description:
            "User reported inappropriate language in community forum post "
            "#48492. Auto-moderation confidence score: 85%.",
        createdAt: now.subtract(const Duration(hours: 1)),
        actionLabel: "Review",
        dismissible: true,
        unread: true,
      ),
      SystemAlert(
        id: "a4",
        severity: AlertSeverity.info,
        category: AlertCategory.system,
        title: "Database Backup Complete",
        description:
            "Routine daily backup of user telemetry and nutrition database "
            "completed successfully to secure cold storage.",
        createdAt: now.subtract(const Duration(hours: 3)),
        actionLabel: "View Logs",
        dismissible: false,
        unread: false,
      ),
    ];
  }
}
