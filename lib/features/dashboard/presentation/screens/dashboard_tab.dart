import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';

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
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // Dashboard Data
  double _caloriesConsumed = 0;
  double _caloriesTarget = 2000;
  double _proteinConsumed = 0;
  double _proteinTarget = 150;
  double _carbConsumed = 0;
  double _carbTarget = 250;
  double _fatConsumed = 0;
  double _fatTarget = 70;

  // Water data snapshot
  double _waterConsumed = 0;
  double _waterGoal = 2000;

  // Weight data snapshot
  double _currentWeight = 0;
  double _targetWeight = 0;

  final Color primaryGreen = const Color(0xFF006D44);
  final Color secondaryAccent = const Color(0xFF319795);
  final Color bgGradientStart = const Color(0xFFF0FDF4);
  final Color bgGradientEnd = const Color(0xFFE6FFFA);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      // 1. Get Daily Nutrition Summary
      final nutritionSummary = await ApiService.getDailyNutritionSummary(dateStr);
      if (nutritionSummary != null) {
        _caloriesConsumed = (nutritionSummary['caloriesConsumed'] as num?)?.toDouble() ?? 0.0;
        _caloriesTarget = (nutritionSummary['caloriesTarget'] as num?)?.toDouble() ?? 2000.0;
        _proteinConsumed = (nutritionSummary['proteinConsumed'] as num?)?.toDouble() ?? 0.0;
        _proteinTarget = (nutritionSummary['proteinTarget'] as num?)?.toDouble() ?? 150.0;
        _carbConsumed = (nutritionSummary['carbConsumed'] as num?)?.toDouble() ?? 0.0;
        _carbTarget = (nutritionSummary['carbTarget'] as num?)?.toDouble() ?? 250.0;
        _fatConsumed = (nutritionSummary['fatConsumed'] as num?)?.toDouble() ?? 0.0;
        _fatTarget = (nutritionSummary['fatTarget'] as num?)?.toDouble() ?? 70.0;
      }

      // 2. Get Daily Water Summary
      final waterSummary = await ApiService.getDailyWaterSummary(dateStr);
      if (waterSummary != null) {
        _waterConsumed = (waterSummary['consumedML'] as num?)?.toDouble() ?? 0.0;
        _waterGoal = (waterSummary['goalML'] as num?)?.toDouble() ?? 2000.0;
      }

      // 3. Get Weight Summary
      final weightSummary = await ApiService.getWeightSummary();
      if (weightSummary != null) {
        _currentWeight = (weightSummary['currentWeight'] as num?)?.toDouble() ?? 0.0;
        _targetWeight = (weightSummary['targetWeight'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final caloriePercent = _caloriesTarget > 0 ? (_caloriesConsumed / _caloriesTarget).clamp(0.0, 1.0) : 0.0;
    final remainingCalories = (_caloriesTarget - _caloriesConsumed).clamp(0.0, double.infinity);

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
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildDateSelector(),
                  const SizedBox(height: 25),
                  _isLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(50.0),
                            child: CircularProgressIndicator(color: primaryGreen),
                          ),
                        )
                      : Column(
                          children: [
                            _buildCalorieCard(caloriePercent, remainingCalories),
                            const SizedBox(height: 20),
                            _buildMacrosCard(),
                            const SizedBox(height: 20),
                            _buildWaterWeightRow(),
                            const SizedBox(height: 20),
                            _buildAiCoachBanner(),
                            const SizedBox(height: 20),
                            _buildQuickActions(),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Dashboard",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
            Text(
              "Track your health and nutrition automatically",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: _loadDashboardData,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            isToday ? "Today, ${DateFormat('MMM dd').format(_selectedDate)}" : DateFormat('EEEE, MMM dd').format(_selectedDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(double caloriePercent, double remainingCalories) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
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
                      "Calories",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3748)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "${_caloriesConsumed.round()}",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryGreen),
                ),
                Text(
                  "kcal consumed of ${_caloriesTarget.round()} kcal goal",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  remainingCalories > 0
                      ? "${remainingCalories.round()} kcal remaining"
                      : "Goal exceeded by ${(_caloriesConsumed - _caloriesTarget).round()} kcal!",
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
                child: CircularProgressIndicator(
                  value: caloriePercent,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade100,
                  color: primaryGreen,
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
                    "of goal",
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

  Widget _buildMacrosCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Macronutrients Summary",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 20),
          _buildMacroRow(
            "Protein",
            _proteinConsumed,
            _proteinTarget,
            Colors.redAccent.shade200,
            "g",
          ),
          const SizedBox(height: 15),
          _buildMacroRow(
            "Carbohydrates",
            _carbConsumed,
            _carbTarget,
            Colors.amber.shade600,
            "g",
          ),
          const SizedBox(height: 15),
          _buildMacroRow(
            "Fats",
            _fatConsumed,
            _fatTarget,
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
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF4A5568)),
            ),
            Text(
              "${consumed.round()}/$target $unit (${(percent * 100).round()}%)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterWeightRow() {
    final waterPercent = _waterGoal > 0 ? (_waterConsumed / _waterGoal).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        // Water summary card
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
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
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
                      const Text("Water Log", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        "${_waterConsumed.round()} / ${_waterGoal.round()} ml",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: waterPercent,
                      color: Colors.blue[600],
                      backgroundColor: Colors.blue.shade50,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Weight progress summary card
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
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
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
                      const Text("Weight summary", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        _currentWeight > 0 ? "$_currentWeight kg" : "-- kg",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _targetWeight > 0 ? "Goal: $_targetWeight kg" : "Goal: -- kg",
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  const Text("View details", style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
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
                    "AI Nutrition Coach",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Get personalized diet advice based on your data",
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
          "Quick Actions",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                Icons.add_shopping_cart,
                "Log Meal",
                Colors.green.shade50,
                Colors.green.shade800,
                widget.onNavigateToMeals,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionBtn(
                Icons.opacity,
                "Log Water",
                Colors.blue.shade50,
                Colors.blue.shade800,
                widget.onNavigateToWater,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionBtn(
                Icons.add_chart,
                "Log Weight",
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
