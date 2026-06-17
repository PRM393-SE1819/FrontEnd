import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _profileExists = false;

  // Profile data
  String _fullName = "Người dùng";
  String _email = "";
  String _gender = "Male";
  DateTime _dob = DateTime.now().subtract(const Duration(days: 365 * 25));
  double _height = 170;
  double _weight = 70;
  String _activityLevel = "ModeratelyActive";
  String _goal = "MaintainWeight";
  double? _targetWeight;

  double _bmi = 0;
  int _caloriesTarget = 2000;

  // Allergies & Conditions lists
  List<dynamic> _allergies = [];
  List<dynamic> _conditions = [];

  final Color primaryGreen = const Color(0xFF006D44);
  final Color bgColor = const Color(0xFFF7FAFC);

  final Map<String, String> genderLabelMap = {
    'Male': 'Nam',
    'Female': 'Nữ',
  };

  final Map<String, String> activityLabelMap = {
    'Sedentary': 'Ít vận động (Văn phòng)',
    'LightlyActive': 'Vận động nhẹ (1-3 ngày/tuần)',
    'ModeratelyActive': 'Vận động vừa (3-5 ngày/tuần)',
    'VeryActive': 'Vận động nhiều (6-7 ngày/tuần)',
    'ExtraActive': 'Vận động rất nhiều (Vận động viên)',
  };

  final Map<String, String> goalLabelMap = {
    'LoseWeight': 'Giảm cân',
    'MaintainWeight': 'Giữ cân',
    'GainWeight': 'Tăng cân',
  };

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getHealthProfile(),
        ApiService.getAllergies(),
        ApiService.getHealthConditions(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final allergiesList = results[1] as List<dynamic>?;
      final conditionsList = results[2] as List<dynamic>?;

      if (profile != null) {
        _profileExists = true;
        _fullName = profile['fullName'] ?? _fullName;
        _email = profile['email'] ?? '';
        _gender = profile['gender'] ?? 'Male';
        if (profile['dateOfBirth'] != null) {
          _dob = DateTime.parse(profile['dateOfBirth']);
        }
        _height = (profile['height'] as num?)?.toDouble() ?? 170.0;
        _weight = (profile['weight'] as num?)?.toDouble() ?? 70.0;
        _activityLevel = profile['activityLevel'] ?? 'ModeratelyActive';
        _goal = profile['goal'] ?? 'MaintainWeight';
        _targetWeight = (profile['targetWeight'] as num?)?.toDouble();
        _bmi = (profile['bmi'] as num?)?.toDouble() ?? 0.0;
        _caloriesTarget = (profile['caloriesTarget'] as num?)?.toInt() ?? 2000;
      } else {
        _profileExists = false;
      }
      _allergies = allergiesList ?? [];
      _conditions = conditionsList ?? [];

      if (_fullName.isNotEmpty) {
        await _storage.write(key: 'user_name', value: _fullName);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditProfileDialog() {
    final genderOptions = ['Male', 'Female'];
    final activityOptions = ['Sedentary', 'LightlyActive', 'ModeratelyActive', 'VeryActive', 'ExtraActive'];
    final goalOptions = ['LoseWeight', 'MaintainWeight', 'GainWeight'];

    String editGender = _gender;
    DateTime editDob = _dob;
    final heightController = TextEditingController(text: _height.toString());
    final weightController = TextEditingController(text: _weight.toString());
    String editActivity = _activityLevel;
    String editGoal = _goal;
    final targetWeightController = TextEditingController(text: _targetWeight?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDob() async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: editDob,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setDialogState(() => editDob = picked);
              }
            }

            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(_profileExists ? "Cập nhật Hồ sơ Sức khỏe" : "Khởi tạo Hồ sơ"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: editGender,
                    decoration: const InputDecoration(labelText: "Giới tính"),
                    items: genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(genderLabelMap[g] ?? g))).toList(),
                    onChanged: (val) => setDialogState(() => editGender = val!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Ngày sinh: ${DateFormat('dd/MM/yyyy').format(editDob)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: selectDob,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: heightController,
                    decoration: const InputDecoration(labelText: "Chiều cao (cm)", suffixText: "cm"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: "Cân nặng (kg)", suffixText: "kg"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: editActivity,
                    decoration: const InputDecoration(labelText: "Mức độ hoạt động"),
                    items: activityOptions.map((a) => DropdownMenuItem(value: a, child: Text(activityLabelMap[a] ?? a))).toList(),
                    onChanged: (val) => setDialogState(() => editActivity = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: editGoal,
                    decoration: const InputDecoration(labelText: "Mục tiêu"),
                    items: goalOptions.map((g) => DropdownMenuItem(value: g, child: Text(goalLabelMap[g] ?? g))).toList(),
                    onChanged: (val) => setDialogState(() => editGoal = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetWeightController,
                    decoration: const InputDecoration(labelText: "Cân nặng mục tiêu (kg)", suffixText: "kg"),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () async {
                    final h = double.tryParse(heightController.text) ?? 170.0;
                    final w = double.tryParse(weightController.text) ?? 70.0;
                    final tw = double.tryParse(targetWeightController.text);

                    // Client validation
                    if (editGoal == 'LoseWeight' && tw != null && tw >= w) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cân nặng mục tiêu phải nhỏ hơn hiện tại để Giảm cân")));
                      return;
                    }
                    if (editGoal == 'GainWeight' && tw != null && tw <= w) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cân nặng mục tiêu phải lớn hơn hiện tại để Tăng cân")));
                      return;
                    }

                    final data = {
                      "gender": editGender,
                      "dateOfBirth": DateFormat('yyyy-MM-dd').format(editDob),
                      "height": h,
                      "weight": w,
                      "activityLevel": editActivity,
                      "goal": editGoal,
                      "targetWeight": tw,
                    };

                    Navigator.pop(context); // Close edit dialog

                    // Optimistic update: apply values and calculate targets instantly
                    setState(() {
                      _gender = editGender;
                      _dob = editDob;
                      _height = h;
                      _weight = w;
                      _activityLevel = editActivity;
                      _goal = editGoal;
                      _targetWeight = tw;
                      _profileExists = true;

                      // Local calculations for instant feedback
                      _bmi = w / ((h / 100) * (h / 100));
                      
                      double bmr = 0;
                      final age = DateTime.now().year - _dob.year;
                      if (_gender == 'Male') {
                        bmr = 10 * w + 6.25 * h - 5 * age + 5;
                      } else {
                        bmr = 10 * w + 6.25 * h - 5 * age - 161;
                      }
                      
                      double factor = 1.2;
                      if (editActivity == 'LightlyActive') factor = 1.375;
                      else if (editActivity == 'ModeratelyActive') factor = 1.55;
                      else if (editActivity == 'VeryActive') factor = 1.725;
                      else if (editActivity == 'ExtraActive') factor = 1.9;
                      
                      double tdee = bmr * factor;
                      if (editGoal == 'LoseWeight') {
                        _caloriesTarget = (tdee - 500).round();
                      } else if (editGoal == 'GainWeight') {
                        _caloriesTarget = (tdee + 500).round();
                      } else {
                        _caloriesTarget = tdee.round();
                      }
                    });

                    // Fire the API call in background
                    ApiService.updateHealthProfile(data).then((success) {
                      if (success) {
                        _loadProfileData(showLoader: false);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Không thể đồng bộ hồ sơ với máy chủ. Vui lòng thử lại."),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    });

                    // Instantly notify success
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Đã cập nhật hồ sơ sức khỏe thành công!"),
                        backgroundColor: primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                  child: const Text("Lưu", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAddAllergyDialog({Map<String, dynamic>? existing}) {
    final nameController = TextEditingController(text: existing?['allergyName'] ?? '');
    final notesController = TextEditingController(text: existing?['notes'] ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Sửa dị ứng thực phẩm' : 'Thêm dị ứng thực phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên loại dị ứng *'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Triệu chứng / Ghi chú'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              bool success;
              if (isEdit) {
                success = await ApiService.updateAllergy(existing!['allergyId'], name);
              } else {
                success = await ApiService.addAllergy(name, notesController.text.trim());
              }
              if (success) _loadProfileData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: Text(isEdit ? 'Cập nhật' : 'Thêm', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _openAddConditionDialog({Map<String, dynamic>? existing}) {
    final nameController = TextEditingController(text: existing?['conditionName'] ?? '');
    final notesController = TextEditingController(text: existing?['notes'] ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Sửa tình trạng bệnh lý' : 'Thêm tình trạng bệnh lý'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên bệnh lý *'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Mức độ / Ghi chú'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              bool success;
              if (isEdit) {
                success = await ApiService.updateHealthCondition(
                    existing!['healthConditionId'], name, notesController.text.trim());
              } else {
                success = await ApiService.addHealthCondition(name, notesController.text.trim());
              }
              if (success) _loadProfileData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: Text(isEdit ? 'Cập nhật' : 'Thêm', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Hồ sơ Sức khỏe',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  AnimatedFadeSlide(
                    delay: 0,
                    child: _buildProfileHeader(),
                  ),
                  const SizedBox(height: 25),
                  if (!_profileExists) ...[
                    AnimatedFadeSlide(
                      delay: 100,
                      child: _buildNoProfileBanner(),
                    ),
                  ] else ...[
                    AnimatedFadeSlide(
                      delay: 100,
                      child: _buildMetricsGrid(),
                    ),
                    const SizedBox(height: 25),
                    AnimatedFadeSlide(
                      delay: 150,
                      child: _buildAllergiesCard(),
                    ),
                    const SizedBox(height: 25),
                    AnimatedFadeSlide(
                      delay: 200,
                      child: _buildConditionsCard(),
                    ),
                  ],
                  const SizedBox(height: 35),
                  AnimatedFadeSlide(
                    delay: 250,
                    child: _buildLogoutButton(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 45,
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(Icons.person, size: 50, color: Color(0xFF006D44)),
        ),
        const SizedBox(height: 12),
        Text(
          _fullName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        if (_email.isNotEmpty)
          Text(
            _email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _openEditProfileDialog,
          icon: const Icon(Icons.edit, size: 16, color: Colors.white),
          label: Text(_profileExists ? "Sửa thông tin sức khỏe" : "Khởi tạo hồ sơ", style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildNoProfileBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 40),
          const SizedBox(height: 12),
          Text(
            "Chưa có hồ sơ sức khỏe",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber.shade900),
          ),
          const SizedBox(height: 8),
          const Text(
            "Vui lòng nhập chiều cao, cân nặng, mức độ vận động và mục tiêu để hệ thống tính toán thực đơn dinh dưỡng tối ưu cho bạn.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF5A6270)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCell("Chiều cao", "${_height.round()} cm"),
              _metricCell("Cân nặng", "${_weight.toStringAsFixed(1)} kg"),
              _metricCell("Chỉ số BMI", _bmi.toStringAsFixed(1)),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCell("Giới tính", genderLabelMap[_gender] ?? _gender),
              _metricCell("Tuổi", "${DateTime.now().year - _dob.year} tuổi"),
              _metricCell("Mục tiêu Calo ngày", "$_caloriesTarget kcal"),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCell("Mục tiêu cân nặng", goalLabelMap[_goal] ?? _goal),
              _metricCell("Cân nặng đích", _targetWeight != null ? "${_targetWeight!.toStringAsFixed(1)} kg" : "-- kg"),
              _metricCell("Hoạt động", activityLabelMap[_activityLevel] != null ? activityLabelMap[_activityLevel]!.split(' (')[0] : _activityLevel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dị ứng thực phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: Icon(Icons.add, color: primaryGreen), onPressed: () => _openAddAllergyDialog()),
            ],
          ),
          const SizedBox(height: 10),
          _allergies.isEmpty
              ? Text("Không có ghi nhận dị ứng thực phẩm nào.", style: TextStyle(color: Colors.grey[500], fontSize: 13))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allergies.length,
                  itemBuilder: (context, idx) {
                    final item = _allergies[idx];
                    final allergyId = item['allergyId'];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text(item['allergyName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item['notes'] ?? 'Không có chi tiết triệu chứng'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: primaryGreen, size: 20),
                            onPressed: () => _openAddAllergyDialog(existing: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final success = await ApiService.deleteAllergy(allergyId);
                              if (success) _loadProfileData();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  Widget _buildConditionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tình trạng bệnh lý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: Icon(Icons.add, color: primaryGreen), onPressed: () => _openAddConditionDialog()),
            ],
          ),
          const SizedBox(height: 10),
          _conditions.isEmpty
              ? Text("Không có ghi nhận tình trạng bệnh lý nào.", style: TextStyle(color: Colors.grey[500], fontSize: 13))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _conditions.length,
                  itemBuilder: (context, idx) {
                    final item = _conditions[idx];
                    final conditionId = item['healthConditionId'];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.favorite_border, color: Colors.redAccent),
                      title: Text(item['conditionName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item['notes'] ?? 'Không có ghi chú'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: primaryGreen, size: 20),
                            onPressed: () => _openAddConditionDialog(existing: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final success = await ApiService.deleteHealthCondition(conditionId);
                              if (success) _loadProfileData();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            String? token = await _storage.read(key: 'jwt_token');
            if (token != null) {
              await ApiService.post("/Auth/logout", null);
            }
          } catch (e) {
            debugPrint("Logout error: $e");
          }

          await _storage.deleteAll();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

class AnimatedFadeSlide extends StatelessWidget {
  final Widget child;
  final int delay;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 15),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
