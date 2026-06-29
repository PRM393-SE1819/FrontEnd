import '../../../../core/usecases/usecase.dart';
import '../repositories/user_registry_repository.dart';

class DeleteUserUseCase implements UseCase<void, String> {
  final UserRegistryRepository repository;

  const DeleteUserUseCase(this.repository);

  @override
  Future<void> call(String id) {
    return repository.deleteUser(id);
  }
}
