import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/dependency_injection.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../meal/domain/entities/food.dart';
import '../../../meal/domain/repositories/meal_repository.dart';
import '../cubit/food_cubit.dart';
import '../cubit/food_state.dart';
import '../../../meal/presentation/screens/meal_tab.dart';

class FoodTab extends StatefulWidget {
  const FoodTab({super.key});

  @override
  State<FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends State<FoodTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final Color primaryGreen = const Color(0xFF006D44);
  final Color secondaryGreen = const Color(0xFFE6FFFA);
  final Color accentAmber = const Color(0xFFD97706);

  final Map<String, String> mealTypeMap = {
    'Breakfast': 'Bữa sáng',
    'Lunch': 'Bữa trưa',
    'Dinner': 'Bữa tối',
    'Snack': 'Bữa phụ',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodCubit>().loadFavorites();
      context.read<FoodCubit>().performSearch(""); // Default empty search
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      context.read<FoodCubit>().loadFavorites();
    }
  }

  Future<void> _toggleFavorite(Food food) async {
    final success = await context.read<FoodCubit>().toggleFavorite(food);
    if (success && mounted) {
      final isFavNow = context.read<FoodCubit>().state is FoodSearchSuccess &&
          (context.read<FoodCubit>().state as FoodSearchSuccess).favoriteFoods.any((f) => f.foodId == food.foodId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavNow ? "Đã thêm vào danh sách Yêu thích" : "Đã xóa khỏi danh sách Yêu thích"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  void _openBarcodeScanner() {
    showDialog<String>(
      context: context,
      builder: (dialogCtx) => const BarcodeScannerDialog(),
    ).then((barcode) async {
      if (barcode != null && barcode.isNotEmpty) {
        if (!mounted) return;
        final foodCubit = context.read<FoodCubit>();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (loaderCtx) => const Center(child: CircularProgressIndicator()),
        );

        final food = await foodCubit.scanBarcode(barcode);
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (food != null) {
          _showFoodDetailsDialog(food);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Mã vạch $barcode không tồn tại trong hệ thống."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "Tự tạo món",
                textColor: Colors.white,
                onPressed: () => _openCustomFoodDialog(barcode: barcode),
              ),
            ),
          );
        }
      }
    });
  }

  void _showFoodDetailsDialog(Food food) {
    final foodCubit = context.read<FoodCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return BlocProvider.value(
          value: foodCubit,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (sheetContext, scrollController) {
              return BlocBuilder<FoodCubit, FoodState>(
                builder: (builderContext, state) {
                  final isFav = state is FoodSearchSuccess && state.favoriteFoods.any((f) => f.foodId == food.foodId);
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                                  ),
                                  if (food.servingSize != null)
                                    Text(
                                      "Khẩu phần: ${food.servingSize}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey,
                                size: 30,
                              ),
                              onPressed: () {
                                _toggleFavorite(food);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (food.description != null && food.description!.isNotEmpty) ...[
                          Text(
                            food.description!,
                            style: TextStyle(fontSize: 15, color: Colors.grey[700], fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildNutritionFactSheet(food),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _showAddToMealDialog(food);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Thêm vào nhật ký ăn uống",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNutritionFactSheet(Food food) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Giá trị dinh dưỡng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          const Divider(thickness: 2, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Lượng Calo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text("${food.calories.round()} kcal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black),
          _nutritionRow("Tổng chất béo", food.fat, "g", bold: true),
          _nutritionRow("Tổng bột đường (Carbs)", food.carbs, "g", bold: true),
          _nutritionRow("  Chất xơ", food.fiber, "g"),
          _nutritionRow("  Đường", food.sugar, "g"),
          _nutritionRow("Chất đạm (Protein)", food.protein, "g", bold: true),
          _nutritionRow("Natri (Sodium)", food.sodium, "mg"),
        ],
      ),
    );
  }

  Widget _nutritionRow(String label, double val, String unit, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${val.toStringAsFixed(1)} $unit",
            style: TextStyle(
              fontSize: 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToMealDialog(Food food) {
    String selectedMealType = 'Breakfast';
    final quantityController = TextEditingController(text: "1");
    DateTime selectedTime = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Ghi nhận bữa ăn", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedMealType,
                    decoration: InputDecoration(
                      labelText: "Bữa ăn",
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
                        setDialogState(() => selectedMealType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: "Số lượng (Khẩu phần chuẩn: ${food.servingSize ?? '1 phần'})",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: "khẩu phần",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(quantityController.text) ?? 1.0;

                    final mealData = {
                      "mealType": selectedMealType,
                      "mealDate": selectedTime.toIso8601String(),
                      "notes": "Được ghi từ thanh tìm kiếm",
                      "items": [
                        {
                          "foodId": food.foodId,
                          "quantity": qty,
                        }
                      ]
                    };

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loaderContext) => const Center(child: CircularProgressIndicator()),
                    );

                    final res = await getIt<MealRepository>().addMeal(mealData);
                    if (mounted) {
                      Navigator.pop(context); // Close loading
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext); // Close dialog
                    }

                    if (res != null) {
                      MealTab.onReload?.call();
                      if (mounted) {
                        try {
                          context.read<DashboardCubit>().loadDashboardData(showLoading: false);
                        } catch (_) {}
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã thêm món ăn vào ${mealTypeMap[selectedMealType]}!"),
                            backgroundColor: primaryGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Thêm", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openCustomFoodDialog({Food? existingFood, String? barcode}) {
    final nameController = TextEditingController(text: existingFood?.name ?? '');
    final descController = TextEditingController(text: existingFood?.description ?? '');
    final calController = TextEditingController(text: existingFood?.calories.toString() ?? '100');
    final protController = TextEditingController(text: existingFood?.protein.toString() ?? '0');
    final carbController = TextEditingController(text: existingFood?.carbs.toString() ?? '0');
    final fatController = TextEditingController(text: existingFood?.fat.toString() ?? '0');
    final servingController = TextEditingController(text: existingFood?.servingSize ?? '100g');
    final barcodeController = TextEditingController(text: barcode ?? existingFood?.barcode ?? '');

    final foodCubit = context.read<FoodCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: foodCubit,
          child: AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              existingFood == null ? "Tạo món ăn tự tạo" : "Sửa món ăn tự tạo",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Builder(
              builder: (builderContext) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Tên món ăn *"),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Mô tả"),
                    ),
                    TextField(
                      controller: servingController,
                      decoration: const InputDecoration(labelText: "Khẩu phần (vd: 100g, 1 lát)"),
                    ),
                    TextField(
                      controller: calController,
                      decoration: const InputDecoration(labelText: "Lượng Calo (kcal) *"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: protController,
                      decoration: const InputDecoration(labelText: "Chất đạm (Protein) (g)"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: carbController,
                      decoration: const InputDecoration(labelText: "Chất bột đường (Carbs) (g)"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: fatController,
                      decoration: const InputDecoration(labelText: "Chất béo (Fats) (g)"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: barcodeController,
                      decoration: const InputDecoration(labelText: "Mã vạch (Tùy chọn)"),
                    ),
                  ],
                );
              }
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              Builder(
                builder: (btnContext) {
                  return ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final cal = double.tryParse(calController.text) ?? 0.0;
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(btnContext).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên món ăn")));
                        return;
                      }

                      final foodData = {
                        "name": name,
                        "description": descController.text.trim(),
                        "calories": cal,
                        "protein": double.tryParse(protController.text) ?? 0.0,
                        "carbs": double.tryParse(carbController.text) ?? 0.0,
                        "fat": double.tryParse(fatController.text) ?? 0.0,
                        "servingSize": servingController.text.trim(),
                        "barcode": barcodeController.text.trim(),
                      };

                      Navigator.pop(dialogContext);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (loaderContext) => const Center(child: CircularProgressIndicator()),
                      );

                      bool success;
                      if (existingFood == null) {
                        success = await foodCubit.createCustomFood(foodData);
                      } else {
                        success = await foodCubit.updateCustomFood(existingFood.foodId, foodData);
                      }

                      if (mounted) Navigator.pop(context); // Close loading

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existingFood == null ? "Đã tạo món ăn thành công!" : "Đã cập nhật món ăn thành công!"),
                              backgroundColor: primaryGreen,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Lỗi khi gửi thông tin món ăn tự tạo.")),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                    child: const Text("Lưu", style: TextStyle(color: Colors.white)),
                  );
                }
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCustomFood(int foodId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa món tự tạo"),
        content: const Text("Bạn có chắc chắn muốn xóa món ăn tự tạo này không?"),
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

    if (confirm == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await context.read<FoodCubit>().deleteCustomFood(foodId);

      if (mounted) Navigator.pop(context); // Close loading indicator

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xóa món ăn tự tạo thành công"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi: Không thể xóa món ăn này."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          "Tra cứu dinh dưỡng",
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryGreen,
          tabs: const [
            Tab(text: "Tìm món ăn", icon: Icon(Icons.search)),
            Tab(text: "Yêu thích", icon: Icon(Icons.favorite)),
            Tab(text: "Món tự tạo", icon: Icon(Icons.dining_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildFavoritesTab(),
          _buildCustomFoodsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Tìm món tiêu chuẩn hoặc món tự tạo...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (query) => context.read<FoodCubit>().performSearch(query),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      onPressed: _openBarcodeScanner,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: state is FoodLoading
                    ? Center(child: CircularProgressIndicator(color: primaryGreen))
                    : state is FoodSearchSuccess && state.searchResults.isNotEmpty
                        ? ListView.builder(
                            itemCount: state.searchResults.length,
                            itemBuilder: (context, index) {
                              final food = state.searchResults[index];
                              return AnimatedFadeSlide(
                                delay: (index * 50).clamp(0, 300),
                                child: _buildFoodCard(food, state.favoriteFoods),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant, size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text("Không tìm thấy món ăn nào.", style: TextStyle(color: Colors.grey[500])),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _openCustomFoodDialog(),
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                                  child: const Text("Tạo món ăn tự tạo", style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, state) {
        if (state is FoodSearchSuccess) {
          if (state.isLoadingFavorites) {
            return Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (state.favoriteFoods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text("Chưa có món ăn yêu thích nào.", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: state.favoriteFoods.length,
              itemBuilder: (context, index) {
                final food = state.favoriteFoods[index];
                return AnimatedFadeSlide(
                  delay: (index * 50).clamp(0, 300),
                  child: _buildFoodCard(food, state.favoriteFoods),
                );
              },
            ),
          );
        }
        return Center(child: CircularProgressIndicator(color: primaryGreen));
      },
    );
  }

  Widget _buildCustomFoodsTab() {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, state) {
        final customFoods = state is FoodSearchSuccess ? state.customFoods : <Food>[];
        final favoriteFoods = state is FoodSearchSuccess ? state.favoriteFoods : <Food>[];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Món ăn đã tự tạo của tôi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openCustomFoodDialog(),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text("Thêm món", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                  )
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: customFoods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dining_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text("Bạn chưa tự tạo món ăn nào.", style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: customFoods.length,
                        itemBuilder: (context, index) {
                          final food = customFoods[index];
                          return AnimatedFadeSlide(
                            delay: (index * 50).clamp(0, 300),
                            child: _buildFoodCard(food, favoriteFoods, isCustomTab: true),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodCard(Food food, List<Food> favoriteFoods, {bool isCustomTab = false}) {
    final isFav = favoriteFoods.any((f) => f.foodId == food.foodId);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showFoodDetailsDialog(food),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (food.isCustom || food.foodType == 'Custom') ? secondaryGreen : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  (food.isCustom || food.foodType == 'Custom') ? Icons.dining_outlined : Icons.restaurant,
                  color: (food.isCustom || food.foodType == 'Custom') ? primaryGreen : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${food.calories.round()} kcal | P: ${food.protein.toStringAsFixed(1)}g | C: ${food.carbs.toStringAsFixed(1)}g | F: ${food.fat.toStringAsFixed(1)}g",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCustomTab) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                  onPressed: () => _openCustomFoodDialog(existingFood: food),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteCustomFood(food.foodId),
                ),
              ] else
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleFavorite(food),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nhập mã vạch", style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: "Nhập mã vạch thủ công (ví dụ: 8934567890123)",
          prefixIcon: Icon(Icons.qr_code_2),
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D44)),
          child: const Text("Tìm kiếm", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
