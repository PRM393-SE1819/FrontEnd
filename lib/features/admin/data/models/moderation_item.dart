import 'package:flutter/material.dart';

/// Loại cờ vi phạm bị báo cáo trong hàng đợi kiểm duyệt.
enum ModerationFlagType {
  inaccurateDetection,
  inappropriateAdvice,
  spam,
  other,
}

/// Trạng thái xử lý của một mục kiểm duyệt.
enum ModerationStatus { pending, approved, rejected, escalated }

extension ModerationFlagTypeX on ModerationFlagType {
  /// Nhãn hiển thị trên thẻ (badge).
  String get label {
    switch (this) {
      case ModerationFlagType.inaccurateDetection:
        return "PHÁT HIỆN SAI";
      case ModerationFlagType.inappropriateAdvice:
        return "TƯ VẤN KHÔNG PHÙ HỢP";
      case ModerationFlagType.spam:
        return "SPAM / LẠM DỤNG";
      case ModerationFlagType.other:
        return "KHÁC";
    }
  }

  Color get color {
    switch (this) {
      case ModerationFlagType.inaccurateDetection:
        return const Color(0xFFE53E3E); // đỏ
      case ModerationFlagType.inappropriateAdvice:
        return const Color(0xFF0FA68A); // teal
      case ModerationFlagType.spam:
        return const Color(0xFFDD6B20); // cam
      case ModerationFlagType.other:
        return const Color(0xFF718096); // xám
    }
  }

  IconData get icon {
    switch (this) {
      case ModerationFlagType.inaccurateDetection:
        return Icons.flag;
      case ModerationFlagType.inappropriateAdvice:
        return Icons.warning_amber_rounded;
      case ModerationFlagType.spam:
        return Icons.block;
      case ModerationFlagType.other:
        return Icons.help_outline;
    }
  }

  /// Khóa khớp với giá trị trả về từ API (khi nối API thật).
  static ModerationFlagType fromApi(String? value) {
    switch (value) {
      case "inaccurate_detection":
        return ModerationFlagType.inaccurateDetection;
      case "inappropriate_advice":
        return ModerationFlagType.inappropriateAdvice;
      case "spam":
        return ModerationFlagType.spam;
      default:
        return ModerationFlagType.other;
    }
  }
}

/// Một mục trong hàng đợi kiểm duyệt nội dung.
///
/// `fromJson` đã sẵn sàng cho việc nối API thật — chỉ cần chỉnh tên field
/// cho khớp response từ backend là dùng được.
class ModerationItem {
  final String id;
  final ModerationFlagType flagType;
  final DateTime reportedAt;
  final String? imageUrl;
  final String title;
  final String userHandle;
  final String content;
  final ModerationStatus status;

  const ModerationItem({
    required this.id,
    required this.flagType,
    required this.reportedAt,
    required this.title,
    required this.userHandle,
    required this.content,
    this.imageUrl,
    this.status = ModerationStatus.pending,
  });

  ModerationItem copyWith({ModerationStatus? status}) {
    return ModerationItem(
      id: id,
      flagType: flagType,
      reportedAt: reportedAt,
      imageUrl: imageUrl,
      title: title,
      userHandle: userHandle,
      content: content,
      status: status ?? this.status,
    );
  }

  /// Map từ `GET /api/admin/reports`.
  ///
  /// LƯU Ý: hiện endpoint trả mảng rỗng và không khai báo schema trong Swagger,
  /// nên đây là map PHÒNG THỦ (đọc nhiều tên field khả dĩ). Khi có report thật,
  /// chỉ cần chỉnh lại tên field cho khớp response.
  factory ModerationItem.fromJson(Map<String, dynamic> json) {
    return ModerationItem(
      id: (json['reportId'] ?? json['id'] ?? '').toString(),
      flagType: ModerationFlagTypeX.fromApi(
          (json['reason'] ?? json['flagType'] ?? json['type']) as String?),
      reportedAt: DateTime.tryParse(
              (json['createdAt'] ?? json['reportedAt'] ?? '') as String) ??
          DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
      title: (json['targetType'] ?? json['title'] ?? 'Report') as String,
      userHandle: (json['reporterName'] ??
          json['reportedBy'] ??
          json['userHandle'] ??
          '') as String,
      content: (json['reason'] ??
          json['description'] ??
          json['content'] ??
          '') as String,
      status: _statusFromApi(json['status'] as String?),
    );
  }

  static ModerationStatus _statusFromApi(String? value) {
    switch (value?.toLowerCase()) {
      case "approved":
        return ModerationStatus.approved;
      case "rejected":
        return ModerationStatus.rejected;
      case "escalated":
        return ModerationStatus.escalated;
      default:
        return ModerationStatus.pending;
    }
  }
}
