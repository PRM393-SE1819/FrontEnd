import 'package:flutter/material.dart';

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

/// Tình trạng của một thành phần hệ thống.
enum HealthStatus { operational, degraded, down }

extension HealthStatusX on HealthStatus {
  String get label {
    switch (this) {
      case HealthStatus.operational:
        return "Operational";
      case HealthStatus.degraded:
        return "Degraded";
      case HealthStatus.down:
        return "Down";
    }
  }

  Color get color {
    switch (this) {
      case HealthStatus.operational:
        return const Color(0xFF006D44);
      case HealthStatus.degraded:
        return const Color(0xFFDD6B20);
      case HealthStatus.down:
        return const Color(0xFFE53E3E);
    }
  }

  static HealthStatus fromApi(String? value) {
    switch (value) {
      case "degraded":
        return HealthStatus.degraded;
      case "down":
        return HealthStatus.down;
      default:
        return HealthStatus.operational;
    }
  }
}

/// Một mục trong "System Health". `loadPercent` != null khi hiển thị mức tải.
class HealthIndicator {
  final String name;
  final IconData icon;
  final HealthStatus status;
  final int? loadPercent;

  const HealthIndicator({
    required this.name,
    required this.icon,
    required this.status,
    this.loadPercent,
  });
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

/// Loại sự kiện trong nhật ký bảo mật.
enum LogType { login, system, database }

extension LogTypeX on LogType {
  String get label {
    switch (this) {
      case LogType.login:
        return "Login";
      case LogType.system:
        return "System";
      case LogType.database:
        return "Database";
    }
  }

  Color get color {
    switch (this) {
      case LogType.login:
        return const Color(0xFFE53E3E);
      case LogType.system:
        return const Color(0xFF2B6CB0);
      case LogType.database:
        return const Color(0xFF006D44);
    }
  }

  IconData get icon {
    switch (this) {
      case LogType.login:
        return Icons.login;
      case LogType.system:
        return Icons.memory;
      case LogType.database:
        return Icons.storage;
    }
  }

  static LogType fromApi(String? value) {
    switch (value) {
      case "login":
        return LogType.login;
      case "database":
        return LogType.database;
      default:
        return LogType.system;
    }
  }
}

/// Một dòng trong "Security & System Log".
class SecurityLog {
  final DateTime time;
  final LogType type;
  final String description;

  const SecurityLog({
    required this.time,
    required this.type,
    required this.description,
  });

  factory SecurityLog.fromJson(Map<String, dynamic> json) {
    return SecurityLog(
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      type: LogTypeX.fromApi(json['type'] as String?),
      description: json['description'] as String? ?? '',
    );
  }
}

/// Gói toàn bộ dữ liệu cho màn hình Analytics Overview.
class AnalyticsOverview {
  final List<MetricStat> metrics;
  final List<HealthIndicator> health;
  final ModerationSummary moderation;
  final List<SecurityLog> logs;

  const AnalyticsOverview({
    required this.metrics,
    required this.health,
    required this.moderation,
    required this.logs,
  });
}
