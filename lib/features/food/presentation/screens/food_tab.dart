import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';

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
  int _searchTotalPages = 1;
  int _searchCurrentPage = 1;

  // Favorite foods
  bool _isLoadingFavorites = false;
  List<dynamic> _favoriteFoods = [];

  bool _isLoadingCustom = false;
  List<dynamic> _customFoods = []; // We can store local custom foods or search for custom foods.

  final Color primaryGreen = const Color(0xFF006D44);
  final Color secondaryGreen = const Color(0xFFE6FFFA);
  final Color accentAmber = const Color(0xFFD97706);

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
    final results = await ApiService.searchFoods(query, page: 1, pageSize: 20);
    if (mounted) {
      setState(() {
        _searchResults = results != null ? results['items'] ?? [] : [];
        _searchTotalPages = results != null ? results['totalPages'] ?? 1 : 1;
        _searchCurrentPage = results != null ? results['currentPage'] ?? 1 : 1;
        
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFav ? "Removed from Favorites" : "Added to Favorites"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  void _openBarcodeScanner() {
    final barcodeTextController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: primaryGreen),
              const SizedBox(width: 10),
              const Text("Barcode Scanner", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Scan or enter barcode to quickly retrieve food details.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: barcodeTextController,
                decoration: InputDecoration(
                  labelText: "Enter Barcode Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.password),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      if (barcodeTextController.text.isNotEmpty) {
                        Navigator.pop(context, barcodeTextController.text.trim());
                      }
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              const Text("Test Barcodes:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _barcodeChip("8934567890123", context),
                  _barcodeChip("8936018619124", context),
                  _barcodeChip("123456789", context),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    ).then((barcode) async {
      if (barcode != null && barcode is String) {
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
              content: Text("Barcode $barcode not found in database."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "Create Food",
                textColor: Colors.white,
                onPressed: () => _openCustomFoodDialog(barcode: barcode),
              ),
            ),
          );
        }
      }
    });
  }

  Widget _barcodeChip(String code, BuildContext ctx) {
    return ActionChip(
      label: Text(code),
      onPressed: () => Navigator.pop(ctx, code),
      backgroundColor: primaryGreen.withOpacity(0.08),
      labelStyle: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
    );
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
                              food['name'] ?? "Food Item",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                            ),
                            if (food['servingSize'] != null)
                              Text(
                                "Serving Size: ${food['servingSize']}",
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
                        "Add to Meal Log",
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
          const Text("Nutrition Facts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          const Divider(thickness: 2, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Calories", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text("${calories.round()} kcal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black),
          _nutritionRow("Total Fat", fat, "g", bold: true),
          _nutritionRow("Total Carbohydrate", carbs, "g", bold: true),
          _nutritionRow("  Dietary Fiber", fiber, "g"),
          _nutritionRow("  Sugars", sugar, "g"),
          _nutritionRow("Protein", protein, "g", bold: true),
          _nutritionRow("Sodium", sodium, "mg"),
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
    final quantityController = TextEditingController(text: "100");
    DateTime selectedTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Add to Meal Log", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
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
                        setDialogState(() => selectedMealType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: "Quantity (grams / servings)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: "g",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(quantityController.text) ?? 100.0;
                    final mealData = {
                      "mealType": selectedMealType,
                      "mealDate": selectedTime.toIso8601String(),
                      "notes": "Logged from search",
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Logged $selectedMealType successfully!"),
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
                  child: const Text("Add Log", style: TextStyle(color: Colors.white)),
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
          title: Text(existingFood == null ? "Create Custom Food" : "Edit Custom Food", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Food Name *"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: servingController,
                decoration: const InputDecoration(labelText: "Serving Size (e.g. 100g, 1 slice)"),
              ),
              TextField(
                controller: calController,
                decoration: const InputDecoration(labelText: "Calories (kcal) *"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: protController,
                decoration: const InputDecoration(labelText: "Protein (g)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: carbController,
                decoration: const InputDecoration(labelText: "Carbs (g)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatController,
                decoration: const InputDecoration(labelText: "Fat (g)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: "Barcode (Optional)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final cal = double.tryParse(calController.text) ?? 0.0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name is required")));
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
                      content: Text(existingFood == null ? "Custom food created!" : "Custom food updated!"),
                      backgroundColor: primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error submitting custom food details.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
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
        title: const Text("Delete Custom Food"),
        content: const Text("Are you sure you want to delete this custom food?"),
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
      final success = await ApiService.deleteCustomFood(foodId);
      if (success) {
        _performSearch(_searchController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Custom food deleted successfully")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          "Food & Nutrition Hub",
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
            Tab(text: "Search Foods", icon: Icon(Icons.search)),
            Tab(text: "Favorites", icon: Icon(Icons.favorite)),
            Tab(text: "My Custom Foods", icon: Icon(Icons.dining_outlined)),
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
                    hintText: "Search standard or custom foods...",
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
                            Text("No foods found.", style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _openCustomFoodDialog(),
                              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                              child: const Text("Create Custom Food", style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          return _buildFoodCard(food);
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
                    Text("No favorite foods logged yet.", style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: _favoriteFoods.length,
                  itemBuilder: (context, index) {
                    final food = _favoriteFoods[index];
                    return _buildFoodCard(food);
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
                "My Created Dishes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
              ),
              ElevatedButton.icon(
                onPressed: () => _openCustomFoodDialog(),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text("Add Custom", style: TextStyle(color: Colors.white)),
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
                        Text("You haven't added any custom foods.", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _customFoods.length,
                    itemBuilder: (context, index) {
                      final food = _customFoods[index];
                      return _buildFoodCard(food, isCustomTab: true);
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
                      food['name'] ?? "Food Item",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${calories.round()} kcal | P:${protein.round()}g C:${carbs.round()}g F:${fat.round()}g",
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
