import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>?> login(String email, String password) {
    return remoteDataSource.login(email, password);
  }

  @override
  Future<Map<String, dynamic>?> register(
    String fullName,
    String username,
    String email,
    String password,
  ) {
    return remoteDataSource.register(fullName, username, email, password);
  }

  @override
  Future<Map<String, dynamic>?> verifyEmail(String email, String token) {
    return remoteDataSource.verifyEmail(email, token);
  }

  @override
  Future<Map<String, dynamic>?> resendVerificationEmail(String email) {
    return remoteDataSource.resendVerificationEmail(email);
  }

  @override
  Future<Map<String, dynamic>?> requestPasswordReset(String email) {
    return remoteDataSource.requestPasswordReset(email);
  }

  @override
  Future<Map<String, dynamic>?> resetPassword(String token, String newPassword) {
    return remoteDataSource.resetPassword(token, newPassword);
  }
}
