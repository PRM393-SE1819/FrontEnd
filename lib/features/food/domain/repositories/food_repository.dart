import '../../../meal/domain/entities/food.dart';

abstract class FoodRepository {
  Future<List<Food>> getFavoriteFoods();
  Future<bool> addFavoriteFood(int foodId);
  Future<bool> removeFavoriteFood(int foodId);
  Future<Map<String, dynamic>?> searchFoods(String query, {int page = 1, int pageSize = 100});
  Future<Map<String, dynamic>?> scanBarcode(String barcode);
  Future<Food?> createCustomFood(Map<String, dynamic> foodData);
  Future<Food?> updateCustomFood(int foodId, Map<String, dynamic> foodData);
  Future<bool> deleteCustomFood(int foodId);
}
