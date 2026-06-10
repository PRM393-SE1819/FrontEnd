abstract class AuthRepository {
  Future<Map<String, dynamic>?> login(String email, String password);
  Future<Map<String, dynamic>?> register(
    String fullName,
    String username,
    String email,
    String password,
  );
  Future<Map<String, dynamic>?> verifyEmail(String email, String token);
  Future<Map<String, dynamic>?> resendVerificationEmail(String email);
  Future<Map<String, dynamic>?> requestPasswordReset(String email);
  Future<Map<String, dynamic>?> resetPassword(String token, String newPassword);
}
