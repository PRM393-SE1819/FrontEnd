import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';

class MealTab extends StatefulWidget {
  const MealTab({super.key});

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Daily Summary data
  double _caloriesConsumed = 0;
  double _caloriesTarget = 2000;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;
  double _remaining = 2000;

  // Meals list
  List<dynamic> _meals = [];

  final Color primaryGreen = const Color(0xFF006D44);
  final Color secondaryGreen = const Color(0xFFE6FFFA);

  @override
  void initState() {
    super.initState();
    _loadMealLogs();
  }

  Future<void> _loadMealLogs() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      // 1. Get Daily Summary
      final summary = await ApiService.getDailyCaloriesSummary(dateStr);
      if (summary != null) {
        _caloriesConsumed = (summary['caloriesConsumed'] as num?)?.toDouble() ?? 0.0;
        _caloriesTarget = (summary['caloriesTarget'] as num?)?.toDouble() ?? 2000.0;
        _protein = (summary['protein'] as num?)?.toDouble() ?? 0.0;
        _carbs = (summary['carbs'] as num?)?.toDouble() ?? 0.0;
        _fat = (summary['fat'] as num?)?.toDouble() ?? 0.0;
        _remaining = (summary['remainingCalories'] as num?)?.toDouble() ?? 2000.0;
      }

