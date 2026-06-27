import '../entities/meal.dart';
import '../entities/daily_calories_summary.dart';
import '../entities/food.dart';

abstract class MealRepository {
  Future<DailyCaloriesSummary?> getDailyCaloriesSummary(String date);
  Future<List<Meal>?> getMealHistory({int page = 1, int pageSize = 10, String? date, String? mealType});
  Future<Meal?> addMeal(Map<String, dynamic> mealData);
  Future<Meal?> updateMeal(int mealId, Map<String, dynamic> mealData);
  Future<bool> deleteMeal(int mealId);
  Future<List<Food>?> searchFoods(String query, {int page = 1, int pageSize = 100});
  Future<List<Food>?> getFavoriteFoods();
}
