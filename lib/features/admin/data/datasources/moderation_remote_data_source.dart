import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/moderation_item.dart';

/// Nguồn dữ liệu cho Moderation — tự gọi HTTP qua [http.Client] inject vào.
///
/// Endpoints:
///   GET  /api/admin/reports            -> mảng report
///   PUT  /api/admin/reports/{id}/status  body: { "status": "Approved" | "Rejected" | "Pending" }
class ModerationRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const ModerationRemoteDataSource({
    required this.client,
    required this.storage,
  });

  Future<Map<String, String>> _getHeaders({bool hasBody = false}) async {
    final token = await storage.read(key: 'jwt_token');
    final headers = <String, String>{};
    if (hasBody) {
      headers["Content-Type"] = "application/json";
    }
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Future<List<ModerationItem>> _fetchAll() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/admin/reports"),
      headers: headers,
    );
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

  Future<List<ModerationItem>> getQueue() async {
    final all = await _fetchAll();
    return all.where((r) => r.status == ModerationStatus.pending).toList();
  }

  Future<List<ModerationItem>> getResolved() async {
    final all = await _fetchAll();
    return all.where((r) => r.status != ModerationStatus.pending).toList();
  }

  Future<void> updateStatus(String id, ModerationStatus status) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/admin/reports/$id/status"),
      headers: headers,
      body: jsonEncode({"status": _toApiStatus(status)}),
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