      // 2. Get Meal History for selected date
      final history = await ApiService.getMealHistory(date: dateStr);
      if (history != null) {
        _meals = history['items'] ?? [];
      }
    } catch (e) {
      debugPrint("Error loading meals: $e");
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
    _loadMealLogs();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMealLogs();
    }
  }

  Future<void> _deleteMeal(int mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Meal Log"),
        content: const Text("Are you sure you want to delete this meal log?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteMeal(mealId);
      if (success) {
        _loadMealLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meal deleted successfully")),
        );
      }
    }
  }

  void _openAddMealWizard() {
    String selectedMealType = 'Breakfast';
    final notesController = TextEditingController();
    List<Map<String, dynamic>> mealItems = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setWizardState) {
            void searchAndAddFood() {
              final searchController = TextEditingController();
              List<dynamic> foodResults = [];
              bool searchingFood = true;
              bool initiated = false;

              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setSearchState) {
                      if (!initiated) {
                        initiated = true;
                        Future.microtask(() async {
                          final results = await ApiService.searchFoods("");
                          final favs = await ApiService.getFavoriteFoods() ?? [];
                          setSearchState(() {
                            final List<dynamic> loaded = results != null ? results['items'] ?? [] : [];
                            final favIds = favs.map((f) => f['foodId']).toSet();
                            for (var f in loaded) {
                              f['isFavorite'] = favIds.contains(f['foodId']);
                            }
                            // Sort favorites to the top
                            loaded.sort((a, b) {
                              final aFav = a['isFavorite'] == true ? 1 : 0;
                              final bFav = b['isFavorite'] == true ? 1 : 0;
                              return bFav.compareTo(aFav);
                            });
                            foodResults = loaded;
                            searchingFood = false;
                          });
                        });
                      }

                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("Search Food to Add"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: "Type food name...",
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () async {
                                      setSearchState(() => searchingFood = true);
                                      final results = await ApiService.searchFoods(searchController.text.trim());
                                      final favs = await ApiService.getFavoriteFoods() ?? [];
                                      setSearchState(() {
                                        final List<dynamic> loaded = results != null ? results['items'] ?? [] : [];
                                        final favIds = favs.map((f) => f['foodId']).toSet();
                                        for (var f in loaded) {
                                          f['isFavorite'] = favIds.contains(f['foodId']);
                                        }
                                        foodResults = loaded;
                                        searchingFood = false;
                                      });
                                    },
                                  ),
                                ),
                                onSubmitted: (val) async {
                                  setSearchState(() => searchingFood = true);
                                  final results = await ApiService.searchFoods(val.trim());
                                  final favs = await ApiService.getFavoriteFoods() ?? [];
                                  setSearchState(() {
                                    final List<dynamic> loaded = results != null ? results['items'] ?? [] : [];
                                    final favIds = favs.map((f) => f['foodId']).toSet();
                                    for (var f in loaded) {
                                      f['isFavorite'] = favIds.contains(f['foodId']);
                                    }
                                    foodResults = loaded;
                                    searchingFood = false;
                                  });
                                },
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
                                                final isFav = food['isFavorite'] == true;
                                                final isCustom = food['isCustom'] == true || food['foodType'] == 'Custom';
                                                return ListTile(
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          food['name'] ?? '',
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
                                                      Text("${food['calories']} kcal / ${food['servingSize'] ?? '100g'}"),
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
                                                    Navigator.pop(context, food);
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
                if (selectedFood != null && selectedFood is Map) {
                  final qtyController = TextEditingController(text: "100");
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Quantity for ${selectedFood['name']}"),
                      content: TextField(
                        controller: qtyController,
                        decoration: const InputDecoration(
                          labelText: "Weight (grams / servings)",
                          suffixText: "g",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        ElevatedButton(
                          onPressed: () {
                            final qty = double.tryParse(qtyController.text) ?? 100.0;
                            Navigator.pop(context, qty);
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  ).then((quantity) {
                    if (quantity != null && quantity is double) {
                      setWizardState(() {
                        mealItems.add({
                          "foodId": selectedFood['foodId'],
                          "name": selectedFood['name'],
                          "quantity": quantity,
                          "calories": (selectedFood['calories'] as num).toDouble() * (quantity / 100.0)
                        });
                      });
                    }
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Log New Meal", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedMealType,
                        decoration: InputDecoration(
                          labelText: "Meal Type",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
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
                          labelText: "Meal Notes (Optional)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Food Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton.icon(
                            onPressed: searchAndAddFood,
                            icon: const Icon(Icons.add),
                            label: const Text("Add Food"),
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
                                child: Text("No food items added yet.", style: TextStyle(color: Colors.grey)),
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
                                  subtitle: Text("${item['quantity']}g - ${item['calories'].round()} kcal"),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: mealItems.isEmpty
                      ? null
                      : () async {
                          final mealData = {
                            "mealType": selectedMealType,
                            "mealDate": _selectedDate.toIso8601String(),
                            "notes": notesController.text.trim(),
                            "items": mealItems.map((item) => {
                              "foodId": item['foodId'],
                              "quantity": item['quantity'],
                            }).toList()
                          };

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          final res = await ApiService.addMeal(mealData);
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            Navigator.pop(context); // Close wizard
                          }

                          if (res != null) {
                            _loadMealLogs();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Logged $selectedMealType successfully!"),
                                backgroundColor: primaryGreen,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Log Meal", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          "Meal Logs & History",
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: primaryGreen),
            onPressed: () => _selectDate(context),
          )
        ],
      ),
      body: Column(
        children: [
          _buildDateBanner(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDailySummaryCard(),
                        const SizedBox(height: 20),
                        _buildMealHistorySection(),
                      ],
                    ),
                  ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _openAddMealWizard,
        backgroundColor: primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDateBanner() {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            isToday ? "Today, ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}" : DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    final caloriePercent = _caloriesTarget > 0 ? (_caloriesConsumed / _caloriesTarget).clamp(0.0, 1.0) : 0.0;
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
          const Text("Nutrition Intake Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748))),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_caloriesConsumed.round()}",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
                  ),
                  const Text("Consumed (kcal)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_caloriesTarget.round()}",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const Text("Target Budget", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_remaining.round()}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _remaining > 0 ? Colors.green[700] : Colors.redAccent,
                    ),
                  ),
                  const Text("Remaining", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: caloriePercent,
              minHeight: 8,
              color: primaryGreen,
              backgroundColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroMetric("Protein", "${_protein.round()}g"),
              _macroMetric("Carbs", "${_carbs.round()}g"),
              _macroMetric("Fats", "${_fat.round()}g"),
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

  Widget _buildMealHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Logged Meals",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 12),
        _meals.isEmpty
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
                      "No meals logged for this day.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _meals.length,
                itemBuilder: (context, idx) {
                  final meal = _meals[idx];
                  return _buildMealCard(meal);
                },
              ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final items = meal['items'] as List<dynamic>? ?? [];
    final mealType = meal['mealType'] ?? 'Meal';
    final calories = (meal['totalCalories'] as num?)?.toDouble() ?? 0.0;
    final mealId = meal['mealId'];

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
        title: Text(mealType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          "${calories.round()} kcal | ${items.length} items",
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
                if (meal['notes'] != null && meal['notes'].toString().isNotEmpty) ...[
                  Text(
                    "Notes: ${meal['notes']}",
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
                              "${item['foodName']} (${item['quantity']}g)",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            "${(item['calories'] as num).round()} kcal",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
