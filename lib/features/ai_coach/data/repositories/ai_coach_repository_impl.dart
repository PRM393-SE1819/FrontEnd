import '../../domain/repositories/ai_coach_repository.dart';
import '../datasources/ai_coach_remote_datasource.dart';

class AiCoachRepositoryImpl implements AiCoachRepository {
  final AiCoachRemoteDataSource remoteDataSource;

  const AiCoachRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>?> getDailyNutritionSummary(String date) async {
    return await remoteDataSource.getDailyNutritionSummary(date);
  }

  @override
  Future<Map<String, dynamic>?> getDailyWaterSummary(String date) async {
    return await remoteDataSource.getDailyWaterSummary(date);
  }

  @override
  Future<Map<String, dynamic>?> getWeightSummary() async {
    return await remoteDataSource.getWeightSummary();
  }

  @override
  Future<Map<String, dynamic>?> getHealthProfile() async {
    return await remoteDataSource.getHealthProfile();
  }

  @override
  Future<List<dynamic>?> getHealthConditions() async {
    return await remoteDataSource.getHealthConditions();
  }

  @override
  Future<List<dynamic>?> getAllergies() async {
    return await remoteDataSource.getAllergies();
  }

  @override
  Future<List<dynamic>?> getMealHistory(String date) async {
    return await remoteDataSource.getMealHistory(date);
  }

  @override
  Future<Map<String, dynamic>?> sendAiNutritionMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? userContext,
  }) async {
    return await remoteDataSource.sendAiNutritionMessage(
      userMessage: userMessage,
      conversationHistory: conversationHistory,
      userContext: userContext,
    );
  }

  @override
  Future<String?> analyzeFoodImage({
    required String imageBase64,
    required String mimeType,
    Map<String, dynamic>? userContext,
  }) async {
    return await remoteDataSource.analyzeFoodImage(
      imageBase64: imageBase64,
      mimeType: mimeType,
      userContext: userContext,
    );
  }

  @override
  Future<Map<String, dynamic>?> searchFoods(String query) async {
    return await remoteDataSource.searchFoods(query);
  }

  @override
  Future<Map<String, dynamic>?> addMeal(Map<String, dynamic> mealData) async {
    return await remoteDataSource.addMeal(mealData);
  }

  @override
  Future<Map<String, dynamic>?> estimateCalories(String foodDescription) async {
    return await remoteDataSource.estimateCalories(foodDescription);
  }

  @override
  Future<bool> deleteAllChatHistory() async {
    return await remoteDataSource.deleteAllChatHistory();
  }
}
