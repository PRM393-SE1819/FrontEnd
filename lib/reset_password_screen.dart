import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF006D44);
  final Color textDark = const Color(0xFF2D3748);
  final Color inputBgColor = const Color(0xFFF7FAFC);

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
    }
  }

  // Password validation: At least 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char (@$!%*?&)
  bool _hasLength(String text) => text.length >= 8;
  bool _hasUppercase(String text) => RegExp(r'[A-Z]').hasMatch(text);
  bool _hasLowercase(String text) => RegExp(r'[a-z]').hasMatch(text);
  bool _hasDigit(String text) => RegExp(r'\d').hasMatch(text);
  bool _hasSpecialChar(String text) => RegExp(r'[@$!%*?&]').hasMatch(text);

  bool _isValidPassword(String password) {
    return _hasLength(password) &&
        _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasDigit(password) &&
        _hasSpecialChar(password);
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String token = _tokenController.text.trim();
    String newPassword = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/Auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "newPassword": newPassword,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Đặt lại mật khẩu thành công!");
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        _showErrorSnackBar(responseData['message'] ?? "Không thể đặt lại mật khẩu");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Lỗi kết nối server: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2F1),
              Color(0xFFF3E5F5),
              Color(0xFFE3F2FD),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_reset, color: primaryGreen, size: 44),
                        const SizedBox(width: 8),
                        Text(
                          "Reset Password",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: primaryGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your reset token and your new password below.",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                "Create New Password",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Token Field
                            Text(
                              "Reset Token",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _tokenController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: "Paste token from email link",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.grey),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Mã xác thực/token không được để trống";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // New Password Field
                            Text(
                              "New Password",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: "••••••••",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Mật khẩu mới không được để trống";
                                }
                                if (!_isValidPassword(value)) {
                                  return "Mật khẩu yếu. Vui lòng xem yêu cầu bên dưới.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Password requirements visual helper
                            AnimatedBuilder(
                              animation: _passwordController,
                              builder: (context, child) {
                                final text = _passwordController.text;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRuleRow("Tối thiểu 8 ký tự", _hasLength(text)),
                                    _buildRuleRow("Chứa chữ hoa (A-Z)", _hasUppercase(text)),
                                    _buildRuleRow("Chứa chữ thường (a-z)", _hasLowercase(text)),
                                    _buildRuleRow("Chứa số (0-9)", _hasDigit(text)),
                                    _buildRuleRow("Chứa ký tự đặc biệt (@\$!%*?&)", _hasSpecialChar(text)),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            Text(
                              "Confirm New Password",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                hintText: "••••••••",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return "Mật khẩu xác nhận không khớp";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 25),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleResetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Save New Password",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Back to Login Link
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        "Back to Sign In",
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey[400],
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
