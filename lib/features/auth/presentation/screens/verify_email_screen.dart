import 'package:flutter/material.dart';
import '../../../../di/dependency_injection.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? initialToken;
  const VerifyEmailScreen({super.key, required this.email, this.initialToken});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  // Design Tokens (Matching FIGMA / Stitch design)
  final Color primaryGreen = const Color(0xFF006D44);
  final Color textDark = const Color(0xFF2D3748);
  final Color inputBgColor = const Color(0xFFF7FAFC);

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      // Fill the visual OTP controllers with first characters from token
      for (int i = 0; i < 6; i++) {
        if (i < widget.initialToken!.length) {
          _controllers[i].text = widget.initialToken![i];
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoVerify(widget.initialToken!);
      });
    }
  }

  Future<void> _autoVerify(String token) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final responseData = await getIt<AuthRepository>().verifyEmail(widget.email, token);

      setState(() {
        _isLoading = false;
      });

      if (responseData != null && responseData['statusCode'] == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Xác thực email thành công! Vui lòng đăng nhập.");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        _showErrorSnackBar(responseData?['message'] ?? "Mã xác thực không đúng hoặc đã hết hạn");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Lỗi kết nối server: $e");
    }
  }

  Future<void> _verifyEmail() async {
    String code = _controllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      _showErrorSnackBar("Vui lòng nhập đủ mã xác thực 6 chữ số");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final responseData = await getIt<AuthRepository>().verifyEmail(widget.email, code);

      setState(() {
        _isLoading = false;
      });

      if (responseData != null && responseData['statusCode'] == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Xác thực email thành công! Vui lòng đăng nhập.");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        _showErrorSnackBar(responseData?['message'] ?? "Mã xác thực không đúng hoặc đã hết hạn");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Lỗi kết nối server: $e");
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isResending = true;
    });

    try {
      final responseData = await getIt<AuthRepository>().resendVerificationEmail(widget.email);

      setState(() {
        _isResending = false;
      });

      if (responseData != null && responseData['statusCode'] == 200) {
        _showSuccessSnackBar(responseData['message'] ?? "Đã gửi lại link xác thực mới qua Email!");
      } else {
        _showErrorSnackBar(responseData?['message'] ?? "Gửi lại mã xác thực thất bại");
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
                      child: Icon(Icons.mark_email_unread_outlined, color: primaryGreen, size: 48),
                    ),
                    const SizedBox(height: 25),

                    Text(
                      "Verify Email",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                        children: [
                          const TextSpan(text: "We sent a 6-digit verification code to \n"),
                          TextSpan(
                            text: widget.email,
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
                          ),
                          const TextSpan(text: ". Please enter the code below to activate your account."),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Inputs Card
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
                        children: [
                          // 6 verification digits inputs
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 45,
                                height: 55,
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    filled: true,
                                    fillColor: inputBgColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: primaryGreen, width: 2),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 30),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyEmail,
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
                                      "Verify Account",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Resend Section
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text("Didn't receive the code? ", style: TextStyle(color: Colors.grey[700])),
                              _isResending
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : GestureDetector(
                                      onTap: _resendVerification,
                                      child: Text(
                                        "Resend",
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Redirect back to Login
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
