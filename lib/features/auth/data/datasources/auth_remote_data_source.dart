import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    data['statusCode'] = response.statusCode;
    return data;
  }

  Future<Map<String, dynamic>?> register(
    String fullName,
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "username": username,
        "email": email,
        "password": password,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    data['statusCode'] = response.statusCode;
    return data;
  }

  Future<Map<String, dynamic>?> verifyEmail(String email, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Auth/verify-email?email=${Uri.encodeComponent(email)}&token=${Uri.encodeComponent(token)}"),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    data['statusCode'] = response.statusCode;
    return data;
  }

  Future<Map<String, dynamic>?> resendVerificationEmail(String email) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Auth/resend-verification-email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    data['statusCode'] = response.statusCode;
    return data;
  }

  Future<Map<String, dynamic>?> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Auth/request-password-reset"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    data['statusCode'] = response.statusCode;
    return data;
  }

  Future<Map<String, dynamic>?> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Auth/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token, "newPassword": newPassword}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    data['statusCode'] = response.statusCode;
    return data;
  }
}
