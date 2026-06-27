import '../../domain/entities/meal.dart';
import '../../domain/entities/daily_calories_summary.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/meal_remote_datasource.dart';

class MealRepositoryImpl implements MealRepository {
  final MealRemoteDataSource remoteDataSource;

  const MealRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DailyCaloriesSummary?> getDailyCaloriesSummary(String date) async {
    try {
      return await remoteDataSource.getDailyCaloriesSummary(date);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Meal>?> getMealHistory({
    int page = 1,
    int pageSize = 10,
    String? date,
    String? mealType,
  }) async {
    try {
      return await remoteDataSource.getMealHistory(
        page: page,
        pageSize: pageSize,
        date: date,
        mealType: mealType,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Meal?> addMeal(Map<String, dynamic> mealData) async {
    try {
      return await remoteDataSource.addMeal(mealData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Meal?> updateMeal(int mealId, Map<String, dynamic> mealData) async {
    try {
      return await remoteDataSource.updateMeal(mealId, mealData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> deleteMeal(int mealId) async {
    try {
      return await remoteDataSource.deleteMeal(mealId);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Food>?> searchFoods(String query, {int page = 1, int pageSize = 100}) async {
    try {
      return await remoteDataSource.searchFoods(query, page: page, pageSize: pageSize);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Food>?> getFavoriteFoods() async {
    try {
      return await remoteDataSource.getFavoriteFoods();
    } catch (_) {
      return null;
    }
  }
}
