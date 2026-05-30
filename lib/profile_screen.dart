import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();

  // 1. Các biến trạng thái để hứng dữ liệu từ Database
  bool _isLoading = true;
  String _userName = "Loading...";
  String _userRole = "Nutrition Enthusiast";
  String _height = "--";
  String _currentWeight = "--";
  String _targetWeight = "--";
  String _activityLevel = "--";
  double _goalProgress = 0.0;
  String _progressText = "0%";

  final Color primaryGreen = const Color(0xFF006D44);
  final Color bgColor = const Color(0xFFF7FAFC);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Lấy tên tạm từ lúc đăng nhập để hiện lên cho nhanh
    String? name = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _userName = name ?? "User";
      });
    }

    await _fetchUserProfile();
  }

  // 2. HÀM CHUẨN BỊ SẴN CHO DATABASE
  Future<void> _fetchUserProfile() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      /* // === KHI NÀO BE CÓ DATABASE & API, HÃY BỎ COMMENT ĐOẠN NÀY ===

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/User/profile"), // Thay bằng Link API thật
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Gửi token để xác thực
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _userName = data['fullName'] ?? _userName;
            _height = "${data['height'] ?? '--'} cm";
            _currentWeight = "${data['weight'] ?? '--'} kg";
            _targetWeight = "${data['targetWeight'] ?? '--'} kg";
            _activityLevel = data['activityLevel'] ?? '--';

            // Tính toán % tiến độ nếu có số liệu thực
            if (data['weight'] != null && data['targetWeight'] != null && data['startWeight'] != null) {
               // Logic tính % của bạn ở đây...
            }
            _isLoading = false;
          });
        }
      } else {
        // Xử lý lỗi token hết hạn v.v..
      }
      */

      // === ĐOẠN NÀY ĐỂ TEST TẠM KHI CHƯA CÓ API, CÓ API THÌ XÓA ĐI ===
      await Future.delayed(const Duration(seconds: 1)); // Giả lập mạng chậm
      if (mounted) {
        setState(() {
          _height = "172 cm";
          _currentWeight = "68.5 kg";
          _targetWeight = "65.0 kg";
          _activityLevel = "Moderate";
          _goalProgress = 0.75;
          _progressText = "75%";
          _isLoading = false;
        });
      }
      // ==============================================================

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Lỗi lấy Profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
            'My Profile',
            style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold, fontSize: 22)
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: primaryGreen),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen)) // Hiện loading xoay xoay khi đang lấy Data
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildGoalCard(),
              const SizedBox(height: 25),
              Row(
                children: [
                  // 3. Truyền Biến vào UI thay vì gõ chữ
                  Expanded(child: _buildSmallMetricCard(Icons.height, "Height", _height)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSmallMetricCard(Icons.monitor_weight_outlined, "Weight", _currentWeight)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSmallMetricCard(Icons.directions_run, "Activity", _activityLevel)),
                ],
              ),
              const SizedBox(height: 30),
              _buildMenuOption(Icons.person_outline, "Edit Profile"),
              _buildMenuOption(Icons.restaurant_menu, "Dietary Preferences"),
              _buildMenuOption(Icons.notifications_none, "Notifications"),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      String? token = await _storage.read(key: 'jwt_token');
                      if (token != null) {
                        await http.post(
                          Uri.parse("${ApiConfig.baseUrl}/Auth/logout"),
                          headers: {
                            "Content-Type": "application/json",
                            "Authorization": "Bearer $token",
                          },
                        );
                      }
                    } catch (e) {
                      debugPrint("Backend logout failed: $e");
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen, width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFE0F2F1),
                child: Icon(Icons.person, size: 55, color: Color(0xFF006D44)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF006D44),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
            )
          ],
        ),
        const SizedBox(height: 15),
        Text(
            _userName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))
        ),
        const SizedBox(height: 5),
        Text(
            _userRole,
            style: TextStyle(fontSize: 14, color: Colors.grey[600])
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.track_changes, color: primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  const Text("Health Goals", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3748))),
                ],
              ),
              Text(_progressText, style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: _goalProgress,
                minHeight: 10,
                color: primaryGreen,
                backgroundColor: Colors.grey.shade200
            ),
          ),
          const SizedBox(height: 15),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_currentWeight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Target", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_targetWeight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF006D44))),
                  ],
                ),
              ]
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 28),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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

  Widget _buildMenuOption(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2D3748))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}