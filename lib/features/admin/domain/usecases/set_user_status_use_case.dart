import '../../../../core/usecases/usecase.dart';
import '../../data/models/admin_user.dart';
import '../repositories/user_registry_repository.dart';

class SetUserStatusParams {
  final String id;
  final UserStatus status;

  const SetUserStatusParams({required this.id, required this.status});
}

class SetUserStatusUseCase implements UseCase<void, SetUserStatusParams> {
  final UserRegistryRepository repository;

  const SetUserStatusUseCase(this.repository);

  @override
  Future<void> call(SetUserStatusParams params) {
    return repository.setUserStatus(params.id, params.status);
  }
}
