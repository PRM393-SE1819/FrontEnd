import 'package:flutter/material.dart';
import 'user_registry_screen.dart';
import 'content_moderation_screen.dart';
import 'analytics_overview_screen.dart';

/// Khung điều hướng chính của khu vực Admin.
///
/// Bottom nav gồm 3 nút: Users · Moderation · Analytics.
/// Dùng [IndexedStack] để giữ trạng thái từng tab khi chuyển qua lại.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _navBackground = Color(0xFF1B2A4A);
  static const Color _textDark = Color(0xFF2D3748);

  int _currentIndex = 1; // mặc định mở tab Moderation (theo Figma)

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const UserRegistryScreen(),
      const ContentModerationScreen(),
      // "Review queue" trên dashboard chuyển thẳng sang tab Moderation.
      AnalyticsOverviewScreen(onOpenModeration: () => _goToTab(1)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.spa, color: _primaryGreen, size: 22),
          ),
          const SizedBox(width: 10),
          const Text(
            "NutriAI Admin",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, size: 20, color: _primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _navBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.people_alt_outlined, "Người dùng"),
              _navItem(1, Icons.gavel_outlined, "Kiểm duyệt"),
              _navItem(2, Icons.bar_chart_outlined, "Thống kê"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? _primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Colors.white : Colors.white60,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
