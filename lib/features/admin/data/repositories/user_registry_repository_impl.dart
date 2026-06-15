import '../../domain/repositories/user_registry_repository.dart';
import '../datasources/user_registry_mock_data_source.dart';
import '../models/admin_user.dart';

/// Hiện thực [UserRegistryRepository] — chỉ ủy quyền cho data source.
///
/// Nhận [UserRegistryDataSource] (interface), nên hoạt động được với cả
/// mock lẫn remote. Việc chọn dùng cái nào nằm ở DI.
class UserRegistryRepositoryImpl implements UserRegistryRepository {
  final UserRegistryDataSource dataSource;

  UserRegistryRepositoryImpl(this.dataSource);

  @override
  Future<PaginatedUsers> getUsers({
    int page = 1,
    int pageSize = 8,
    String? search,
    UserStatus? status,
    int? roleId,
  }) {
    return dataSource.fetchUsers(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      roleId: roleId,
    );
  }

  @override
  Future<void> setUserStatus(String id, UserStatus status) {
    return dataSource.setStatus(id, status);
  }

  @override
  Future<void> changeUserRole(String id, int roleId) {
    return dataSource.changeRole(id, roleId);
  }

  @override
  Future<void> deleteUser(String id) {
    return dataSource.deleteUser(id);
  }
}
