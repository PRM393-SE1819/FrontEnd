import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/meal_cubit.dart';
import '../cubit/meal_state.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/food.dart';

class MealTab extends StatefulWidget {
  const MealTab({super.key});

  static void Function()? onReload;

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  final Color primaryGreen = const Color(0xFF006D44);
  final Color secondaryGreen = const Color(0xFFE6FFFA);

  final Map<String, String> mealTypeMap = {
    'Breakfast': 'Bữa sáng',
    'Lunch': 'Bữa trưa',
    'Dinner': 'Bữa tối',
    'Snack': 'Bữa phụ',
  };

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MealCubit>();
    MealTab.onReload = () {
      if (cubit.state is MealLoaded) {
        cubit.loadMealLogs((cubit.state as MealLoaded).selectedDate);
      } else {
        cubit.loadMealLogs(DateTime.now());
      }
    };
    cubit.loadMealLogs(DateTime.now());
  }

  @override
  void dispose() {
    MealTab.onReload = null;
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime currentDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF2D3748),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != currentDate) {
      if (mounted) {
        context.read<MealCubit>().selectDate(picked);
      }
    }
  }

  Future<void> _deleteMeal(int mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa nhật ký bữa ăn"),
        content: const Text("Bạn có chắc chắn muốn xóa nhật ký bữa ăn này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<MealCubit>().deleteMeal(mealId);
    }
  }

  Future<void> _editMealItemQuantity(Meal meal, int foodId, String mealType, String notes, double newQuantity) async {
    final updatedItemsPayload = meal.items.map((item) {
      final quantity = (item.foodId == foodId) ? newQuantity : item.quantity;
      return {
        "foodId": item.foodId,
        "quantity": quantity,
      };
    }).toList();

    final mealData = {
      "mealType": mealType,
      "notes": notes,
      "items": updatedItemsPayload,
    };

    context.read<MealCubit>().updateMeal(meal.mealId, mealData);
  }

  void _showEditItemQuantityDialog(Meal meal, dynamic item) {
    final currentQty = item.quantity;
    final qtyController = TextEditingController(text: currentQty % 1 == 0 ? currentQty.toInt().toString() : currentQty.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Sửa số lượng cho ${item.foodName}"),
        content: TextField(
          controller: qtyController,
          decoration: InputDecoration(
            labelText: "Số lượng (Khẩu phần chuẩn: ${item.servingSize ?? '1 phần'})",
            suffixText: "khẩu phần",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Hủy", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(qtyController.text);
              if (newQty != null && newQty > 0) {
                Navigator.pop(context);
                _editMealItemQuantity(meal, item.foodId, meal.mealType, meal.notes ?? '', newQty);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập số lượng hợp lệ")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAddMealWizard(DateTime selectedDate) {
    String selectedMealType = 'Breakfast';
    final notesController = TextEditingController();
    List<Map<String, dynamic>> mealItems = [];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setWizardState) {
            void searchAndAddFood() {
              final searchController = TextEditingController();
              List<Food> foodResults = [];
              bool searchingFood = true;
              bool initiated = false;

              showDialog(
                context: context,
                builder: (searchCtx) {
                  return StatefulBuilder(
                    builder: (context, setSearchState) {
                      Future<void> performSearch(String query) async {
                        setSearchState(() => searchingFood = true);
                        final cubit = dialogCtx.read<MealCubit>();
                        final results = await cubit.searchFoods(query);
                        final favs = await cubit.getFavoriteFoods();
                        
                        setSearchState(() {
                          final favIds = favs.map((f) => f.foodId).toSet();
                          foodResults = results.map((f) {
                            return Food(
                              foodId: f.foodId,
                              name: f.name,
                              calories: f.calories,
                              protein: f.protein,
                              carbs: f.carbs,
                              fat: f.fat,
                              servingSize: f.servingSize,
                              isCustom: f.isCustom,
                              isFavorite: favIds.contains(f.foodId),
                              foodType: f.foodType,
                            );
                          }).toList();

                          // Sort: Custom foods first, then favorites, then standard
                          foodResults.sort((a, b) {
                            final aCustom = (a.isCustom || a.foodType == 'Custom') ? 1 : 0;
                            final bCustom = (b.isCustom || b.foodType == 'Custom') ? 1 : 0;
                            if (aCustom != bCustom) {
                              return bCustom.compareTo(aCustom);
                            }
                            final aFav = a.isFavorite ? 1 : 0;
                            final bFav = b.isFavorite ? 1 : 0;
                            return bFav.compareTo(aFav);
                          });
                          searchingFood = false;
                        });
                      }

                      if (!initiated) {
                        initiated = true;
                        Future.microtask(() => performSearch(""));
                      }

                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("Tìm món ăn để thêm"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: "Nhập tên món ăn...",
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () => performSearch(searchController.text.trim()),
                                  ),
                                ),
                                onSubmitted: (val) => performSearch(val.trim()),
                              ),
                              const SizedBox(height: 10),
                              searchingFood
                                  ? const Center(child: CircularProgressIndicator())
                                  : SizedBox(
                                      height: 250,
                                      child: foodResults.isEmpty
                                          ? Center(child: Text("Không tìm thấy món ăn nào", style: TextStyle(color: Colors.grey[400])))
                                          : ListView.builder(
                                              itemCount: foodResults.length,
                                              itemBuilder: (context, idx) {
                                                final food = foodResults[idx];
                                                final isFav = food.isFavorite;
                                                final isCustom = food.isCustom || food.foodType == 'Custom';
                                                return ListTile(
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          food.name,
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                      if (isFav)
                                                        const Icon(Icons.star, color: Colors.amber, size: 18),
                                                    ],
                                                  ),
                                                  subtitle: Wrap(
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    spacing: 6,
                                                    children: [
                                                      Text("${food.calories.round()} kcal / ${food.servingSize ?? '100g'}"),
                                                      if (isCustom)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: Colors.teal.shade50,
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.teal.shade200, width: 0.5),
                                                            ),
                                                          child: Text(
                                                            "Tự tạo",
                                                            style: TextStyle(fontSize: 10, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                                                  onTap: () {
                                                    Navigator.pop(searchCtx, food);
                                                  },
                                                );
                                              },
                                            ),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ).then((selectedFood) {
                if (selectedFood != null && selectedFood is Food) {
                  final qtyController = TextEditingController(text: "1");
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Số lượng cho ${selectedFood.name}"),
                      content: TextField(
                        controller: qtyController,
                        decoration: InputDecoration(
                          labelText: "Số lượng (Khẩu phần chuẩn: ${selectedFood.servingSize ?? '1 phần'})",
                          suffixText: "khẩu phần",
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                        ElevatedButton(
                          onPressed: () {
                            final qty = double.tryParse(qtyController.text) ?? 1.0;
                            Navigator.pop(context, qty);
                          },
                          child: const Text("Xác nhận"),
                        ),
                      ],
                    ),
                  ).then((quantity) {
                    if (quantity != null && quantity is double) {
                      final servingSize = selectedFood.servingSize;
                      setWizardState(() {
                        mealItems.add({
                          "foodId": selectedFood.foodId,
                          "name": selectedFood.name,
                          "quantity": quantity,
                          "servingSize": servingSize,
                          "calories": selectedFood.calories * quantity
                        });
                      });
                    }
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Ghi nhận bữa ăn mới", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedMealType,
                        decoration: InputDecoration(
                          labelText: "Loại bữa ăn",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                          return DropdownMenuItem(
                            value: type, 
                            child: Text(mealTypeMap[type] ?? type),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setWizardState(() => selectedMealType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: "Ghi chú bữa ăn (Tùy chọn)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Các món ăn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton.icon(
                            onPressed: searchAndAddFood,
                            icon: const Icon(Icons.add),
                            label: const Text("Thêm món"),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      mealItems.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text("Chưa có món ăn nào được thêm.", style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: mealItems.length,
                              itemBuilder: (context, index) {
                                final item = mealItems[index];
                                return ListTile(
                                  title: Text(item['name'] ?? ''),
                                  subtitle: Text("x${item['quantity'] % 1 == 0 ? (item['quantity'] as num).toInt() : item['quantity']} - ${item['calories'].round()} kcal"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      setWizardState(() {
                                        mealItems.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: mealItems.isEmpty
                      ? null
                      : () {
                          final mealData = {
                            "mealType": selectedMealType,
                            "mealDate": selectedDate.toIso8601String(),
                            "notes": notesController.text.trim(),
                            "items": mealItems.map((item) => {
                              "foodId": item['foodId'],
                              "quantity": item['quantity'],
                            }).toList()
                          };
                          Navigator.pop(dialogCtx);
                          context.read<MealCubit>().addMeal(mealData);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Lưu", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getFormattedDate(DateTime date) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (isToday) {
      return "Hôm nay, ngày ${DateFormat('dd/MM/yyyy').format(date)}";
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
    return "$vietnameseDay, ngày ${DateFormat('dd/MM/yyyy').format(date)}";
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MealCubit, MealState>(
      listener: (context, state) {
        if (state is MealLoaded && state.toastMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.toastMessage!),
              backgroundColor: primaryGreen,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is MealInitial || state is MealLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
            body: Center(child: CircularProgressIndicator(color: primaryGreen)),
          );
        }

        if (state is MealError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
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

        if (state is MealLoaded) {
          final summary = state.summary;
          final meals = state.meals;
          final date = state.selectedDate;

          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
            appBar: AppBar(
              title: const Text(
                "Nhật ký bữa ăn",
                style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: primaryGreen),
                  tooltip: "Thêm bữa ăn",
                  onPressed: () => _openAddMealWizard(date),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: primaryGreen),
                  onPressed: () => _selectDate(context, date),
                ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    _buildDateBanner(date),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            AnimatedFadeSlide(
                              delay: 0,
                              child: _buildDailySummaryCard(
                                summary.caloriesConsumed,
                                summary.caloriesTarget,
                                summary.protein,
                                summary.carbs,
                                summary.fat,
                                summary.remainingCalories,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AnimatedFadeSlide(
                              delay: 100,
                              child: _buildMealHistorySection(meals, date),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
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

  Widget _buildDateBanner(DateTime date) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.read<MealCubit>().changeDate(-1),
          ),
          Text(
            _getFormattedDate(date),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => context.read<MealCubit>().changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard(
    double caloriesConsumed,
    double caloriesTarget,
    double protein,
    double carbs,
    double fat,
    double remaining,
  ) {
    final caloriePercent = caloriesTarget > 0 ? (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tổng hợp dinh dưỡng đã nạp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748))),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${caloriesConsumed.round()}",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
                  ),
                  const Text("Đã nạp (kcal)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${caloriesTarget.round()}",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const Text("Mục tiêu (kcal)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${remaining.round()}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: remaining > 0 ? Colors.green[700] : Colors.redAccent,
                    ),
                  ),
                  const Text("Còn lại (kcal)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: caloriePercent),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  color: primaryGreen,
                  backgroundColor: Colors.grey.shade100,
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroMetric("Đạm (Protein)", "${protein.round()}g"),
              _macroMetric("Tinh bột (Carbs)", "${carbs.round()}g"),
              _macroMetric("Chất béo (Fats)", "${fat.round()}g"),
            ],
          )
        ],
      ),
    );
  }

  Widget _macroMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748))),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildMealHistorySection(List<Meal> meals, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Các bữa ăn đã ghi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: primaryGreen, size: 28),
              onPressed: () => _openAddMealWizard(date),
              tooltip: "Thêm bữa ăn mới",
            ),
          ],
        ),
        const SizedBox(height: 12),
        meals.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.restaurant, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text(
                      "Không có nhật ký bữa ăn nào cho ngày này.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meals.length,
                itemBuilder: (context, idx) {
                  final meal = meals[idx];
                  return AnimatedFadeSlide(
                    delay: (idx * 50).clamp(0, 300),
                    child: _buildMealCard(meal),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    final items = meal.items;
    final mealType = meal.mealType;
    final calories = meal.totalCalories;
    final mealId = meal.mealId;

    IconData typeIcon = Icons.restaurant;
    Color iconColor = primaryGreen;
    if (mealType == 'Breakfast') {
      typeIcon = Icons.wb_sunny_outlined;
      iconColor = Colors.orange;
    } else if (mealType == 'Lunch') {
      typeIcon = Icons.lunch_dining_outlined;
      iconColor = Colors.teal;
    } else if (mealType == 'Dinner') {
      typeIcon = Icons.nightlight_outlined;
      iconColor = Colors.indigo;
    } else if (mealType == 'Snack') {
      typeIcon = Icons.cookie_outlined;
      iconColor = Colors.brown;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(typeIcon, color: iconColor),
        ),
        title: Text(mealTypeMap[mealType] ?? mealType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          "${calories.round()} kcal | ${items.length} món ăn",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _deleteMeal(mealId),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                  Text(
                    "Ghi chú: ${meal.notes}",
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                  const Divider(),
                ],
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item.foodName} (x${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity})",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            "${item.calories.round()} kcal",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _showEditItemQuantityDialog(meal, item);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          )
        ],
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
