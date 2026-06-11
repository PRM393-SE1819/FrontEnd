import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;
  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Design Tokens (Matching FIGMA / Stitch design)
  final Color primaryGreen = const Color(0xFF006D44);
  final Color textDark = const Color(0xFF2D3748);
  final Color inputBgColor = const Color(0xFFF7FAFC);

  // Password validation helpers
  bool _hasLength(String text) => text.length >= 8;
  bool _hasUppercase(String text) => RegExp(r'[A-Z]').hasMatch(text);
  bool _hasLowercase(String text) => RegExp(r'[a-z]').hasMatch(text);
  bool _hasDigit(String text) => RegExp(r'\d').hasMatch(text);
  bool _hasSpecialChar(String text) => RegExp(r'[@$!%*?&]').hasMatch(text);
  bool _hasOnlyAllowedChars(String text) => text.isEmpty || RegExp(r'^[A-Za-z\d@$!%*?&]+$').hasMatch(text);

  bool _isValidPassword(String password) {
    return _hasLength(password) &&
        _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasDigit(password) &&
        _hasSpecialChar(password) &&
        _hasOnlyAllowedChars(password);
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
      final responseData = await getIt<AuthRepository>().resetPassword(token, newPassword);

      setState(() {
        _isLoading = false;
      });

      if (responseData != null && responseData['statusCode'] == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Mật khẩu đã được đặt lại thành công!");
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        if (responseData != null && responseData['errors'] != null) {
          final errorsMap = responseData['errors'] as Map<String, dynamic>;
          List<String> allErrors = [];
          errorsMap.forEach((key, val) {
            if (val is List) {
              allErrors.addAll(val.map((e) => e.toString()));
            } else {
              allErrors.add(val.toString());
            }
          });
          _showErrorSnackBar(allErrors.join('\n'));
        } else {
          _showErrorSnackBar(responseData?['message'] ?? "Token không hợp lệ hoặc đã hết hạn");
        }
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
                    // Header Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Icon(Icons.lock_reset, color: primaryGreen, size: 48),
                    ),
                    const SizedBox(height: 25),

                    Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "Enter the verification token sent to your email and your new password.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 35),

                    // Forms Card
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
                            // Token Field
                            Text("Reset Token", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _tokenController,
                              decoration: InputDecoration(
                                hintText: "Paste token received in email",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.key, color: Colors.grey),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Token không được để trống";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // New Password
                            Text("New Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: "Min 6 chars + special char",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                                  return "Mật khẩu không được để trống";
                                }
                                if (!_isValidPassword(value)) {
                                  return "Yêu cầu: >= 8 ký tự, 1 hoa, 1 thường, 1 số, 1 đặc biệt (@\$!%*?&)";
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
                                    _buildRuleRow("Chỉ dùng ký tự hợp lệ (không chứa dấu cách, #, .)", _hasOnlyAllowedChars(text)),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                hintText: "Re-enter new password",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                                        "Reset Password",
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

                    // Back to Login
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, color: primaryGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Back to Login",
                            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? Colors.green[700] : Colors.grey[600],
              ),
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
