abstract class AiCoachRepository {
  Future<Map<String, dynamic>?> getDailyNutritionSummary(String date);
  Future<Map<String, dynamic>?> getDailyWaterSummary(String date);
  Future<Map<String, dynamic>?> getWeightSummary();
  Future<Map<String, dynamic>?> getHealthProfile();
  Future<List<dynamic>?> getHealthConditions();
  Future<List<dynamic>?> getAllergies();
  Future<List<dynamic>?> getMealHistory(String date);
  
  Future<Map<String, dynamic>?> sendAiNutritionMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? userContext,
  });

  Future<String?> analyzeFoodImage({
    required String imageBase64,
    required String mimeType,
    Map<String, dynamic>? userContext,
  });

  Future<Map<String, dynamic>?> searchFoods(String query);
  Future<Map<String, dynamic>?> addMeal(Map<String, dynamic> mealData);
  Future<Map<String, dynamic>?> estimateCalories(String foodDescription);
  Future<bool> deleteAllChatHistory();
}
