import 'package:flutter/material.dart';

/// Nhóm cảnh báo dùng cho bộ lọc (filter chips).
enum AlertCategory { security, system, moderation }

extension AlertCategoryX on AlertCategory {
  String get label {
    switch (this) {
      case AlertCategory.security:
        return "Security";
      case AlertCategory.system:
        return "System";
      case AlertCategory.moderation:
        return "Moderation";
    }
  }

  static AlertCategory fromApi(String? value) {
    switch (value) {
      case "security":
        return AlertCategory.security;
      case "moderation":
        return AlertCategory.moderation;
      default:
        return AlertCategory.system;
    }
  }
}

/// Mức độ nghiêm trọng — quyết định màu sắc và icon của thẻ cảnh báo.
enum AlertSeverity { critical, warning, moderation, info }

extension AlertSeverityX on AlertSeverity {
  Color get color {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFE53E3E);
      case AlertSeverity.warning:
        return const Color(0xFF0FA68A);
      case AlertSeverity.moderation:
        return const Color(0xFF006D44);
      case AlertSeverity.info:
        return const Color(0xFF2B6CB0);
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.critical:
        return Icons.warning_amber_rounded;
      case AlertSeverity.warning:
        return Icons.query_stats;
      case AlertSeverity.moderation:
        return Icons.flag_outlined;
      case AlertSeverity.info:
        return Icons.cloud_done_outlined;
    }
  }

  static AlertSeverity fromApi(String? value) {
    switch (value) {
      case "critical":
        return AlertSeverity.critical;
      case "warning":
        return AlertSeverity.warning;
      case "moderation":
        return AlertSeverity.moderation;
      default:
        return AlertSeverity.info;
    }
  }
}

/// Một cảnh báo hệ thống hiển thị trên màn hình Alerts.
///
/// `fromJson` đã sẵn sàng cho API thật — chỉ cần khớp tên field với backend.
class SystemAlert {
  final String id;
  final AlertSeverity severity;
  final AlertCategory category;
  final String title;
  final String description;
  final DateTime createdAt;
  final String actionLabel;
  final bool dismissible;
  final bool unread;

  const SystemAlert({
    required this.id,
    required this.severity,
    required this.category,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.actionLabel,
    this.dismissible = true,
    this.unread = false,
  });

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: json['id'].toString(),
      severity: AlertSeverityX.fromApi(json['severity'] as String?),
      category: AlertCategoryX.fromApi(json['category'] as String?),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      actionLabel: json['actionLabel'] as String? ?? "View",
      dismissible: json['dismissible'] as bool? ?? true,
      unread: json['unread'] as bool? ?? false,
    );
  }
}
