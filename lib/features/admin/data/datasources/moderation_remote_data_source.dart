import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';
import '../models/moderation_item.dart';
import 'moderation_mock_data_source.dart';

/// Nguồn dữ liệu THẬT cho Moderation — gọi API qua [ApiService].
///
/// Endpoints:
///   GET  /api/admin/reports            -> mảng report
///   PUT  /api/admin/reports/{id}/status  body: { "status": "Approved" | "Rejected" | "Pending" }
///
/// LƯU Ý: hiện `GET /api/admin/reports` trả mảng rỗng và Swagger không khai báo
/// schema. Map field dựa trên [ModerationItem.fromJson] (phòng thủ). Khi có
/// report thật, chỉ cần chỉnh tên field trong fromJson cho khớp.
class ModerationRemoteDataSource implements ModerationDataSource {
  const ModerationRemoteDataSource();

  Future<List<ModerationItem>> _fetchAll() async {
    final response = await ApiService.get("/admin/reports");
    if (response.statusCode != 200) {
      throw Exception("Failed to load reports (${response.statusCode})");
    }
    final decoded = jsonDecode(response.body);
    final list = decoded is List
        ? decoded
        : (decoded['items'] as List<dynamic>? ?? []);
    return list
        .map((e) => ModerationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ModerationItem>> getQueue() async {
    final all = await _fetchAll();
    return all.where((r) => r.status == ModerationStatus.pending).toList();
  }

  @override
  Future<List<ModerationItem>> getResolved() async {
    final all = await _fetchAll();
    return all.where((r) => r.status != ModerationStatus.pending).toList();
  }

  @override
  Future<void> updateStatus(String id, ModerationStatus status) async {
    final response = await ApiService.put(
      "/admin/reports/$id/status",
      {"status": _toApiStatus(status)},
    );
    if (response.statusCode != 200 && kDebugMode) {
      debugPrint("updateStatus failed: ${response.statusCode} ${response.body}");
    }
  }

  // Backend community statistics dùng Pending/Approved/Rejected.
  // "Escalated" chưa có phía backend -> tạm giữ ở Pending.
  String _toApiStatus(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return "Approved";
      case ModerationStatus.rejected:
        return "Rejected";
      case ModerationStatus.escalated:
      case ModerationStatus.pending:
        return "Pending";
    }
  }
}
