import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../di/dependency_injection.dart';
import '../../domain/usecases/register_use_case.dart';
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
  
  // Onboarding Wizard steps: 0, 1, 2, 3, 4
  int _currentStep = 0;
  final _storage = const FlutterSecureStorage();

  // Step 1: Health Profile Part 1
  String _gender = "Male";
  DateTime? _dob;

  // Step 2: Health Profile Part 2
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Step 3: Health Profile Part 3
  String _activityLevel = "ModeratelyActive";
  String _goal = "LoseWeight";
  final _targetWeightController = TextEditingController();

  // Step 4: Health Conditions & Allergies
  final _customConditionController = TextEditingController();
  final _customAllergyController = TextEditingController();

  final List<String> _selectedConditions = [];
  final List<String> _selectedAllergies = [];

  final List<String> _commonConditions = ["Diabetes", "Hypertension", "Kidney Disease", "Heart Disease"];
  final List<String> _commonAllergies = ["Peanuts", "Seafood", "Milk", "Eggs", "Gluten", "Soy"];

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Design Tokens (Matching FIGMA / Stitch design)
  final Color primaryGreen = const Color(0xFF006D44);
  final Color textDark = const Color(0xFF2D3748);
  final Color inputBgColor = const Color(0xFFF7FAFC);

  // Password validation helper methods
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

  // Step verification
  bool _validateStep0() {
    return _formKey.currentState?.validate() ?? false;
  }

  bool _validateStep1() {
    if (_dob == null) {
      _showErrorSnackBar("Vui lòng chọn ngày sinh của bạn.");
      return false;
    }
    final age = DateTime.now().year - _dob!.year;
    if (age < 10) {
      _showErrorSnackBar("Bạn phải từ đủ 10 tuổi trở lên để sử dụng ứng dụng.");
      return false;
    }
    if (age > 120) {
      _showErrorSnackBar("Độ tuổi không được vượt quá 120 tuổi.");
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (height < 50 || height > 300) {
      _showErrorSnackBar("Chiều cao phải từ 50cm đến 300cm.");
      return false;
    }
    if (weight < 20 || weight > 500) {
      _showErrorSnackBar("Cân nặng phải từ 20kg đến 500kg.");
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final targetWeightText = _targetWeightController.text.trim();
    if (targetWeightText.isNotEmpty) {
      final targetWeight = double.tryParse(targetWeightText) ?? 0;
      if (targetWeight < 20 || targetWeight > 500) {
        _showErrorSnackBar("Cân nặng mục tiêu phải từ 20kg đến 500kg.");
        return false;
      }
      if (_goal == "LoseWeight" && targetWeight >= weight) {
        _showErrorSnackBar("Với mục tiêu giảm cân, Cân nặng mục tiêu phải NHỎ HƠN Cân nặng hiện tại.");
        return false;
      }
      if (_goal == "GainWeight" && targetWeight <= weight) {
        _showErrorSnackBar("Với mục tiêu tăng cân, Cân nặng mục tiêu phải LỚN HƠN Cân nặng hiện tại.");
        return false;
      }
    }
    return true;
  }

  Future<void> _handleRegister() async {
    String fullName = _fullNameController.text.trim();
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final responseData = await getIt<RegisterUseCase>().call(
        RegisterParams(
          fullName: fullName,
          username: username,
          email: email,
          password: password,
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (responseData != null && responseData['statusCode'] == 200) {
        // Cache the health profile and goals locally
        final profileData = {
          "profile": {
            "gender": _gender,
            "dateOfBirth": "${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}",
            "height": double.parse(_heightController.text),
            "weight": double.parse(_weightController.text),
            "activityLevel": _activityLevel,
            "goal": _goal,
            "targetWeight": _targetWeightController.text.isNotEmpty ? double.parse(_targetWeightController.text) : null,
          },
          "conditions": _selectedConditions.map((c) => {"conditionName": c, "notes": ""}).toList(),
          "allergies": _selectedAllergies.map((a) => {"allergyName": a, "notes": ""}).toList(),
        };

        await _storage.write(key: 'pending_profile_data', value: jsonEncode(profileData));

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

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep0()) return;
    if (_currentStep == 1 && !_validateStep1()) return;
    if (_currentStep == 2 && !_validateStep2()) return;
    if (_currentStep == 3 && !_validateStep3()) return;

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      _handleRegister();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
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
                constraints: const BoxConstraints(maxWidth: 480),
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
                      "Thiết lập tài khoản và kế hoạch dinh dưỡng của bạn",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Onboarding Wizard Card
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
                          // Progress Bar
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _currentStep > 0 ? _prevStep : null,
                                child: Icon(
                                  Icons.arrow_back,
                                  color: _currentStep > 0 ? Colors.grey[700] : Colors.transparent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (_currentStep + 1) / 5,
                                    minHeight: 6,
                                    color: primaryGreen,
                                    backgroundColor: Colors.grey[100],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Bước ${_currentStep + 1}/5",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A5568),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Dynamic Step Content
                          _buildStepContent(),
                          const SizedBox(height: 24),

                          // Navigation Buttons
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _nextStep,
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
                                  : Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          _currentStep == 4 ? "Hoàn tất đăng ký" : "Tiếp tục",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepAccountDetails();
      case 1:
        return _buildStepGenderAndBirthdate();
      case 2:
        return _buildStepPhysicalDetails();
      case 3:
        return _buildStepLifestyleAndGoals();
      case 4:
        return _buildStepHealthConditionsAndAllergies();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 0: Account Details ---
  Widget _buildStepAccountDetails() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Tạo tài khoản mới",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Full Name
          Text(
            "Full Name",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
              if (val.isEmpty) return "Họ và tên không được để trống";
              if (val.length < 2) return "Họ và tên phải có ít nhất 2 ký tự";
              if (val.length > 100) return "Họ và tên không được vượt quá 100 ký tự";
              if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(val)) {
                return "Họ và tên chỉ được chứa chữ cái và khoảng trắng";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Username
          Text(
            "Username",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
              if (val.isEmpty) return "Tên đăng nhập không được để trống";
              if (val.length < 3) return "Tên đăng nhập phải có ít nhất 3 ký tự";
              if (val.length > 50) return "Tên đăng nhập không được vượt quá 50 ký tự";
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) {
                return "Chỉ chứa chữ cái, số và dấu gạch dưới";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          Text(
            "Email Address",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
              if (value == null || value.trim().isEmpty) return "Email không được để trống";
              if (!_isValidEmail(value.trim())) return "Định dạng email không hợp lệ";
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          Text(
            "Password",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
              if (value == null || value.isEmpty) return "Mật khẩu không được để trống";
              if (!_isValidPassword(value)) return "Yêu cầu mật khẩu không thỏa mãn";
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Checklist
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
                  _buildRuleRow("Chỉ dùng ký tự hợp lệ", _hasOnlyAllowedChars(text)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Step 1: Gender & Birthdate ---
  Widget _buildStepGenderAndBirthdate() {
    final formattedDob = _dob != null ? DateFormat('dd/MM/yyyy').format(_dob!) : "Chọn ngày sinh của bạn";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Thông tin cơ bản",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // What's your birthday? Title
        const Text(
          "Ngày sinh của bạn là khi nào?",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 4),
        Text(
          "Chúng tôi cần tuổi của bạn để tính toán lượng calo tiêu thụ hàng ngày chính xác.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        // Birthdate Picker Button
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final selected = await showDatePicker(
              context: context,
              initialDate: _dob ?? now.subtract(const Duration(days: 365 * 25)),
              firstDate: now.subtract(const Duration(days: 365 * 120)),
              lastDate: now,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primaryGreen,
                      onPrimary: Colors.white,
                      onSurface: textDark,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (selected != null) {
              setState(() {
                _dob = selected;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _dob != null ? primaryGreen : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: _dob != null ? primaryGreen : Colors.grey),
                const SizedBox(width: 12),
                Text(
                  formattedDob,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _dob != null ? FontWeight.bold : FontWeight.normal,
                    color: _dob != null ? textDark : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gender Selection
        const Text(
          "Giới tính sinh học",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 4),
        Text(
          "Được sử dụng để ước tính tỷ lệ trao đổi chất cơ bản (BMR).",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildGenderCard("Male", "Nam", Icons.male, Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard("Female", "Nữ", Icons.female, Colors.pink),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(String value, String label, IconData icon, Color activeColor) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? activeColor : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Physical Details ---
  Widget _buildStepPhysicalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Chỉ số cơ thể",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Height
        Text(
          "Chiều cao (cm)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: "Nhập chiều cao của bạn",
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixText: "cm",
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Weight
        Text(
          "Cân nặng hiện tại (kg)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: "Nhập cân nặng của bạn",
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixText: "kg",
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 3: Lifestyle & Goals ---
  Widget _buildStepLifestyleAndGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Lối sống & Mục tiêu",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Activity Level
        const Text(
          "Mức độ hoạt động hàng ngày",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _activityLevel,
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(value: "Sedentary", child: Text("Sedentary (Ít vận động)")),
            DropdownMenuItem(value: "LightlyActive", child: Text("Lightly Active (Nhẹ nhàng)")),
            DropdownMenuItem(value: "ModeratelyActive", child: Text("Moderately Active (Vừa phải)")),
            DropdownMenuItem(value: "VeryActive", child: Text("Very Active (Năng động)")),
            DropdownMenuItem(value: "ExtraActive", child: Text("Extra Active (Cường độ cao)")),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _activityLevel = val;
              });
            }
          },
        ),
        const SizedBox(height: 20),

        // Goals
        const Text(
          "Mục tiêu sức khỏe",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _goal,
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(value: "LoseWeight", child: Text("Lose Weight (Giảm cân)")),
            DropdownMenuItem(value: "MaintainWeight", child: Text("Maintain Weight (Giữ cân)")),
            DropdownMenuItem(value: "GainWeight", child: Text("Gain Weight (Tăng cân)")),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _goal = val;
              });
            }
          },
        ),
        const SizedBox(height: 20),

        // Target Weight
        if (_goal != "MaintainWeight") ...[
          Text(
            "Cân nặng mục tiêu (kg)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: "Nhập cân nặng mục tiêu mong muốn",
              hintStyle: TextStyle(color: Colors.grey[400]),
              suffixText: "kg",
              filled: true,
              fillColor: inputBgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- Step 4: Health Conditions & Allergies ---
  Widget _buildStepHealthConditionsAndAllergies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Sức khỏe & Dị ứng",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Health Conditions
        const Text(
          "Bệnh lý nền của bạn (nếu có)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonConditions.map((condition) {
            final isSelected = _selectedConditions.contains(condition);
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              selectedColor: primaryGreen.withOpacity(0.12),
              checkmarkColor: primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? primaryGreen : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedConditions.add(condition);
                  } else {
                    _selectedConditions.remove(condition);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Custom condition input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customConditionController,
                decoration: InputDecoration(
                  hintText: "Thêm bệnh lý khác...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_circle, color: primaryGreen, size: 32),
              onPressed: () {
                final text = _customConditionController.text.trim();
                if (text.isNotEmpty && !_selectedConditions.contains(text)) {
                  setState(() {
                    _selectedConditions.add(text);
                    _customConditionController.clear();
                  });
                }
              },
            )
          ],
        ),
        const SizedBox(height: 20),

        // Food Allergies
        const Text(
          "Thực phẩm bị dị ứng (nếu có)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonAllergies.map((allergy) {
            final isSelected = _selectedAllergies.contains(allergy);
            return FilterChip(
              label: Text(allergy),
              selected: isSelected,
              selectedColor: primaryGreen.withOpacity(0.12),
              checkmarkColor: primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? primaryGreen : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAllergies.add(allergy);
                  } else {
                    _selectedAllergies.remove(allergy);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Custom allergy input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customAllergyController,
                decoration: InputDecoration(
                  hintText: "Thêm dị ứng khác...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_circle, color: primaryGreen, size: 32),
              onPressed: () {
                final text = _customAllergyController.text.trim();
                if (text.isNotEmpty && !_selectedAllergies.contains(text)) {
                  setState(() {
                    _selectedAllergies.add(text);
                    _customAllergyController.clear();
                  });
                }
              },
            )
          ],
        ),
      ],
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
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _customConditionController.dispose();
    _customAllergyController.dispose();
    super.dispose();
  }
}
