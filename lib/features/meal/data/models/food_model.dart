import '../../domain/entities/food.dart';

class FoodModel extends Food {
  const FoodModel({
    required super.foodId,
    required super.name,
    required super.calories,
    required super.protein,
    required super.carbs,
    required super.fat,
    super.servingSize,
    super.isCustom = false,
    super.isFavorite = false,
    super.foodType,
    super.description,
    super.barcode,
    super.sodium = 0.0,
    super.fiber = 0.0,
    super.sugar = 0.0,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      foodId: json['foodId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      servingSize: json['servingSize'],
      isCustom: json['isCustom'] ?? (json['foodType'] == 'Custom'),
      isFavorite: json['isFavorite'] ?? false,
      foodType: json['foodType'],
      description: json['description'],
      barcode: json['barcode'],
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
      'isCustom': isCustom,
      'isFavorite': isFavorite,
      'foodType': foodType,
      'description': description,
      'barcode': barcode,
      'sodium': sodium,
      'fiber': fiber,
      'sugar': sugar,
    };
  }
}
