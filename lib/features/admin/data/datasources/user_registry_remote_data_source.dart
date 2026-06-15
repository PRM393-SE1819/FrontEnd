import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';
import '../models/admin_user.dart';
import 'user_registry_mock_data_source.dart';

/// Nguồn dữ liệu THẬT cho User Registry — gọi API qua [ApiService]
/// (tự đính kèm Bearer token).
///
/// Endpoints:
///   GET    /api/admin/users?Search=&Status=&RoleId=&Page=&PageSize=
///   PUT    /api/admin/users/{id}/status   body: { "status": "Active" | "Banned" }
///   PUT    /api/admin/users/{id}/role     body: { "roleId": 1 | 2 }
///   DELETE /api/admin/users/{id}
class UserRegistryRemoteDataSource implements UserRegistryDataSource {
  const UserRegistryRemoteDataSource();

  @override
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

    final response = await ApiService.get(query.toString());
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

  @override
  Future<void> setStatus(String id, UserStatus status) async {
    // Backend dùng "Active" / "Banned".
    final apiStatus = status == UserStatus.suspended ? "Banned" : "Active";
    final response = await ApiService.put(
      "/admin/users/$id/status",
      {"status": apiStatus},
    );
    if (response.statusCode != 200 && kDebugMode) {
      debugPrint("setStatus failed: ${response.statusCode} ${response.body}");
    }
  }

  @override
  Future<void> changeRole(String id, int roleId) async {
    final response = await ApiService.put(
      "/admin/users/$id/role",
      {"roleId": roleId},
    );
    if (response.statusCode != 200 && kDebugMode) {
      debugPrint("changeRole failed: ${response.statusCode} ${response.body}");
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    final response = await ApiService.delete("/admin/users/$id");
    if (response.statusCode != 200 && response.statusCode != 204 && kDebugMode) {
      debugPrint("deleteUser failed: ${response.statusCode} ${response.body}");
    }
  }
}
