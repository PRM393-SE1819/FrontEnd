import 'package:flutter/material.dart';
import 'di/dependency_injection.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/verify_email_screen.dart';

void main() {
  setupDependencyInjection();
  runApp(const NutriAIApp());
}

class NutriAIApp extends StatelessWidget {
  const NutriAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    String? token;
    String? email;
    bool isVerifyEmailUrl = false;
    bool isResetPasswordUrl = false;

    try {
      final uri = Uri.base;
      token = uri.queryParameters['token'];
      email = uri.queryParameters['email'];
      
      final fullUrlString = uri.toString();
      if (fullUrlString.contains('verify-email')) {
        isVerifyEmailUrl = true;
      } else if (fullUrlString.contains('reset-password') || (token != null && email == null)) {
        isResetPasswordUrl = true;
      }
    } catch (_) {}

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriAI',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF006D44),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D44),
          primary: const Color(0xFF006D44),
        ),
      ),
      home: isVerifyEmailUrl && email != null && token != null
          ? VerifyEmailScreen(email: email, initialToken: token)
          : isResetPasswordUrl && token != null
              ? ResetPasswordScreen(initialToken: token)
              : const LoginScreen(),
    );
  }
}