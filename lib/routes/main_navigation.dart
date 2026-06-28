import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../di/dependency_injection.dart';
import '../features/dashboard/presentation/screens/dashboard_tab.dart';
import '../features/food/presentation/screens/food_tab.dart';
import '../features/meal/presentation/screens/meal_tab.dart';
import '../features/water/presentation/screens/water_tab.dart';
import '../features/weight/presentation/screens/weight_tab.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/ai_coach/presentation/screens/ai_coach_screen.dart';
import '../features/meal/presentation/cubit/meal_cubit.dart';
import '../features/profile/presentation/cubit/profile_cubit.dart';
import '../features/ai_coach/presentation/cubit/ai_coach_cubit.dart';
import '../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../features/food/presentation/cubit/food_cubit.dart';
import '../features/weight/presentation/cubit/weight_cubit.dart';




class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  int _refreshCounter = 0;
  final _storage = const FlutterSecureStorage();
  String _userName = "User";
  late final DashboardCubit _dashboardCubit;

  static const Color primaryGreen = Color(0xFF006D44);

  @override
  void initState() {
    super.initState();
    _dashboardCubit = getIt<DashboardCubit>()..loadDashboardData();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final name = await _storage.read(key: 'user_name');
    if (mounted && name != null) {
      setState(() => _userName = name);
    }
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      try {
        _dashboardCubit.loadDashboardData(showLoading: false);
      } catch (_) {}
    } else if (index == 2) {
      try {
        MealTab.onReload?.call();
      } catch (_) {}
    } else if (index == 5) {
      try {
        AiCoachScreen.onReload?.call();
      } catch (_) {}
    }
  }

  // Maps raw bottom-nav tap index to actual tab index (AI Coach is center = index 2 visually, but maps to tab 5)
  void _onNavTap(int navIndex) {
    // Nav order: 0=Home, 1=Foods, 2=AI(center), 3=Meals, 4=Water/Weight
    // We show 5 nav items but tab 5 is AI Coach
    // Remap: 0->0, 1->1, 2->5(AI), 3->2(Meals), 4->3(Water)
    const map = [0, 1, 5, 2, 3];
    if (navIndex < map.length) {
      final targetIndex = map[navIndex];
      setState(() => _currentIndex = targetIndex);
      
      // Trigger background reload on navigation
      if (targetIndex == 0) {
        try {
          _dashboardCubit.loadDashboardData(showLoading: false);
        } catch (_) {}
      } else if (targetIndex == 2) {
        try {
          MealTab.onReload?.call();
        } catch (_) {}
      } else if (targetIndex == 5) {
        try {
          AiCoachScreen.onReload?.call();
        } catch (_) {}
      }
    }
  }

  int get _navIndex {
    const reverseMap = {0: 0, 1: 1, 2: 3, 3: 4, 5: 2};
    return reverseMap[_currentIndex] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      DashboardTab(
        key: ValueKey("db_$_refreshCounter"),
        onNavigateToMeals: () => _navigateToTab(2),
        onNavigateToWater: () => _navigateToTab(3),
        onNavigateToWeight: () => _navigateToTab(4),
        onNavigateToAiCoach: () => _navigateToTab(5),
      ),
      BlocProvider<FoodCubit>(
        create: (context) => getIt<FoodCubit>(),
        child: FoodTab(key: ValueKey("food_$_refreshCounter")),
      ),
      BlocProvider<MealCubit>(
        create: (context) => getIt<MealCubit>(),
        child: MealTab(key: ValueKey("meal_$_refreshCounter")),
      ),
      WaterTab(key: ValueKey("water_$_refreshCounter")),
      BlocProvider<WeightCubit>(
        create: (context) => getIt<WeightCubit>(),
        child: WeightTab(key: ValueKey("weight_$_refreshCounter")),
      ),
      BlocProvider<AiCoachCubit>(
        create: (context) => getIt<AiCoachCubit>(),
        child: AiCoachScreen(key: ValueKey("ai_$_refreshCounter")),
      ),
    ];

    return BlocProvider<DashboardCubit>.value(
      value: _dashboardCubit,
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "NutriAI",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF2D3748)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider<ProfileCubit>(
                      create: (context) => getIt<ProfileCubit>(),
                      child: const ProfileScreen(),
                    ),
                  ),
                );
                _loadUserInfo();
                setState(() {
                  _refreshCounter++;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A5568)),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 18, color: primaryGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: _buildBottomNav(),
    ),);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _navItem(0, Icons.dashboard_outlined, Icons.dashboard, "Trang chủ"),
              _navItem(1, Icons.restaurant_menu_outlined, Icons.restaurant_menu, "Món ăn"),
              // Center AI Coach FAB button
              Expanded(
                child: GestureDetector(
                  onTap: () => _onNavTap(2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006D44), Color(0xFF00A86B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: _navIndex == 2
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF006D44).withValues(alpha: 0.5),
                                      blurRadius: 18,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF006D44).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: const Icon(Icons.psychology_alt, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Trợ lý AI",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _navIndex == 2 ? primaryGreen : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _navItem(3, Icons.event_note_outlined, Icons.event_note, "Bữa ăn"),
              _navItem(4, Icons.local_drink_outlined, Icons.local_drink, "Nước"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int navIndex, IconData icon, IconData activeIcon, String label) {
    final isActive = _navIndex == navIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(navIndex),
        behavior: HitTestBehavior.opaque,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? primaryGreen : Colors.grey[500],
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? primaryGreen : Colors.grey[500],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 5 : 0,
                height: isActive ? 5 : 0,
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
