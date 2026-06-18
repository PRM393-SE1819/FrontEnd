import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../meal/presentation/screens/meal_tab.dart';

class FoodTab extends StatefulWidget {
  const FoodTab({super.key});

  @override
  State<FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends State<FoodTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Search results
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  // Favorite foods
  bool _isLoadingFavorites = false;
  List<dynamic> _favoriteFoods = [];

  List<dynamic> _customFoods = []; // We can store local custom foods or search for custom foods.

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
    _loadFavorites();
    _performSearch(""); // Default empty search to load initial foods
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoadingFavorites = true);
    final favs = await ApiService.getFavoriteFoods();
    if (mounted) {
      setState(() {
        _favoriteFoods = favs ?? [];
        _isLoadingFavorites = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final results = await ApiService.searchFoods(query, page: 1, pageSize: 100);
    if (mounted) {
      setState(() {
        final List<dynamic> items = results != null ? results['items'] ?? [] : [];
        // Sort custom foods first, then favorites, then standard foods
        items.sort((a, b) {
          final aCustom = (a['isCustom'] == true || a['foodType'] == 'Custom') ? 1 : 0;
          final bCustom = (b['isCustom'] == true || b['foodType'] == 'Custom') ? 1 : 0;
          if (aCustom != bCustom) {
            return bCustom.compareTo(aCustom); // Custom foods at the absolute top
          }
          final aId = a['foodId'];
          final bId = b['foodId'];
          final aFav = _favoriteFoods.any((f) => f['foodId'] == aId) ? 1 : 0;
          final bFav = _favoriteFoods.any((f) => f['foodId'] == bId) ? 1 : 0;
          return bFav.compareTo(aFav); // Then favorite foods
        });
        _searchResults = items;
        _customFoods = _searchResults.where((food) => food['isCustom'] == true || food['foodType'] == 'Custom').toList();
        _isSearching = false;
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> food) async {
    final foodId = food['foodId'];
    final isFav = _favoriteFoods.any((f) => f['foodId'] == foodId);
    
    bool success;
    if (isFav) {
      success = await ApiService.removeFavoriteFood(foodId);
    } else {
      success = await ApiService.addFavoriteFood(foodId);
    }

    if (success) {
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFav ? "Đã xóa khỏi danh sách Yêu thích" : "Đã thêm vào danh sách Yêu thích"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryGreen,
          ),
        );
      }
    }
  }

  void _openBarcodeScanner() {
    showDialog<String>(
      context: context,
      builder: (context) => const BarcodeScannerDialog(),
    ).then((barcode) async {
      if (barcode != null && barcode.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final result = await ApiService.scanBarcode(barcode);
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (result != null && result['found'] == true) {
          final food = result['food'];
          if (food != null) {
            _showFoodDetailsDialog(food);
          }
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

  void _showFoodDetailsDialog(Map<String, dynamic> food) {
    final isFav = _favoriteFoods.any((f) => f['foodId'] == food['foodId']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
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
                              food['name'] ?? "Tên món ăn",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                            ),
                            if (food['servingSize'] != null)
                              Text(
                                "Khẩu phần: ${food['servingSize']}",
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
                          Navigator.pop(context);
                          _toggleFavorite(food);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (food['description'] != null && food['description'].toString().isNotEmpty) ...[
                    Text(
                      food['description'],
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
                        Navigator.pop(context);
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
    );
  }

  Widget _buildNutritionFactSheet(Map<String, dynamic> food) {
    final calories = (food['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (food['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (food['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (food['fat'] as num?)?.toDouble() ?? 0.0;
    final sodium = (food['sodium'] as num?)?.toDouble() ?? 0.0;
    final fiber = (food['fiber'] as num?)?.toDouble() ?? 0.0;
    final sugar = (food['sugar'] as num?)?.toDouble() ?? 0.0;

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
              Text("${calories.round()} kcal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black),
          _nutritionRow("Tổng chất béo", fat, "g", bold: true),
          _nutritionRow("Tổng bột đường (Carbs)", carbs, "g", bold: true),
          _nutritionRow("  Chất xơ", fiber, "g"),
          _nutritionRow("  Đường", sugar, "g"),
          _nutritionRow("Chất đạm (Protein)", protein, "g", bold: true),
          _nutritionRow("Natri (Sodium)", sodium, "mg"),
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

  void _showAddToMealDialog(Map<String, dynamic> food) {
    String selectedMealType = 'Breakfast';
    final quantityController = TextEditingController(text: "1");
    DateTime selectedTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Ghi nhận bữa ăn", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
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
                      labelText: "Số lượng (Khẩu phần chuẩn: ${food['servingSize'] ?? '1 phần'})",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: "khẩu phần",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                          "foodId": food['foodId'],
                          "quantity": qty,
                        }
                      ]
                    };

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    final res = await ApiService.addMeal(mealData);
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      Navigator.pop(context); // Close dialog
                    }

                    if (res != null) {
                      MealTab.onReload?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã thêm món ăn vào ${mealTypeMap[selectedMealType]}!"),
                          backgroundColor: primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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

  void _openCustomFoodDialog({Map<String, dynamic>? existingFood, String? barcode}) {
    final nameController = TextEditingController(text: existingFood?['name'] ?? '');
    final descController = TextEditingController(text: existingFood?['description'] ?? '');
    final calController = TextEditingController(text: existingFood?['calories']?.toString() ?? '100');
    final protController = TextEditingController(text: existingFood?['protein']?.toString() ?? '0');
    final carbController = TextEditingController(text: existingFood?['carbs']?.toString() ?? '0');
    final fatController = TextEditingController(text: existingFood?['fat']?.toString() ?? '0');
    final servingController = TextEditingController(text: existingFood?['servingSize'] ?? '100g');
    final barcodeController = TextEditingController(text: barcode ?? existingFood?['barcode'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existingFood == null ? "Tạo món ăn tự tạo" : "Sửa món ăn tự tạo", 
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final cal = double.tryParse(calController.text) ?? 0.0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên món ăn")));
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

                Navigator.pop(context);
                showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                bool success;
                if (existingFood == null) {
                  final res = await ApiService.createCustomFood(foodData);
                  success = res != null;
                } else {
                  final res = await ApiService.updateCustomFood(existingFood['foodId'], foodData);
                  success = res != null;
                }

                if (context.mounted) Navigator.pop(context); // Close loading

                if (success) {
                  _performSearch(_searchController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existingFood == null ? "Đã tạo món ăn thành công!" : "Đã cập nhật món ăn thành công!"),
                      backgroundColor: primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lỗi khi gửi thông tin món ăn tự tạo.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
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

      final success = await ApiService.deleteCustomFood(foodId);

      if (mounted) Navigator.pop(context); // Close loading indicator

      if (success) {
        _performSearch(_searchController.text);
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
                  onSubmitted: _performSearch,
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
            child: _isSearching
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : _searchResults.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          return AnimatedFadeSlide(
                            delay: (index * 50).clamp(0, 300),
                            child: _buildFoodCard(food),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return _isLoadingFavorites
        ? Center(child: CircularProgressIndicator(color: primaryGreen))
        : _favoriteFoods.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text("Chưa có món ăn yêu thích nào.", style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: _favoriteFoods.length,
                  itemBuilder: (context, index) {
                    final food = _favoriteFoods[index];
                    return AnimatedFadeSlide(
                      delay: (index * 50).clamp(0, 300),
                      child: _buildFoodCard(food),
                    );
                  },
                ),
              );
  }

  Widget _buildCustomFoodsTab() {
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
            child: _customFoods.isEmpty
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
                    itemCount: _customFoods.length,
                    itemBuilder: (context, index) {
                      final food = _customFoods[index];
                      return AnimatedFadeSlide(
                        delay: (index * 50).clamp(0, 300),
                        child: _buildFoodCard(food, isCustomTab: true),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food, {bool isCustomTab = false}) {
    final calories = (food['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (food['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (food['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (food['fat'] as num?)?.toDouble() ?? 0.0;
    final foodId = food['foodId'];
    final isFav = _favoriteFoods.any((f) => f['foodId'] == foodId);

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
                  color: primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.restaurant_menu, color: primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food['name'] ?? "Món ăn",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${calories.round()} kcal | Đạm:${protein.round()}g Đường:${carbs.round()}g Béo:${fat.round()}g",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isCustomTab) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _openCustomFoodDialog(existingFood: food),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteCustomFood(foodId),
                ),
              ] else ...[
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleFavorite(food),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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

class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF006D44);
  late AnimationController _animController;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Quét mã vạch",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Đặt mã vạch vào khung hình hoặc nhập mã vạch bên dưới để tra cứu thông tin dinh dưỡng.",
              style: TextStyle(fontSize: 13, color: Color(0xFF718096), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Viewfinder Simulator
            Container(
              width: 200,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF1A202C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Corner markers
                    Positioned(
                      top: 10, left: 10,
                      child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: primaryGreen, width: 3), left: BorderSide(color: primaryGreen, width: 3)),
                      )),
                    ),
                    Positioned(
                      top: 10, right: 10,
                      child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: primaryGreen, width: 3), right: BorderSide(color: primaryGreen, width: 3)),
                      )),
                    ),
                    Positioned(
                      bottom: 10, left: 10,
                      child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: primaryGreen, width: 3), left: BorderSide(color: primaryGreen, width: 3)),
                      )),
                    ),
                    Positioned(
                      bottom: 10, right: 10,
                      child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: primaryGreen, width: 3), right: BorderSide(color: primaryGreen, width: 3)),
                      )),
                    ),
                    
                    // Laser Scanner Simulation Line
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + (100 * _animController.value),
                          left: 15,
                          right: 15,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Centered Help Icon
                    const Center(
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(Icons.qr_code, size: 64, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Manual Input TextField
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Nhập mã vạch sản phẩm",
                hintText: "Ví dụ: 8934567890123",
                prefixIcon: const Icon(Icons.keyboard_outlined, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.pop(context, val.trim());
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(context, text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vui lòng nhập mã vạch")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Tra cứu",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

double parseServingWeight(String? servingSize) {
  if (servingSize == null || servingSize.isEmpty) return 100.0;
  final regExp = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
  final match = regExp.firstMatch(servingSize);
  if (match != null) {
    final parsed = double.tryParse(match.group(1) ?? '');
    if (parsed != null && parsed > 0) return parsed;
  }
  return 1.0; // Fallback to 1 (e.g. "portion", "serving", "phần", "cái")
}
