import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResendVerificationEmailUseCase implements UseCase<Map<String, dynamic>?, String> {
  final AuthRepository repository;

  const ResendVerificationEmailUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(String email) {
    return repository.resendVerificationEmail(email);
  }
}
