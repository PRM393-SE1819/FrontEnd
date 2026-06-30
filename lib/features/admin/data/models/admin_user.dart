import 'package:flutter/material.dart';

/// Vai trò của người dùng trong hệ thống.
enum UserRole { admin, user, guest }

/// Trạng thái tài khoản.
enum UserStatus { active, suspended }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return "Quản trị";
      case UserRole.user:
        return "Người dùng";
      case UserRole.guest:
        return "Khách";
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFF006D44);
      case UserRole.user:
        return const Color(0xFF2B6CB0);
      case UserRole.guest:
        return const Color(0xFF718096);
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.shield;
      case UserRole.user:
        return Icons.person;
      case UserRole.guest:
        return Icons.visibility_outlined;
    }
  }

  /// roleId gửi lên API (`PUT /admin/users/{id}/role`). Backend: 1=Admin, 2=User.
  int get roleId {
    switch (this) {
      case UserRole.admin:
        return 1;
      case UserRole.user:
        return 2;
      case UserRole.guest:
        return 3;
    }
  }

  /// Khớp với cả `roleName` ("Admin"/"User") lẫn `role` viết thường từ API.
  static UserRole fromApi(String? value) {
    switch (value?.toLowerCase()) {
      case "admin":
        return UserRole.admin;
      case "guest":
        return UserRole.guest;
      default:
        return UserRole.user;
    }
  }
}

extension UserStatusX on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return "Hoạt động";
      case UserStatus.suspended:
        return "Đã khóa";
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.active:
        return const Color(0xFF006D44);
      case UserStatus.suspended:
        return const Color(0xFFE53E3E);
    }
  }

  /// API trả "Active" / "Banned" (hoặc "Suspended"). Mọi giá trị khóa -> suspended.
  static UserStatus fromApi(String? value) {
    final v = value?.toLowerCase() ?? '';
    if (v.contains("ban") || v.contains("suspend") || v.contains("lock")) {
      return UserStatus.suspended;
    }
    return UserStatus.active;
  }
}

/// Một người dùng trong sổ đăng ký (User Registry).
///
/// `fromJson` đã sẵn sàng cho API thật — chỉ cần khớp tên field với backend.
class AdminUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserStatus status;
  final DateTime lastActive;
  final String? avatarUrl;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.lastActive,
    this.avatarUrl,
  });

  /// Chữ cái đầu của tên dùng cho avatar khi không có ảnh. VD: "David Thompson" -> "DT".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  AdminUser copyWith({UserStatus? status, UserRole? role}) {
    return AdminUser(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      status: status ?? this.status,
      lastActive: lastActive,
      avatarUrl: avatarUrl,
    );
  }

  /// Map từ response thật của `GET /api/admin/users`:
  /// `{ userId, fullName, username, email, status, roleId, roleName, createdAt }`.
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['userId'] ?? json['id'] ?? '').toString(),
      name: (json['fullName'] as String?)?.trim().isNotEmpty == true
          ? json['fullName'] as String
          : (json['username'] as String? ?? json['name'] as String? ?? ''),
      email: json['email'] as String? ?? '',
      role: UserRoleX.fromApi(
          json['roleName'] as String? ?? json['role'] as String?),
      status: UserStatusX.fromApi(json['status'] as String?),
      // Backend không có "lastActive" -> dùng tạm createdAt (ngày tạo).
      lastActive:
          DateTime.tryParse(
                  json['lastActive'] as String? ??
                      json['createdAt'] as String? ??
                      '') ??
              DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Kết quả phân trang trả về cho danh sách user.
class PaginatedUsers {
  final List<AdminUser> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedUsers({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil().clamp(1, 1 << 30);

  /// Vị trí bắt đầu hiển thị (1-based) cho dòng "Showing X to Y of Z".
  int get from => total == 0 ? 0 : (page - 1) * pageSize + 1;

  int get to => ((page - 1) * pageSize + items.length);
}
