import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../di/dependency_injection.dart';
import '../../../../routes/main_navigation.dart';
import '../../domain/repositories/auth_repository.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

// Import màn hình Admin Dashboard của bạn
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _obscurePassword = true;

  // Design Tokens (Matching Figma/Stitch design)
  final Color primaryGreen = const Color(0xFF006D44);
  final Color textDark = const Color(0xFF2D3748);
  final Color inputBgColor = const Color(0xFFF7FAFC);

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    bool hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>/-]').hasMatch(password);
    return password.length >= 6 && hasSpecialChar;
  }

  /// Giải mã payload JWT và kiểm tra role có phải "Admin" không.
  /// Backend nhúng role vào claim chuẩn của .NET.
  bool _isAdminToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = parts[1];
      // base64url cần được "pad" cho đủ bội số 4 trước khi decode.
      final normalized = base64Url.normalize(payload);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;
      // Thử cả claim ngắn lẫn claim đầy đủ của .NET.
      final role = decoded['role'] ??
          decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      if (role is List) {
        return role.any((r) => r.toString().toLowerCase() == 'admin');
      }
      return role?.toString().toLowerCase() == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      _showErrorSnackBar("Email không đúng định dạng");
      return;
    }
    if (!_isValidPassword(password)) {
      _showErrorSnackBar("Password phải >= 6 ký tự và có ký tự đặc biệt");
      return;
    }

    // Hiển thị vòng Loading Loading giống hệt thiết kế cũ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: primaryGreen)),
    );

    // Đăng nhập qua API thật. Token JWT chứa role -> dùng để định tuyến
    // Admin vào trang quản trị, người dùng thường vào app chính.
    try {
      final data = await getIt<AuthRepository>().login(email, password);

      if (!mounted) return;
      Navigator.pop(context);

      if (data != null && data['token'] != null) {
        String token = data['token'];
        String name = data['userName'] ?? email.split('@')[0];

        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_name', value: name);
        if (!mounted) return;

        final bool isAdmin = _isAdminToken(token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Chào mừng $name đã đăng nhập!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? const AdminDashboardScreen()
                : const MainNavigationContainer(),
          ),
        );
      } else {
        if (data != null && data['errors'] != null) {
          final errorsMap = data['errors'] as Map<String, dynamic>;
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
          _showErrorSnackBar(data?['message'] ?? "Đăng nhập thất bại");
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tắt loading
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

  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController();
    bool isSendingReset = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Enter your email to receive a reset link."),
                  const SizedBox(height: 15),
                  TextField(
                    controller: emailResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email address",
                      filled: true,
                      fillColor: inputBgColor,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: Colors.grey[600]))
                ),
                ElevatedButton(
                  onPressed: isSendingReset ? null : () async {
                    String email = emailResetController.text.trim();
                    if (!_isValidEmail(email)) {
                      _showErrorSnackBar("Email không hợp lệ");
                      return;
                    }

                    setDialogState(() {
                      isSendingReset = true;
                    });

                    try {
                      final responseData = await getIt<AuthRepository>().requestPasswordReset(email);

                      if (responseData != null) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(responseData['message'] ?? "Vui lòng check email để lấy link reset!"),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          // Navigate to Reset Password Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isSendingReset = false;
                        });
                        _showErrorSnackBar("Lỗi gửi yêu cầu");
                      }
                    } catch (e) {
                      setDialogState(() {
                        isSendingReset = false;
                      });
                      _showErrorSnackBar("Lỗi kết nối server: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: isSendingReset
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Send", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "NutriAI",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: primaryGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Intelligent nutrition, tailored for you.",
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 35),

                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Welcome Back",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                          ),
                        ),
                        const SizedBox(height: 25),

                        Text("Email Address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "you@example.com",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                            filled: true,
                            fillColor: inputBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "••••••••",
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
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text("or continue with", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              _showErrorSnackBar("Chức năng Google đang được phát triển!");
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text("G", style: TextStyle(color: Colors.blue[600], fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Text("Google", style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(color: Colors.grey[700])),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          "Sign Up",
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
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}