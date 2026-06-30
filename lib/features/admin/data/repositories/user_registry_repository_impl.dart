import '../../domain/repositories/user_registry_repository.dart';
import '../datasources/user_registry_remote_data_source.dart';
import '../models/admin_user.dart';

/// Hiện thực [UserRegistryRepository] — ủy quyền cho [UserRegistryRemoteDataSource].
class UserRegistryRepositoryImpl implements UserRegistryRepository {
  final UserRegistryRemoteDataSource remoteDataSource;

  UserRegistryRepositoryImpl(this.remoteDataSource);

  @override
  Future<PaginatedUsers> getUsers({
    int page = 1,
    int pageSize = 8,
    String? search,
    UserStatus? status,
    int? roleId,
  }) {
    return remoteDataSource.fetchUsers(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      roleId: roleId,
    );
  }

  @override
  Future<void> setUserStatus(String id, UserStatus status) {
    return remoteDataSource.setStatus(id, status);
  }

  @override
  Future<void> changeUserRole(String id, int roleId) {
    return remoteDataSource.changeRole(id, roleId);
  }

  @override
  Future<void> deleteUser(String id) {
    return remoteDataSource.deleteUser(id);
  }
}
