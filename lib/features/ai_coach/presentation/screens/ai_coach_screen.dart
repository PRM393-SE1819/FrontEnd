import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../meal/presentation/screens/meal_tab.dart';
import '../../domain/entities/chat_message.dart';
import '../cubit/ai_coach_cubit.dart';
import '../cubit/ai_coach_state.dart';
import '../../../../core/network/api_service.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  static void Function()? onReload;

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  int _currentSubTab = 0; // 0 = AI Scan, 1 = AI Coach

  static const Color primaryGreen = Color(0xFF006D44);
  static const Color lightGreen = Color(0xFFE6F4EE);
  static const Color darkBg = Color(0xFFF7FAFC);

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AiCoachCubit>();
    AiCoachScreen.onReload = () {
      cubit.reloadUserContext();
    };
    cubit.loadInitialData();
  }

  @override
  void dispose() {
    AiCoachScreen.onReload = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getImageUrlForName(String imageName) {
    const images = {
      'salad': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop&q=80',
      'salmon': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500&auto=format&fit=crop&q=80',
      'pho': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500&auto=format&fit=crop&q=80',
      'banh_mi': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=500&auto=format&fit=crop&q=80',
      'pizza': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=80',
      'burger': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=80',
      'chicken': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500&auto=format&fit=crop&q=80',
      'com_tam': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&auto=format&fit=crop&q=80',
      'beef': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=80',
      'fallback': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=500&auto=format&fit=crop&q=80',
    };
    return images[imageName] ?? images['fallback']!;
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();
    context.read<AiCoachCubit>().sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickAndScanFoodImage({ImageSource? preferredSource}) async {
    ImageSource? source = preferredSource;
    if (source == null) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: primaryGreen),
                  title: const Text("Chụp ảnh từ Camera"),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: primaryGreen),
                  title: const Text("Chọn ảnh từ Thư viện"),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
    }

    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64Data = base64Encode(bytes);

    if (mounted) {
      context.read<AiCoachCubit>().scanFoodImage(
            base64Data,
            image.mimeType ?? 'image/jpeg',
            bytes,
          );
    }
    _scrollToBottom();
  }

  void _showScanErrorDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Không thể nhận diện",
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(errorMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đồng ý", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _openManualSearchDialog(String initialQuery) {
    final searchController = TextEditingController(text: initialQuery);
    bool searching = false;
    List<dynamic> results = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> performSearch() async {
              setDialogState(() => searching = true);
              final res = await ApiService.searchFoods(searchController.text.trim());
              setDialogState(() {
                results = res != null ? res['items'] ?? [] : [];
                searching = false;
              });
            }

            if (results.isEmpty && !searching && searchController.text.isNotEmpty) {
              performSearch();
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Tìm kiếm món ăn", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Nhập tên món ăn...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: primaryGreen),
                          onPressed: performSearch,
                        ),
                      ),
                      onSubmitted: (_) => performSearch(),
                    ),
                    const SizedBox(height: 15),
                    searching
                        ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                        : Expanded(
                            child: results.isEmpty
                                ? Center(
                                    child: Text(
                                      searchController.text.isEmpty ? "Nhập từ khóa để tìm kiếm" : "Không tìm thấy món ăn nào.",
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: results.length,
                                    itemBuilder: (context, index) {
                                      final food = results[index];
                                      final calories = (food['calories'] as num?)?.toDouble() ?? 0.0;
                                      return Card(
                                        elevation: 0,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        child: ListTile(
                                          title: Text(food['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          subtitle: Text("${calories.round()} kcal | ${food['servingSize'] ?? '100g'}"),
                                          trailing: const Icon(Icons.add_circle_outline, color: primaryGreen),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showFoodDetailFromSearch(food);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFoodDetailFromSearch(Map<String, dynamic> food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
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
                  Text(
                    food['name'] ?? "Food Item",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  if (food['servingSize'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Khẩu phần: ${food['servingSize']}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildNutritionFactSheet(food),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddToMealDialogFromSearch(food);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Ghi nhận bữa ăn",
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
          const Text("Thành phần dinh dưỡng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          const Divider(thickness: 2, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Calories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text("${calories.round()} kcal", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black),
          _nutritionFactRow("Tổng chất béo (Fat)", fat, "g", bold: true),
          _nutritionFactRow("Tổng Carbohydrate", carbs, "g", bold: true),
          _nutritionFactRow("Chất đạm (Protein)", protein, "g", bold: true),
        ],
      ),
    );
  }

  Widget _nutritionFactRow(String label, double val, String unit, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text("${val.toStringAsFixed(1)} $unit", style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showAddToMealDialogFromSearch(Map<String, dynamic> food) {
    String selectedMealType = 'Breakfast';
    final quantityController = TextEditingController(text: "100");

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Thêm vào nhật ký bữa ăn", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      String label = type;
                      if (type == 'Breakfast') label = 'Bữa sáng';
                      else if (type == 'Lunch') label = 'Bữa trưa';
                      else if (type == 'Dinner') label = 'Bữa tối';
                      else if (type == 'Snack') label = 'Bữa phụ';
                      return DropdownMenuItem(value: type, child: Text(label));
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
                      labelText: "Khối lượng",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: "g",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(quantityController.text) ?? 100.0;
                    final mealData = {
                      "mealType": selectedMealType,
                      "mealDate": DateTime.now().toIso8601String(),
                      "notes": "Logged from AI search",
                      "items": [
                        {
                          "foodId": food['foodId'],
                          "quantity": qty,
                        }
                      ]
                    };

                    Navigator.pop(dialogCtx); // Close Dialog
                    context.read<AiCoachCubit>().addScannedMeal(mealData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Lưu log", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScanResultBottomSheet(Map<String, dynamic> res) {
    final success = res['success'] ?? true;
    if (!success) {
      _showScanErrorDialog(res['message'] ?? "Không thể phân tích dữ liệu hình ảnh.");
      return;
    }

    final items = res['items'] as List<dynamic>? ?? [];
    final totalNutr = res['total_nutrition'] as Map<String, dynamic>?;
    final healthRating = res['health_rating'] ?? "Chưa đánh giá";
    final advice = res['advice'] ?? "";
    final mealType = res['meal_type'] ?? "lunch";
    final alternatives = res['alternatives'] as List<dynamic>? ?? [];

    Color ratingColor = Colors.grey;
    if (healthRating.toString().contains("Tốt")) {
      ratingColor = Colors.green;
    } else if (healthRating.toString().contains("Trung bình")) {
      ratingColor = Colors.orange;
    } else if (healthRating.toString().contains("Hạn chế")) {
      ratingColor = Colors.red;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.6,
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
                            const Text(
                              "Kết Quả Phân Tích",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Độ tin cậy: ${((res['confidence'] ?? 0.8) * 100).round()}%",
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mealType.toString().toUpperCase(),
                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  if (res['imageBase64'] != null && res['imageBase64'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        base64Decode(res['imageBase64']),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ] else if (res['imageName'] != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _getImageUrlForName(res['imageName']),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const Divider(height: 30),

                  if (totalNutr != null) ...[
                    const Text(
                      "Tổng dinh dưỡng bữa ăn",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    const SizedBox(height: 12),
                    _buildNutritionGrid(totalNutr),
                    const SizedBox(height: 20),
                  ],

                  ...items.map((itemObj) {
                    final item = itemObj as Map<String, dynamic>;
                    final nameVi = item['name_vi'] ?? "Món ăn";
                    final nameEn = item['name_en'] ?? "";
                    final portion = item['portion_size'] ?? "";
                    final multiplier = (item['portion_multiplier'] as num?)?.toDouble() ?? 1.0;
                    final weight = (item['weight_grams'] as num?)?.toDouble() ?? 0.0;
                    final ingredients = item['ingredients'] as List<dynamic>? ?? [];
                    final flags = item['dietary_flags'] as Map<String, dynamic>? ?? {};

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  nameVi,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3748)),
                                ),
                              ),
                              if (weight > 0)
                                Text(
                                  "${(weight * multiplier).round()}g",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
                                ),
                            ],
                          ),
                          if (nameEn.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(nameEn, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 8),
                          Text("Khẩu phần: $portion (x$multiplier)", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          const SizedBox(height: 12),
                          if (items.length > 1 && item['nutrition'] != null) _buildNutritionGrid(item['nutrition']),
                          
                          if (ingredients.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text("Thành phần:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4A5568))),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: ingredients.map((ing) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(ing.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568))),
                                );
                              }).toList(),
                            ),
                          ],

                          if (flags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (flags['vegetarian'] == true) _flagChip("Chay 🌱", Colors.green),
                                if (flags['vegan'] == true) _flagChip("Thuần chay 🟢", Colors.teal),
                                if (flags['gluten_free'] == true) _flagChip("Gluten-Free 🌾", Colors.orange),
                                if (flags['high_protein'] == true) _flagChip("Đạm cao 💪", Colors.blue),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  Row(
                    children: [
                      const Text(
                        "Đánh giá sức khỏe: ",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A5568)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ratingColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          healthRating.toString(),
                          style: TextStyle(color: ratingColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (advice.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, color: primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              advice.toString(),
                              style: TextStyle(fontSize: 13, color: Colors.green.shade900, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (alternatives.isNotEmpty) ...[
                    const Text("Gợi ý khác:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF718096))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: alternatives.map((alt) {
                        final name = alt['name'] ?? "";
                        final conf = (alt['confidence'] as num?)?.toDouble() ?? 0.0;
                        return Text(
                          "$name (${(conf * 100).round()}%)",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text("Đóng", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showLogMealSelector(res);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Lưu nhật ký",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogMealSelector(Map<String, dynamic> res) {
    String selectedMealType = 'Breakfast';
    
    final aiMealType = res['meal_type']?.toString().toLowerCase() ?? '';
    if (aiMealType.contains('breakfast')) selectedMealType = 'Breakfast';
    else if (aiMealType.contains('lunch')) selectedMealType = 'Lunch';
    else if (aiMealType.contains('dinner')) selectedMealType = 'Dinner';
    else if (aiMealType.contains('snack')) selectedMealType = 'Snack';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Chọn bữa ăn muốn lưu", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      String label = type;
                      if (type == 'Breakfast') label = 'Bữa sáng';
                      else if (type == 'Lunch') label = 'Bữa trưa';
                      else if (type == 'Dinner') label = 'Bữa tối';
                      else if (type == 'Snack') label = 'Bữa phụ';
                      return DropdownMenuItem(value: type, child: Text(label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedMealType = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _logScannedMealToDbMultiple(res, selectedMealType);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logScannedMealToDbMultiple(Map<String, dynamic> scanResult, String mealType) async {
    final itemsList = scanResult['items'] as List<dynamic>? ?? [];
    if (itemsList.isEmpty) return;

    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
      ),
    );
    overlayState.insert(overlayEntry);

    try {
      final List<Map<String, dynamic>> mealItems = [];

      for (final item in itemsList) {
        final nameVi = item['name_vi'] ?? item['name'] ?? 'Món ăn AI';
        final nameEn = item['name_en'] ?? '';
        final foodName = nameVi.isNotEmpty ? nameVi : nameEn;
        final multiplier = (item['portion_multiplier'] as num?)?.toDouble() ?? 1.0;
        final weight = (item['weight_grams'] as num?)?.toDouble() ?? 100.0;
        final quantity = weight * multiplier;

        // 1. Search food
        final searchResult = await ApiService.searchFoods(foodName);
        int? foodId;
        String? servingSize;

        if (searchResult != null && searchResult['items'] != null && (searchResult['items'] as List).isNotEmpty) {
          final results = searchResult['items'] as List;
          final match = results.firstWhere(
            (f) => f['name'].toString().toLowerCase() == foodName.toLowerCase(),
            orElse: () => results.first,
          );
          foodId = match['foodId'];
          servingSize = match['servingSize']?.toString();
        }

        // 2. Create custom food if not found
        if (foodId == null) {
          final nutrition = item['nutrition'] ?? {};
          final calories = (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
          final protein = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;
          final carbs = (nutrition['carbs'] as num?)?.toDouble() ?? 0.0;
          final fat = (nutrition['fat'] as num?)?.toDouble() ?? 0.0;
          
          servingSize = weight > 0 ? "${weight.round()}g" : (item['portion_size'] ?? "100g");

          final customFood = await ApiService.createCustomFood({
            "name": foodName,
            "description": "Nhận diện từ AI Scan",
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "servingSize": servingSize,
          });

          if (customFood != null) {
            foodId = customFood['foodId'];
          }
        }

        if (foodId != null) {
          final servingWeight = parseServingWeight(servingSize);
          final quantityToSend = quantity / servingWeight;
          mealItems.add({
            "foodId": foodId,
            "quantity": quantityToSend,
          });
        }
      }

      overlayEntry.remove();

      if (mealItems.isNotEmpty) {
        final mealData = {
          "mealType": mealType,
          "mealDate": DateTime.now().toIso8601String(),
          "notes": "Nhận diện từ AI Scan",
          "items": mealItems
        };

        if (mounted) {
          context.read<AiCoachCubit>().addScannedMeal(mealData);
          MealTab.onReload?.call();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể tạo dữ liệu dinh dưỡng cho bữa ăn này.")),
        );
      }
    } catch (e) {
      overlayEntry.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra: $e")),
      );
    }
  }

  Future<void> _estimateCaloriesFromText(String description) async {
    if (description.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
      ),
    );
    overlayState.insert(overlayEntry);

    final res = await ApiService.estimateCalories(description.trim());
    overlayEntry.remove();

    if (res != null) {
      final cal = (res['estimatedCalories'] as num?)?.toInt() ?? 0;
      final protein = (res['protein'] as num?)?.toDouble() ?? 0.0;
      final carbs = (res['carbs'] as num?)?.toDouble() ?? 0.0;
      final fat = (res['fat'] as num?)?.toDouble() ?? 0.0;
      final food = res['foodName'] ?? description;
      final advice = res['advice'] ?? '';
      
      final scanResult = {
        'success': true,
        'message': 'Ước tính: $food',
        'meal_type': 'lunch',
        'total_nutrition': {'calories': cal, 'protein': protein, 'carbs': carbs, 'fat': fat, 'fiber': 0.0, 'sodium': 0.0},
        'items': [
          {
            'name_vi': food,
            'name_en': food,
            'portion_size': '1 phần',
            'portion_multiplier': 1.0,
            'weight_grams': 100.0,
            'nutrition': {'calories': cal, 'protein': protein, 'carbs': carbs, 'fat': fat, 'fiber': 0.0, 'sodium': 0.0},
            'ingredients': [],
            'dietary_flags': {'vegetarian': false, 'vegan': false, 'gluten_free': false, 'high_protein': protein >= 20.0},
          }
        ],
        'alternatives': [],
        'health_rating': 'Tốt',
        'advice': advice,
      };

      if (mounted) {
        context.read<AiCoachCubit>().saveRecentScan(food, scanResult);
        // Add fake scan response to UI conversation logs
        context.read<AiCoachCubit>().sendMessage("Hãy ước tính lượng Calo trong món: $description");
      }
      _showScanResultBottomSheet(scanResult);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể ước tính — vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiCoachCubit, AiCoachState>(
      listener: (context, state) {
        if (state is AiCoachLoaded) {
          if (state.toastMessage != null) {
            final msg = state.toastMessage!;
            if (msg.startsWith("SCAN_SUCCESS:")) {
              final jsonStr = msg.substring("SCAN_SUCCESS:".length);
              final parsed = jsonDecode(jsonStr);
              _showScanResultBottomSheet(parsed);
            } else if (msg.startsWith("SCAN_ERROR:")) {
              final err = msg.substring("SCAN_ERROR:".length);
              _showScanErrorDialog(err);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      },
      builder: (context, state) {
        if (state is AiCoachInitial || state is AiCoachLoading) {
          return const Scaffold(
            backgroundColor: darkBg,
            body: Center(child: CircularProgressIndicator(color: primaryGreen)),
          );
        }

        if (state is AiCoachError) {
          return Scaffold(
            backgroundColor: darkBg,
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

        if (state is AiCoachLoaded) {
          final userContext = state.userContext;

          return Scaffold(
            backgroundColor: darkBg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006D44), Color(0xFF00A86B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _currentSubTab == 0 ? Icons.auto_awesome : Icons.psychology_alt,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSubTab == 0 ? "Phân tích Bữa ăn AI" : "Trợ lý Dinh dưỡng AI",
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A86B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Online • NutriAI",
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                if (userContext != null)
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: primaryGreen),
                    tooltip: "Dinh dưỡng hôm nay",
                    onPressed: () => _showContextPanel(userContext),
                  ),
                if (_currentSubTab == 1)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                    tooltip: 'Xóa lịch sử chat',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xóa lịch sử chat'),
                          content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử hội thoại không?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ApiService.deleteAllChatHistory();
                        if (mounted) {
                          context.read<AiCoachCubit>().loadInitialData();
                        }
                      }
                    },
                  ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    _buildTabSwitcher(),
                    Expanded(
                      child: _currentSubTab == 0 ? _buildScanTab(state) : _buildChatTab(state),
                    ),
                  ],
                ),
                if (state.isOperationLoading)
                  Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: primaryGreen),
                              SizedBox(height: 16),
                              Text("Đang xử lý hình ảnh món ăn..."),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentSubTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentSubTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _currentSubTab == 0
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: _currentSubTab == 0 ? primaryGreen : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Quét món ăn AI",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentSubTab == 0 ? primaryGreen : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentSubTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentSubTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _currentSubTab == 1
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: _currentSubTab == 1 ? primaryGreen : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Trợ lý AI",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentSubTab == 1 ? primaryGreen : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab(AiCoachLoaded state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedFadeSlide(
            delay: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Phân tích Bữa ăn AI",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Giải mã tức thì giá trị dinh dưỡng của món ăn bằng AI. Chụp ảnh hoặc tìm kiếm để bắt đầu.",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedFadeSlide(
            delay: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  readOnly: true,
                  onTap: () => _openManualSearchDialog(""),
                  decoration: InputDecoration(
                    hintText: "Hoặc tìm kiếm món ăn thủ công...",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          AnimatedFadeSlide(
            delay: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [lightGreen.withOpacity(0.8), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F4EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, color: primaryGreen, size: 32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Quét món ăn của bạn",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sử dụng máy ảnh của bạn để nhận diện nguyên liệu và tính toán calo lập tức.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 180,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _pickAndScanFoodImage(preferredSource: ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 4,
                          shadowColor: primaryGreen.withOpacity(0.3),
                        ),
                        child: const Text(
                          "Mở Camera",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          AnimatedFadeSlide(
            delay: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(builder: (context) {
                final estimateCtrl = TextEditingController();
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF0D9488).withOpacity(0.08), Colors.white],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.text_fields, color: Color(0xFF0D9488), size: 20),
                          SizedBox(width: 8),
                          Text('Nhập tên món ăn để ước tính',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3748))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Không cần ảnh — nhập mô tả để nhận ước tính calo ngay lập tức.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: estimateCtrl,
                              decoration: InputDecoration(
                                hintText: 'Ví dụ: 1 bát phở bò, 2 cuốn chả giò...',
                                hintStyle: const TextStyle(fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onSubmitted: (val) => _estimateCaloriesFromText(val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _estimateCaloriesFromText(estimateCtrl.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                            child: const Icon(Icons.calculate, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          AnimatedFadeSlide(
            delay: 400,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.teal, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Thông tin từ AI",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Mô hình thị giác máy tính của chúng tôi phân tích hình dạng, màu sắc và kết cấu thực phẩm để ước tính khẩu phần và phân bổ dinh dưỡng với độ chính xác cao.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Độ chính xác",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                        Text(
                          "~94%",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          AnimatedFadeSlide(
            delay: 500,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Lượt quét gần đây",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedFadeSlide(
            delay: 600,
            child: state.recentScans.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      "Chưa có ảnh quét gần đây.",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                )
              : SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20, right: 8),
                    itemCount: state.recentScans.length,
                    itemBuilder: (context, index) {
                      final scan = state.recentScans[index];
                      final foodName = scan['foodName'] ?? 'Món ăn';
                      
                      final dateStr = scan['date'] as String?;
                      String time = scan['time'] ?? '';
                      if (dateStr != null) {
                        try {
                          final date = DateTime.parse(dateStr);
                          final diff = DateTime.now().difference(date);
                          if (diff.inDays == 0) {
                            time = "Hôm nay, ${DateFormat('HH:mm').format(date)}";
                          } else if (diff.inDays == 1) {
                            time = "Hôm qua, ${DateFormat('HH:mm').format(date)}";
                          } else {
                            time = DateFormat('dd/MM, HH:mm').format(date);
                          }
                        } catch (_) {}
                      }

                      final calories = scan['calories'] ?? 0;
                      final imageUrl = _getImageUrlForName(scan['imageName'] ?? 'fallback');
                      final base64Image = scan['imageBase64'] as String?;

                       return GestureDetector(
                        onTap: () {
                          if (scan['fullResult'] != null) {
                            final fullResult = Map<String, dynamic>.from(scan['fullResult']);
                            if (scan['imageBase64'] != null) {
                              fullResult['imageBase64'] = scan['imageBase64'];
                            }
                            _showScanResultBottomSheet(fullResult);
                          }
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12, bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                if (base64Image != null && base64Image.isNotEmpty)
                                  Image.memory(
                                    base64Decode(base64Image),
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: const Center(
                                        child: Icon(Icons.restaurant, color: Colors.grey, size: 40),
                                      ),
                                    ),
                                  )
                                else
                                  Image.network(
                                    imageUrl,
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: const Center(
                                        child: Icon(Icons.restaurant, color: Colors.grey, size: 40),
                                      ),
                                    ),
                                  ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.6),
                                        Colors.black.withOpacity(0.0),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        foodName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "$calories kcal",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChatTab(AiCoachLoaded state) {
    final userContext = state.userContext;

    return Column(
      children: [
        if (userContext != null) _buildContextBar(userContext),
        _buildQuickPrompts(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: state.messages.length + (state.isChatLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.messages.length) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(state.messages[index]);
            },
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildContextBar(Map<String, dynamic> userContext) {
    final cal = userContext['calories'] ?? 0;
    final calTarget = userContext['calorieTarget'] ?? 2000;
    final pct = calTarget > 0 ? (cal / calTarget).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 540;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: lightGreen,
              border: Border(bottom: BorderSide(color: Colors.green.shade100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "$cal / $calTarget kcal",
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600, 
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "P: ${userContext['protein']}g C: ${userContext['carbs']}g F: ${userContext['fat']}g",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: Colors.green.shade100,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: lightGreen,
            border: Border(bottom: BorderSide(color: Colors.green.shade100)),
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange[700], size: 16),
              const SizedBox(width: 4),
              Text(
                "$cal / $calTarget kcal",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: Colors.green.shade100,
                    color: primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "P: ${userContext['protein']}g  C: ${userContext['carbs']}g  F: ${userContext['fat']}g",
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickPrompts() {
    final prompts = [
      "📊 Phân tích dinh dưỡng hôm nay",
      "🥗 Gợi ý bữa tối",
      "💪 Thực phẩm giàu protein",
      "⚖️ Mẹo giảm cân",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: prompts.map((p) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(p, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.green.shade200),
              onPressed: () {
                _messageController.text = p.replaceAll(RegExp(r'[\u{1F300}-\u{1FFFF}]', unicode: true), '').trim();
                _sendMessage();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return AnimatedFadeSlide(
      delay: 50,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!msg.isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006D44), Color(0xFF00A86B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_alt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? primaryGreen
                      : msg.isError
                          ? Colors.red.shade50
                          : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                    bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.imageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          msg.imageBytes!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (msg.reasoning != null && msg.reasoning!.isNotEmpty) ...[
                      ReasoningCollapseWidget(reasoning: msg.reasoning!),
                    ],
                    if (msg.foodScanResult != null) ...[
                      _buildInlineFoodScanWidget(msg.foodScanResult!),
                    ] else ...[
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: msg.isUser ? Colors.white : const Color(0xFF2D3748),
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(msg.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: msg.isUser ? Colors.white70 : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (msg.isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineFoodScanWidget(Map<String, dynamic> res) {
    final items = res['items'] as List<dynamic>? ?? [];
    String foodName = "Món ăn";
    if (items.isNotEmpty) {
      foodName = items[0]['name_vi'] ?? items[0]['name'] ?? 'Món ăn';
    }
    final totalNutr = res['total_nutrition'] ?? {};
    final calories = (totalNutr['calories'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_outline, color: primaryGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Đã phân tích: $foodName",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text("Tổng calo: $calories kcal", style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showScanResultBottomSheet(res),
          icon: const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
          label: const Text("Xem chi tiết dinh dưỡng", style: TextStyle(color: Colors.white, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006D44), Color(0xFF00A86B)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_alt, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "Hỏi về dinh dưỡng của bạn...",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    prefixIcon: IconButton(
                      icon: Icon(Icons.camera_alt_outlined, color: Colors.grey[400], size: 20),
                      tooltip: "Quét ảnh thức ăn",
                      onPressed: _pickAndScanFoodImage,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006D44), Color(0xFF00A86B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006D44).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextPanel(Map<String, dynamic> userContext) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dinh Dưỡng Hôm Nay",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3748)),
              ),
              const Text(
                "Dữ liệu này được dùng để cá nhân hóa phản hồi của AI",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _contextRow(Icons.local_fire_department, "Calories",
                  "${userContext['calories']} / ${userContext['calorieTarget']} kcal", Colors.orange),
              _contextRow(Icons.fitness_center, "Protein",
                  "${userContext['protein']}g / ${userContext['proteinTarget']}g", Colors.red.shade400),
              _contextRow(Icons.grain, "Carbs",
                  "${userContext['carbs']}g / ${userContext['carbTarget']}g", Colors.amber.shade600),
              _contextRow(Icons.water_drop, "Fat",
                  "${userContext['fat']}g / ${userContext['fatTarget']}g", Colors.blue.shade400),
              _contextRow(Icons.monitor_weight_outlined, "Weight", "${userContext['weight']} kg", primaryGreen),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _contextRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(Map<String, dynamic> nutrition) {
    final cal = (nutrition['calories'] as num?)?.toInt() ?? 0;
    final prot = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;
    final carb = (nutrition['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (nutrition['fat'] as num?)?.toDouble() ?? 0.0;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _nutrCell("Calories", "$cal kcal", Colors.red),
        _nutrCell("Đạm (P)", "${prot.toStringAsFixed(1)}g", Colors.blue),
        _nutrCell("Carb (C)", "${carb.toStringAsFixed(1)}g", Colors.orange),
        _nutrCell("Béo (F)", "${fat.toStringAsFixed(1)}g", Colors.purple),
      ],
    );
  }

  Widget _nutrCell(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _flagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

class ReasoningCollapseWidget extends StatefulWidget {
  final String reasoning;
  const ReasoningCollapseWidget({super.key, required this.reasoning});

  @override
  State<ReasoningCollapseWidget> createState() => _ReasoningCollapseWidgetState();
}

class _ReasoningCollapseWidgetState extends State<ReasoningCollapseWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: const Color(0xFF006D44),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isExpanded ? "Ẩn quá trình suy nghĩ..." : "Xem quá trình suy nghĩ...",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF006D44),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
              child: Text(
                widget.reasoning,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
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

double parseServingWeight(String? servingSize) {
  if (servingSize == null || servingSize.isEmpty) return 100.0;
  final regExp = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
  final match = regExp.firstMatch(servingSize);
  if (match != null) {
    final parsed = double.tryParse(match.group(1) ?? '');
    if (parsed != null && parsed > 0) return parsed;
  }
  return 1.0; // Fallback
}
