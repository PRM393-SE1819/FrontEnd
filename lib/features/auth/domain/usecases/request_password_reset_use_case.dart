import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase implements UseCase<Map<String, dynamic>?, String> {
  final AuthRepository repository;

  const RequestPasswordResetUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(String email) {
    return repository.requestPasswordReset(email);
  }
}
