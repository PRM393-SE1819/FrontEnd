import 'meal_item.dart';

class Meal {
  final int mealId;
  final String mealType;
  final DateTime mealDate;
  final String? notes;
  final List<MealItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const Meal({
    required this.mealId,
    required this.mealType,
    required this.mealDate,
    this.notes,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });
}
