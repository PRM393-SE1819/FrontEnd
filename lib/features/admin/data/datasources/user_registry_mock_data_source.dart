import '../models/admin_user.dart';

/// Hợp đồng nguồn dữ liệu cho User Registry. Mock và Remote cùng implement
/// interface này, nên đổi giữa hai bên chỉ cần thay 1 dòng trong DI.
abstract class UserRegistryDataSource {
  Future<PaginatedUsers> fetchUsers({
    int page,
    int pageSize,
    String? search,
    UserStatus? status,
    int? roleId,
  });
  Future<void> setStatus(String id, UserStatus status);
  Future<void> changeRole(String id, int roleId);
  Future<void> deleteUser(String id);
}

/// Nguồn dữ liệu GIẢ (mock) cho màn hình User Registry.
///
/// =====================  XÓA KHI CÓ API  =====================
/// File này tạo sẵn 248 user giả để dựng UI (đúng con số trong Figma).
/// Khi backend sẵn sàng:
///   1. Tạo `UserRegistryRemoteDataSource` gọi `ApiService` thật.
///   2. Đổi đăng ký trong `dependency_injection.dart` sang remote.
///   3. Xóa file này.
/// ============================================================
class UserRegistryMockDataSource implements UserRegistryDataSource {
  UserRegistryMockDataSource();

  static const _fakeDelay = Duration(milliseconds: 600);

  // Tạo 1 lần rồi giữ trong bộ nhớ để thao tác suspend/activate có hiệu lực.
  List<AdminUser>? _cache;

  List<AdminUser> get _users => _cache ??= _generateUsers();

  /// Lấy 1 trang user, hỗ trợ tìm kiếm + lọc theo trạng thái/vai trò.
  @override
  Future<PaginatedUsers> fetchUsers({
    int page = 1,
    int pageSize = 8,
    String? search,
    UserStatus? status,
    int? roleId,
  }) async {
    await Future.delayed(_fakeDelay);

    final query = (search ?? '').trim().toLowerCase();
    final filtered = _users.where((u) {
      final matchSearch = query.isEmpty ||
          u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
      final matchStatus = status == null || u.status == status;
      final matchRole = roleId == null || u.role.roleId == roleId;
      return matchSearch && matchStatus && matchRole;
    }).toList();

    final start = (page - 1) * pageSize;
    final items = start >= filtered.length
        ? <AdminUser>[]
        : filtered.sublist(
            start,
            (start + pageSize).clamp(0, filtered.length),
          );

    return PaginatedUsers(
      items: items,
      total: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> setStatus(String id, UserStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users[index] = _users[index].copyWith(status: status);
    }
  }

  @override
  Future<void> changeRole(String id, int roleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      final role = UserRole.values.firstWhere(
        (r) => r.roleId == roleId,
        orElse: () => UserRole.user,
      );
      _users[index] = _users[index].copyWith(role: role);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _users.removeWhere((u) => u.id == id);
  }

  // --------- Dữ liệu giả ---------

  List<AdminUser> _generateUsers() {
    final now = DateTime.now();

    // 4 user đầu khớp với thiết kế Figma.
    final featured = <AdminUser>[
      AdminUser(
        id: "u1",
        name: "Elena Rodriguez",
        email: "e.rodriguez@org",
        role: UserRole.admin,
        status: UserStatus.active,
        lastActive: now.subtract(const Duration(seconds: 20)),
      ),
      AdminUser(
        id: "u2",
        name: "Marcus Chen",
        email: "m.chen@example.com",
        role: UserRole.user,
        status: UserStatus.active,
        lastActive: now.subtract(const Duration(hours: 2)),
      ),
      AdminUser(
        id: "u3",
        name: "Sarah Jenkins",
        email: "s.jenkins@guest.net",
        role: UserRole.guest,
        status: UserStatus.suspended,
        lastActive: DateTime(2023, 10, 12),
      ),
      AdminUser(
        id: "u4",
        name: "David Thompson",
        email: "david@fitness-sync.com",
        role: UserRole.user,
        status: UserStatus.active,
        lastActive: now.subtract(const Duration(days: 1)),
      ),
    ];

    // 244 user còn lại tạo tự động cho đủ 248.
    const firstNames = [
      "James", "Mary", "Robert", "Linda", "Michael", "Patricia", "John",
      "Jennifer", "William", "Liam", "Olivia", "Noah", "Emma", "Ava",
      "Sophia", "Lucas", "Mia", "Ethan", "Isabella", "Mason",
    ];
    const lastNames = [
      "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller",
      "Davis", "Martinez", "Lopez", "Wilson", "Anderson", "Taylor", "Moore",
      "Lee", "Nguyen", "Tran", "Pham", "Kim", "Patel",
    ];
    const roles = [UserRole.user, UserRole.user, UserRole.guest, UserRole.admin];

    final generated = List<AdminUser>.generate(244, (i) {
      final first = firstNames[i % firstNames.length];
      final last = lastNames[(i ~/ firstNames.length) % lastNames.length];
      final isSuspended = i % 11 == 0;
      return AdminUser(
        id: "u${i + 5}",
        name: "$first $last",
        email:
            "${first.toLowerCase()}.${last.toLowerCase()}@example.com",
        role: roles[i % roles.length],
        status: isSuspended ? UserStatus.suspended : UserStatus.active,
        lastActive: now.subtract(Duration(hours: i + 3)),
      );
    });

    return [...featured, ...generated];
  }
}
