import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailParams {
  final String email;
  final String token;

  const VerifyEmailParams({required this.email, required this.token});
}

class VerifyEmailUseCase implements UseCase<Map<String, dynamic>?, VerifyEmailParams> {
  final AuthRepository repository;

  const VerifyEmailUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(VerifyEmailParams params) {
    return repository.verifyEmail(params.email, params.token);
  }
}
