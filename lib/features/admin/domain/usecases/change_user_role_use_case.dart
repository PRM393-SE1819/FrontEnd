import '../../../../core/usecases/usecase.dart';
import '../repositories/user_registry_repository.dart';

class ChangeUserRoleParams {
  final String id;
  final int roleId;

  const ChangeUserRoleParams({required this.id, required this.roleId});
}

class ChangeUserRoleUseCase implements UseCase<void, ChangeUserRoleParams> {
  final UserRegistryRepository repository;

  const ChangeUserRoleUseCase(this.repository);

  @override
  Future<void> call(ChangeUserRoleParams params) {
    return repository.changeUserRole(params.id, params.roleId);
  }
}
