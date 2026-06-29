import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  final String token;
  final String newPassword;

  const ResetPasswordParams({required this.token, required this.newPassword});
}

class ResetPasswordUseCase implements UseCase<Map<String, dynamic>?, ResetPasswordParams> {
  final AuthRepository repository;

  const ResetPasswordUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(ResetPasswordParams params) {
    return repository.resetPassword(params.token, params.newPassword);
  }
}
