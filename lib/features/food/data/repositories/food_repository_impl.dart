import '../../../meal/domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/food_remote_datasource.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodRemoteDataSource remoteDataSource;

  const FoodRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Food>> getFavoriteFoods() async {
    final results = await remoteDataSource.getFavoriteFoods();
    return results ?? [];
  }

  @override
  Future<bool> addFavoriteFood(int foodId) async {
    return await remoteDataSource.addFavoriteFood(foodId);
  }

  @override
  Future<bool> removeFavoriteFood(int foodId) async {
    return await remoteDataSource.removeFavoriteFood(foodId);
  }

  @override
  Future<Map<String, dynamic>?> searchFoods(String query, {int page = 1, int pageSize = 100}) async {
    return await remoteDataSource.searchFoods(query, page: page, pageSize: pageSize);
  }

  @override
  Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    return await remoteDataSource.scanBarcode(barcode);
  }

  @override
  Future<Food?> createCustomFood(Map<String, dynamic> foodData) async {
    return await remoteDataSource.createCustomFood(foodData);
  }

  @override
  Future<Food?> updateCustomFood(int foodId, Map<String, dynamic> foodData) async {
    return await remoteDataSource.updateCustomFood(foodId, foodData);
  }

  @override
  Future<bool> deleteCustomFood(int foodId) async {
    return await remoteDataSource.deleteCustomFood(foodId);
  }
}
