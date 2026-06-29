import '../../../../core/usecases/usecase.dart';
import '../../data/models/admin_user.dart';
import '../repositories/user_registry_repository.dart';

class GetUsersParams {
  final int page;
  final int pageSize;
  final String? search;
  final UserStatus? status;
  final int? roleId;

  const GetUsersParams({
    required this.page,
    required this.pageSize,
    this.search,
    this.status,
    this.roleId,
  });
}

class GetUsersUseCase implements UseCase<PaginatedUsers, GetUsersParams> {
  final UserRegistryRepository repository;

  const GetUsersUseCase(this.repository);

  @override
  Future<PaginatedUsers> call(GetUsersParams params) {
    return repository.getUsers(
      page: params.page,
      pageSize: params.pageSize,
      search: params.search,
      status: params.status,
      roleId: params.roleId,
    );
  }
}
