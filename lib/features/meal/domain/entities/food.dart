class Food {
  final int foodId;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? servingSize;
  final bool isCustom;
  final bool isFavorite;
  final String? foodType;
  final String? description;
  final String? barcode;
  final double sodium;
  final double fiber;
  final double sugar;

  const Food({
    required this.foodId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize,
    this.isCustom = false,
    this.isFavorite = false,
    this.foodType,
    this.description,
    this.barcode,
    this.sodium = 0.0,
    this.fiber = 0.0,
    this.sugar = 0.0,
  });
}
