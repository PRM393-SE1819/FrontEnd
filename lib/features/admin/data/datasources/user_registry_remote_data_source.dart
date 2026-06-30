import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/admin_user.dart';

/// Nguồn dữ liệu cho User Registry — tự gọi HTTP qua [http.Client] inject vào
/// (dễ test/mock), tự đính kèm Bearer token đọc từ [FlutterSecureStorage].
///
/// Endpoints:
///   GET    /api/admin/users?Search=&Status=&RoleId=&Page=&PageSize=
///   PUT    /api/admin/users/{id}/status   body: { "status": "Active" | "Banned" }
///   PUT    /api/admin/users/{id}/role     body: { "roleId": 1 | 2 }
///   DELETE /api/admin/users/{id}
class UserRegistryRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const UserRegistryRemoteDataSource({
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

  Future<PaginatedUsers> fetchUsers({
    int page = 1,
    int pageSize = 8,
    String? search,
    UserStatus? status,
    int? roleId,
  }) async {
    final query = StringBuffer("/admin/users?Page=$page&PageSize=$pageSize");
    if (search != null && search.trim().isNotEmpty) {
      query.write("&Search=${Uri.encodeQueryComponent(search.trim())}");
    }
    if (status != null) {
      query.write(
          "&Status=${status == UserStatus.suspended ? "Banned" : "Active"}");
    }
    if (roleId != null) {
      query.write("&RoleId=$roleId");
    }

    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}$query"),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to load users (${response.statusCode})");
    }

    final decoded = jsonDecode(response.body);
    // API trả { items: [...], page, pageSize, totalItems }.
    final items = (decoded['items'] as List<dynamic>? ?? [])
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedUsers(
      items: items,
      total: decoded['totalItems'] as int? ?? items.length,
      page: decoded['page'] as int? ?? page,
      pageSize: decoded['pageSize'] as int? ?? pageSize,
    );
  }

  Future<void> setStatus(String id, UserStatus status) async {
    // Backend dùng "Active" / "Banned".
    final apiStatus = status == UserStatus.suspended ? "Banned" : "Active";
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/admin/users/$id/status"),
      headers: headers,
      body: jsonEncode({"status": apiStatus}),
    );
    if (response.statusCode != 200 && kDebugMode) {
      debugPrint("setStatus failed: ${response.statusCode} ${response.body}");
    }
  }

  Future<void> changeRole(String id, int roleId) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/admin/users/$id/role"),
      headers: headers,
      body: jsonEncode({"roleId": roleId}),
    );
    if (response.statusCode != 200 && kDebugMode) {
      debugPrint("changeRole failed: ${response.statusCode} ${response.body}");
    }
  }

  Future<void> deleteUser(String id) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/admin/users/$id"),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204 && kDebugMode) {
      debugPrint("deleteUser failed: ${response.statusCode} ${response.body}");
    }
  }
}
