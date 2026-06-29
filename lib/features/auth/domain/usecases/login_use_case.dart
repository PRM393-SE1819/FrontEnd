import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<Map<String, dynamic>?, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}
