import 'package:flutter/material.dart';
import 'package:project_fe/login_screen.dart';
import 'profile_screen.dart';

void main() => runApp(const NutriAIApp());

class NutriAIApp extends StatelessWidget {
  const NutriAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriAI',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.teal,
      ),
      home: LoginScreen(),
    );
  }
}