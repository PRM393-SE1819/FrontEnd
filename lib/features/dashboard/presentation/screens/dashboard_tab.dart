import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback onNavigateToMeals;
  final VoidCallback onNavigateToWater;
  final VoidCallback onNavigateToWeight;
  final VoidCallback onNavigateToAiCoach;

  const DashboardTab({
    super.key,
    required this.onNavigateToMeals,
    required this.onNavigateToWater,
    required this.onNavigateToWeight,
    required this.onNavigateToAiCoach,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final Color primaryGreen = const Color(0xFF006D44);
  final Color secondaryAccent = const Color(0xFF319795);
  final Color bgGradientStart = const Color(0xFFF0FDF4);
  final Color bgGradientEnd = const Color(0xFFE6FFFA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboardData();
    });
  }

  String _getFormattedDate(DateTime date) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (isToday) {
      return "Hôm nay, ${DateFormat('dd/MM').format(date)}";
    }
    final weekdayMap = {
      'Monday': 'Thứ Hai',
      'Tuesday': 'Thứ Ba',
      'Wednesday': 'Thứ Tư',
      'Thursday': 'Thứ Năm',
      'Friday': 'Thứ Sáu',
      'Saturday': 'Thứ Bảy',
      'Sunday': 'Chủ Nhật',
    };
    final englishDay = DateFormat('EEEE').format(date);
    final vietnameseDay = weekdayMap[englishDay] ?? englishDay;
    return "$vietnameseDay, ${DateFormat('dd/MM').format(date)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state is DashboardInitial || state is DashboardLoading) {
                return Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                );
              }

              if (state is DashboardError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.read<DashboardCubit>().loadDashboardData(),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                          child: const Text("Tải lại", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is DashboardLoaded) {
                final summary = state.summary;
                final caloriePercent = summary.caloriesTarget > 0 
                    ? (summary.caloriesConsumed / summary.caloriesTarget).clamp(0.0, 1.0) 
                    : 0.0;
                final remainingCalories = (summary.caloriesTarget - summary.caloriesConsumed).clamp(0.0, double.infinity);

                return RefreshIndicator(
                  onRefresh: () => context.read<DashboardCubit>().loadDashboardData(showLoading: false),
                  color: primaryGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedFadeSlide(
                          delay: 0,
                          child: _buildHeader(context),
                        ),
                        const SizedBox(height: 20),
                        AnimatedFadeSlide(
                          delay: 50,
                          child: _buildDateSelector(context, state.selectedDate),
                        ),
                        const SizedBox(height: 25),
                        Column(
                          children: [
                            AnimatedFadeSlide(
                              delay: 100,
                              child: _buildCalorieCard(summary, caloriePercent, remainingCalories),
                            ),
                            const SizedBox(height: 20),
                            AnimatedFadeSlide(
                              delay: 150,
                              child: _buildMacrosCard(summary),
                            ),
                            const SizedBox(height: 20),
                            AnimatedFadeSlide(
                              delay: 200,
                              child: _buildWaterWeightRow(summary),
                            ),
                            const SizedBox(height: 20),
                            AnimatedFadeSlide(
                              delay: 250,
                              child: _buildAiCoachBanner(),
                            ),
                            const SizedBox(height: 20),
                            AnimatedFadeSlide(
                              delay: 300,
                              child: _buildQuickActions(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tổng quan ngày",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
            Text(
              "Theo dõi sức khỏe và dinh dưỡng tự động",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: () => context.read<DashboardCubit>().loadDashboardData(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context, DateTime selectedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            onPressed: () => context.read<DashboardCubit>().changeDate(-1),
          ),
          Text(
            _getFormattedDate(selectedDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () => context.read<DashboardCubit>().changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(DashboardSummary summary, double caloriePercent, double remainingCalories) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Calo tiêu thụ",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3748)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "${summary.caloriesConsumed.round()}",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryGreen),
                ),
                Text(
                  "kcal đã nạp / ${summary.caloriesTarget.round()} kcal mục tiêu",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  remainingCalories > 0
                      ? "Còn lại ${remainingCalories.round()} kcal"
                      : "Vượt quá mục tiêu ${(summary.caloriesConsumed - summary.caloriesTarget).round()} kcal!",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: remainingCalories > 0 ? Colors.green[700] : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: caloriePercent),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade100,
                      color: primaryGreen,
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(caloriePercent * 100).round()}%",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const Text(
                    "đạt được",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMacrosCard(DashboardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tỷ lệ dinh dưỡng",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 20),
          _buildMacroRow(
            "Chất đạm (Protein)",
            summary.proteinConsumed,
            summary.proteinTarget,
            Colors.redAccent.shade200,
            "g",
          ),
          const SizedBox(height: 15),
          _buildMacroRow(
            "Chất bột đường (Carbs)",
            summary.carbConsumed,
            summary.carbTarget,
            Colors.amber.shade600,
            "g",
          ),
          const SizedBox(height: 15),
          _buildMacroRow(
            "Chất béo (Fats)",
            summary.fatConsumed,
            summary.fatTarget,
            Colors.blue.shade400,
            "g",
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String title, double consumed, double target, Color color, String unit) {
    final percent = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF4A5568)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${consumed.round()}/${target.round()} $unit (${(percent * 100).round()}%)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                color: color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaterWeightRow(DashboardSummary summary) {
    final waterPercent = summary.waterGoal > 0 ? (summary.waterConsumed / summary.waterGoal).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: widget.onNavigateToWater,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.local_drink, color: Colors.blue[600], size: 24),
                      Text(
                        "${(waterPercent * 100).round()}%",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[600]),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nước uống", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        "${summary.waterConsumed.round()} / ${summary.waterGoal.round()} ml",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: waterPercent),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          color: Colors.blue[600],
                          backgroundColor: Colors.blue.shade50,
                          minHeight: 6,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: InkWell(
            onTap: widget.onNavigateToWeight,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.monitor_weight_outlined, color: secondaryAccent, size: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Cân nặng", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        summary.currentWeight > 0 ? "${summary.currentWeight} kg" : "-- kg",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        summary.targetWeight > 0 ? "Mục tiêu: ${summary.targetWeight} kg" : "Mục tiêu: -- kg",
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  const Text("Xem chi tiết", style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiCoachBanner() {
    return GestureDetector(
      onTap: widget.onNavigateToAiCoach,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF006D44), Color(0xFF00A86B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006D44).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.psychology_alt, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Trợ lý Dinh dưỡng AI",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Nhận tư vấn dinh dưỡng cá nhân hóa dựa trên dữ liệu của bạn",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Thao tác nhanh",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                Icons.add_shopping_cart,
                "Ghi bữa ăn",
                Colors.green.shade50,
                Colors.green.shade800,
                widget.onNavigateToMeals,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionBtn(
                Icons.opacity,
                "Ghi nước",
                Colors.blue.shade50,
                Colors.blue.shade800,
                widget.onNavigateToWater,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionBtn(
                Icons.add_chart,
                "Ghi cân",
                Colors.teal.shade50,
                Colors.teal.shade800,
                widget.onNavigateToWeight,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String text, Color bg, Color iconColor, VoidCallback onTap) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
      duration: Duration(milliseconds: 600 + delay),
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
