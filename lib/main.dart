import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

void main() => runApp(const NutriAIApp());

class NutriAIApp extends StatelessWidget {
  const NutriAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the query parameter 'token' from the URL (extremely useful for Flutter Web password resets)
    String? resetToken;
    try {
      resetToken = Uri.base.queryParameters['token'];
    } catch (_) {
      // In case Uri.base is not supported or throws on some platforms
    }

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
      home: resetToken != null
          ? ResetPasswordScreen(initialToken: resetToken)
          : const LoginScreen(),
    );
  }
}