import '../../data/models/admin_user.dart';

/// Hợp đồng (interface) cho dữ liệu User Registry.
///
/// Hiện được hiện thực bằng remote (API thật) hoặc mock — chọn ở DI.
abstract class UserRegistryRepository {
  /// Lấy 1 trang user, hỗ trợ tìm kiếm + lọc theo trạng thái/vai trò.
  Future<PaginatedUsers> getUsers({
    int page,
    int pageSize,
    String? search,
    UserStatus? status,
    int? roleId,
  });

  /// Đổi trạng thái tài khoản (Active <-> Suspended/Banned).
  Future<void> setUserStatus(String id, UserStatus status);

  /// Đổi vai trò (roleId: 1=Admin, 2=User).
  Future<void> changeUserRole(String id, int roleId);

  /// Xóa tài khoản người dùng.
  Future<void> deleteUser(String id);
}
