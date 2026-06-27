import '../../domain/entities/meal.dart';
import 'meal_item_model.dart';

class MealModel extends Meal {
  const MealModel({
    required super.mealId,
    required super.mealType,
    required super.mealDate,
    super.notes,
    required super.items,
    required super.totalCalories,
    required super.totalProtein,
    required super.totalCarbs,
    required super.totalFat,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    final parsedItems = list.map((e) => MealItemModel.fromJson(Map<String, dynamic>.from(e))).toList();

    return MealModel(
      mealId: json['mealId'] ?? json['id'] ?? 0,
      mealType: json['mealType'] ?? 'Meal',
      mealDate: DateTime.parse(json['mealDate'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      items: parsedItems,
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealId': mealId,
      'mealType': mealType,
      'mealDate': mealDate.toIso8601String(),
      'notes': notes,
      'items': items.map((e) => (e as MealItemModel).toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
  }
}
