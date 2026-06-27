class MealItem {
  final int foodId;
  final String foodName;
  final double quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? servingSize;

  const MealItem({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize,
  });
}
