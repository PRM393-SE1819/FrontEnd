import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String fullName;
  final String username;
  final String email;
  final String password;

  const RegisterParams({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
  });
}

class RegisterUseCase implements UseCase<Map<String, dynamic>?, RegisterParams> {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(RegisterParams params) {
    return repository.register(
      params.fullName,
      params.username,
      params.email,
      params.password,
    );
  }
}
