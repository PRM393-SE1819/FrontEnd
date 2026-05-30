import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  final Color primaryGreen = const Color(0xFF006D44);
  final Color textDark = const Color(0xFF2D3748);
  final Color inputBgColor = const Color(0xFFF7FAFC);

  Future<void> _handleVerify() async {
    String otpCode = _otpController.text.trim();

    if (otpCode.isEmpty || otpCode.length < 6) {
      _showErrorSnackBar("Vui lòng nhập đầy đủ mã OTP 6 chữ số");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/Auth/verify-email"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otpCode": otpCode,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Xác thực thành công!");
        if (mounted) {
          // Navigate back to Login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        _showErrorSnackBar(responseData['message'] ?? "Xác thực thất bại");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Lỗi kết nối server: $e");
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/Auth/resend-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
        }),
      );

      setState(() {
        _isResending = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Đã gửi lại mã OTP!");
      } else {
        _showErrorSnackBar(responseData['message'] ?? "Không thể gửi lại mã");
      }
    } catch (e) {
      setState(() {
        _isResending = false;
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
                        Icon(Icons.mark_email_read_outlined, color: primaryGreen, size: 40),
                        const SizedBox(width: 8),
                        Text(
                          "Verify Email",
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
                      "We sent a 6-digit verification code to:\n${widget.email}",
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Enter OTP Code",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // OTP Input Field
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "000000",
                              hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 8),
                              filled: true,
                              fillColor: inputBgColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Resend Option
                          Center(
                            child: TextButton(
                              onPressed: _isResending ? null : _handleResendOtp,
                              child: _isResending
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Resend Code",
                                      style: TextStyle(
                                        color: primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleVerify,
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
                                      "Verify & Activate",
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

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
