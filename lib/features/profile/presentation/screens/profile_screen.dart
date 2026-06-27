import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    context.read<ProfileCubit>().loadProfileData();
  }

  void _openEditProfileDialog({
    required bool profileExists,
    required String currentGender,
    required DateTime currentDob,
    required double currentHeight,
    required double currentWeight,
    required String currentActivity,
    required String currentGoal,
    double? currentTargetWeight,
  }) {
    final genderOptions = ['Male', 'Female'];
    final activityOptions = ['Sedentary', 'LightlyActive', 'ModeratelyActive', 'VeryActive', 'ExtraActive'];
    final goalOptions = ['LoseWeight', 'MaintainWeight', 'GainWeight'];

    String editGender = currentGender;
    DateTime editDob = currentDob;
    final heightController = TextEditingController(text: currentHeight.toString());
    final weightController = TextEditingController(text: currentWeight.toString());
    String editActivity = currentActivity;
    String editGoal = currentGoal;
    final targetWeightController = TextEditingController(text: currentTargetWeight?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogStateCtx, setDialogState) {
            Future<void> selectDob() async {
              final DateTime? picked = await showDatePicker(
                context: dialogStateCtx,
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
              title: Text(profileExists ? "Cập nhật Hồ sơ Sức khỏe" : "Khởi tạo Hồ sơ"),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: "Cân nặng (kg)", suffixText: "kg"),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    final h = double.tryParse(heightController.text) ?? 170.0;
                    final w = double.tryParse(weightController.text) ?? 70.0;
                    final tw = double.tryParse(targetWeightController.text);

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

                    Navigator.pop(dialogCtx); // Close dialog
                    context.read<ProfileCubit>().updateHealthProfile(data);
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

  void _openAddAllergyDialog({dynamic existing}) {
    final nameController = TextEditingController(text: existing?.allergyName ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogCtx);
              if (isEdit) {
                context.read<ProfileCubit>().updateAllergy(existing.allergyId, name);
              } else {
                context.read<ProfileCubit>().addAllergy(name, notesController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: Text(isEdit ? 'Cập nhật' : 'Thêm', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _openAddConditionDialog({dynamic existing}) {
    final nameController = TextEditingController(text: existing?.conditionName ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogCtx);
              if (isEdit) {
                context.read<ProfileCubit>().updateHealthCondition(existing.healthConditionId, name, notesController.text.trim());
              } else {
                context.read<ProfileCubit>().addHealthCondition(name, notesController.text.trim());
              }
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
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          if (state.toastMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.toastMessage!),
                backgroundColor: primaryGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.logoutSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator(color: primaryGreen)),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            ),
          );
        }

        if (state is ProfileLoaded) {
          final userProfile = state.userProfile;
          final profileExists = userProfile != null;

          final fullName = userProfile?.fullName ?? "Người dùng";
          final email = userProfile?.email ?? "";
          final gender = userProfile?.gender ?? "Male";
          final dob = userProfile?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25));
          final height = userProfile?.height ?? 170.0;
          final weight = userProfile?.weight ?? 70.0;
          final activityLevel = userProfile?.activityLevel ?? "ModeratelyActive";
          final goal = userProfile?.goal ?? "MaintainWeight";
          final targetWeight = userProfile?.targetWeight;
          final bmi = userProfile?.bmi ?? 0.0;
          final caloriesTarget = userProfile?.caloriesTarget ?? 2000;

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
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      AnimatedFadeSlide(
                        delay: 0,
                        child: _buildProfileHeader(profileExists, fullName, email, gender, dob, height, weight, activityLevel, goal, targetWeight),
                      ),
                      const SizedBox(height: 25),
                      if (!profileExists) ...[
                        AnimatedFadeSlide(
                          delay: 100,
                          child: _buildNoProfileBanner(),
                        ),
                      ] else ...[
                        AnimatedFadeSlide(
                          delay: 100,
                          child: _buildMetricsGrid(height, weight, bmi, gender, dob, caloriesTarget, goal, targetWeight, activityLevel),
                        ),
                        const SizedBox(height: 25),
                        AnimatedFadeSlide(
                          delay: 150,
                          child: _buildAllergiesCard(state.allergies),
                        ),
                        const SizedBox(height: 25),
                        AnimatedFadeSlide(
                          delay: 200,
                          child: _buildConditionsCard(state.conditions),
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
                if (state.isOperationLoading)
                  Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileHeader(
    bool profileExists,
    String fullName,
    String email,
    String gender,
    DateTime dob,
    double height,
    double weight,
    String activityLevel,
    String goal,
    double? targetWeight,
  ) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 45,
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(Icons.person, size: 50, color: Color(0xFF006D44)),
        ),
        const SizedBox(height: 12),
        Text(
          fullName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        if (email.isNotEmpty)
          Text(
            email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _openEditProfileDialog(
            profileExists: profileExists,
            currentGender: gender,
            currentDob: dob,
            currentHeight: height,
            currentWeight: weight,
            currentActivity: activityLevel,
            currentGoal: goal,
            currentTargetWeight: targetWeight,
          ),
          icon: const Icon(Icons.edit, size: 16, color: Colors.white),
          label: Text(profileExists ? "Sửa thông tin sức khỏe" : "Khởi tạo hồ sơ", style: const TextStyle(color: Colors.white)),
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

  Widget _buildMetricsGrid(
    double height,
    double weight,
    double bmi,
    String gender,
    DateTime dob,
    int caloriesTarget,
    String goal,
    double? targetWeight,
    String activityLevel,
  ) {
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
              _metricCell("Chiều cao", "${height.round()} cm"),
              _metricCell("Cân nặng", "${weight.toStringAsFixed(1)} kg"),
              _metricCell("Chỉ số BMI", bmi.toStringAsFixed(1)),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCell("Giới tính", genderLabelMap[gender] ?? gender),
              _metricCell("Tuổi", "${DateTime.now().year - dob.year} tuổi"),
              _metricCell("Mục tiêu Calo ngày", "$caloriesTarget kcal"),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCell("Mục tiêu cân nặng", goalLabelMap[goal] ?? goal),
              _metricCell("Cân nặng đích", targetWeight != null ? "${targetWeight.toStringAsFixed(1)} kg" : "-- kg"),
              _metricCell("Hoạt động", activityLabelMap[activityLevel] != null ? activityLabelMap[activityLevel]!.split(' (')[0] : activityLevel),
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

  Widget _buildAllergiesCard(List<dynamic> allergies) {
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
          allergies.isEmpty
              ? Text("Không có ghi nhận dị ứng thực phẩm nào.", style: TextStyle(color: Colors.grey[500], fontSize: 13))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allergies.length,
                  itemBuilder: (context, idx) {
                    final item = allergies[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text(item.allergyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.notes ?? 'Không có chi tiết triệu chứng'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: primaryGreen, size: 20),
                            onPressed: () => _openAddAllergyDialog(existing: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => context.read<ProfileCubit>().deleteAllergy(item.allergyId),
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

  Widget _buildConditionsCard(List<dynamic> conditions) {
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
          conditions.isEmpty
              ? Text("Không có ghi nhận tình trạng bệnh lý nào.", style: TextStyle(color: Colors.grey[500], fontSize: 13))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: conditions.length,
                  itemBuilder: (context, idx) {
                    final item = conditions[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.favorite_border, color: Colors.redAccent),
                      title: Text(item.conditionName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.notes ?? 'Không có ghi chú'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: primaryGreen, size: 20),
                            onPressed: () => _openAddConditionDialog(existing: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => context.read<ProfileCubit>().deleteHealthCondition(item.healthConditionId),
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
        onPressed: () => context.read<ProfileCubit>().logout(),
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
