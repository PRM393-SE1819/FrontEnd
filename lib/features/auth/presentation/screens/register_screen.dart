import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Design Tokens (Matching FIGMA / Stitch design)
  final Color primaryGreen = const Color(0xFF006D44);
  final Color textDark = const Color(0xFF2D3748);
  final Color inputBgColor = const Color(0xFFF7FAFC);

  // Password validation: At least 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char (@$!%*?&)
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String fullName = _fullNameController.text.trim();
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final responseData = await getIt<AuthRepository>().register(
        fullName,
        username,
        email,
        password,
      );

      setState(() {
        _isLoading = false;
      });

      if (responseData != null && responseData['statusCode'] == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Đăng ký thành công! Hãy xác thực email.");
        
        // Navigate to OTP Verification Screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(email: email),
            ),
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
          _showErrorSnackBar(responseData?['message'] ?? "Đăng ký thất bại");
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
                    // Logo and Title
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.spa, color: primaryGreen, size: 40),
                        const SizedBox(width: 8),
                        Text(
                          "NutriAI",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: primaryGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create your account to start your journey",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Registration Card
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
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Full Name Field
                            Text(
                              "Full Name",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fullNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: "e.g. Jane Doe",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                final val = value?.trim() ?? "";
                                if (val.isEmpty) {
                                  return "Họ và tên không được để trống";
                                }
                                if (val.length < 2) {
                                  return "Họ và tên phải có ít nhất 2 ký tự";
                                }
                                if (val.length > 100) {
                                  return "Họ và tên không được vượt quá 100 ký tự";
                                }
                                if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(val)) {
                                  return "Họ và tên chỉ được chứa chữ cái và khoảng trắng";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Username Field
                            Text(
                              "Username",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: "e.g. janedoe_99",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.alternate_email, color: Colors.grey),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                final val = value?.trim() ?? "";
                                if (val.isEmpty) {
                                  return "Tên đăng nhập không được để trống";
                                }
                                if (val.length < 3) {
                                  return "Tên đăng nhập phải có ít nhất 3 ký tự";
                                }
                                if (val.length > 50) {
                                  return "Tên đăng nhập không được vượt quá 50 ký tự";
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) {
                                  return "Chỉ chứa chữ cái, số và dấu gạch dưới";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            Text(
                              "Email Address",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: "jane@example.com",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email không được để trống";
                                }
                                if (!_isValidEmail(value.trim())) {
                                  return "Định dạng email không hợp lệ";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            Text(
                              "Password",
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
                            const SizedBox(height: 25),

                            // Sign Up CTA
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
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
                                    : const Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            "Create Account",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Redirect to Login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text("Already have an account? ", style: TextStyle(color: Colors.grey[700])),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            "Log in",
                            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
