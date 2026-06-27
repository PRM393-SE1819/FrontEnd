import '../../domain/entities/meal_item.dart';

class MealItemModel extends MealItem {
  const MealItemModel({
    required super.foodId,
    required super.foodName,
    required super.quantity,
    required super.calories,
    required super.protein,
    required super.carbs,
    required super.fat,
    super.servingSize,
  });

  factory MealItemModel.fromJson(Map<String, dynamic> json) {
    return MealItemModel(
      foodId: json['foodId'] ?? 0,
      foodName: json['foodName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      servingSize: json['servingSize']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
    };
  }
}
