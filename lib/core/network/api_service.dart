import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  const ApiService();
  
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<Map<String, String>> _getHeaders({bool hasBody = false}) async {
    final token = await getToken();
    final headers = <String, String>{};
    if (hasBody) {
      headers["Content-Type"] = "application/json";
    }
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // Generic GET
  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    final headers = await _getHeaders(hasBody: false);
    if (kDebugMode) print("GET Request to: $url");
    return await http.get(url, headers: headers);
  }

  // Generic POST
  static Future<http.Response> post(String endpoint, Object? body) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    final headers = await _getHeaders(hasBody: true);
    if (kDebugMode) print("POST Request to: $url with body: ${jsonEncode(body)}");
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  // Generic PUT
  static Future<http.Response> put(String endpoint, Object? body) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    final headers = await _getHeaders(hasBody: true);
    if (kDebugMode) print("PUT Request to: $url with body: ${jsonEncode(body)}");
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  // Generic DELETE
  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    final headers = await _getHeaders(hasBody: false);
    if (kDebugMode) print("DELETE Request to: $url");
    return await http.delete(url, headers: headers);
  }

  // === FOOD MANAGEMENT API ===
  static Future<Map<String, dynamic>?> searchFoods(String query, {int page = 1, int pageSize = 10}) async {
    try {
      final response = await get("/foods?Query=$query&Page=$page&PageSize=$pageSize");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error searching foods: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getFoodNutrition(int foodId) async {
    try {
      final response = await get("/foods/$foodId/nutrition");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting food nutrition: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    try {
      final response = await get("/foods/barcode/$barcode");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error scanning barcode: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createCustomFood(Map<String, dynamic> foodData) async {
    try {
      final response = await post("/foods/custom", foodData);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error creating custom food: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateCustomFood(int id, Map<String, dynamic> foodData) async {
    try {
      final response = await put("/foods/custom/$id", foodData);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error updating custom food: $e");
    }
    return null;
  }

  static Future<bool> deleteCustomFood(int id) async {
    try {
      final response = await delete("/foods/custom/$id");
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error deleting custom food: $e");
    }
    return false;
  }

  // Favorite Foods
  static Future<List<dynamic>?> getFavoriteFoods() async {
    try {
      final response = await get("/favorite-foods");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting favorite foods: $e");
    }
    return null;
  }

  static Future<bool> addFavoriteFood(int foodId) async {
    try {
      final response = await post("/favorite-foods", {"foodId": foodId});
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error adding favorite food: $e");
    }
    return false;
  }

  static Future<bool> removeFavoriteFood(int foodId) async {
    try {
      final response = await delete("/favorite-foods/$foodId");
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error removing favorite food: $e");
    }
    return false;
  }

  // === MEAL TRACKING API ===
  static Future<Map<String, dynamic>?> addMeal(Map<String, dynamic> mealData) async {
    try {
      final response = await post("/meals", mealData);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error adding meal: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateMeal(int mealId, Map<String, dynamic> mealData) async {
    try {
      final response = await put("/meals/$mealId", mealData);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error updating meal: $e");
    }
    return null;
  }

  static Future<bool> deleteMeal(int mealId) async {
    try {
      final response = await delete("/meals/$mealId");
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error deleting meal: $e");
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getMealDetail(int mealId) async {
    try {
      final response = await get("/meals/$mealId");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting meal detail: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getMealHistory({int page = 1, int pageSize = 10, String? date, String? mealType}) async {
    try {
      String queryParams = "?page=$page&pageSize=$pageSize";
      if (date != null) queryParams += "&date=$date";
      if (mealType != null) queryParams += "&mealType=$mealType";
      
      final response = await get("/meals/history$queryParams");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting meal history: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDailyCaloriesSummary(String date) async {
    try {
      final response = await get("/meals/daily-summary?date=$date");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting daily calories summary: $e");
    }
    return null;
  }

  // === NUTRITION TRACKING API ===
  static Future<Map<String, dynamic>?> getCaloriesTracking(String date) async {
    try {
      final response = await get("/nutrition/calories?date=$date");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting calories tracking: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDailyNutritionSummary(String date) async {
    try {
      final response = await get("/nutrition/daily-summary?date=$date");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting daily nutrition summary: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getWeeklyStatistics(String startDate) async {
    try {
      final response = await get("/nutrition/weekly-statistics?startDate=$startDate");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting weekly statistics: $e");
    }
    return null;
  }

  // === WATER TRACKING API ===
  static Future<Map<String, dynamic>?> addWaterLog(double amountMl) async {
    try {
      final response = await post("/water/logs", {"amountML": amountMl});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error adding water log: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getWaterLogHistory({int page = 1, int pageSize = 10, String? date}) async {
    try {
      String params = "?page=$page&pageSize=$pageSize";
      if (date != null) params += "&date=$date";
      final response = await get("/water/logs$params");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return {"items": decoded};
        } else if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error getting water logs: $e");
    }
    return null;
  }

  static Future<bool> deleteWaterLog(int logId) async {
    try {
      final response = await delete("/water/logs/$logId");
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error deleting water log: $e");
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getWaterGoal() async {
    try {
      final response = await get("/water/goal");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting water goal: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateWaterGoal(double targetMl) async {
    try {
      final response = await put("/water/goal", {"dailyTargetML": targetMl});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error updating water goal: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDailyWaterSummary(String date) async {
    try {
      final response = await get("/water/daily-summary?date=$date");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting daily water summary: $e");
    }
    return null;
  }

  // Water Reminders
  static Future<List<dynamic>?> getWaterReminders() async {
    try {
      final response = await get("/water/reminders");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting water reminders: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createWaterReminder(String timeOnlyStr) async {
    try {
      final response = await post("/water/reminders", {"reminderTime": timeOnlyStr});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error creating water reminder: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateWaterReminder(int reminderId, String timeOnlyStr) async {
    try {
      final response = await put("/water/reminders/$reminderId", {"reminderTime": timeOnlyStr});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error updating water reminder: $e");
    }
    return null;
  }

  static Future<bool> deleteWaterReminder(int reminderId) async {
    try {
      final response = await delete("/water/reminders/$reminderId");
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error deleting water reminder: $e");
    }
    return false;
  }

  // === WEIGHT TRACKING API ===
  static Future<Map<String, dynamic>?> createWeightLog(double weight, double? bodyFat) async {
    try {
      final response = await post("/Weight/logs", {
        "weight": weight,
        "bodyFat": bodyFat,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error creating weight log: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateWeightLog(int logId, double weight, double? bodyFat) async {
    try {
      final response = await put("/Weight/logs/$logId", {
        "weight": weight,
        "bodyFat": bodyFat,
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error updating weight log: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getWeightLogs({int page = 1, int pageSize = 10}) async {
    try {
      final response = await get("/Weight/logs?page=$page&pageSize=$pageSize");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return {"items": decoded};
        } else if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error getting weight logs: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getWeightSummary() async {
    try {
      final response = await get("/Weight/summary");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting weight summary: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getProgressStatistics(String startDate, String endDate) async {
    try {
      final response = await get("/Weight/progress-statistics?startDate=$startDate&endDate=$endDate");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting progress statistics: $e");
    }
    return null;
  }

  // === HEALTH PROFILE API ===
  static Future<Map<String, dynamic>?> getHealthProfile() async {
    try {
      final response = await get("/health-profile");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting health profile: $e");
    }
    return null;
  }

  static Future<bool> updateHealthProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await put("/health-profile", profileData);
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error updating health profile: $e");
    }
    return false;
  }

  // Allergies
  static Future<List<dynamic>?> getAllergies() async {
    try {
      final response = await get("/health-profile/allergies");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting allergies: $e");
    }
    return null;
  }

  static Future<bool> addAllergy(String allergyName, String notes) async {
    try {
      final response = await post("/health-profile/allergies", {
        "allergyName": allergyName,
        "notes": notes,
      });
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error adding allergy: $e");
    }
    return false;
  }

  static Future<bool> deleteAllergy(int allergyId) async {
    try {
      final response = await delete("/health-profile/allergies/$allergyId");
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error deleting allergy: $e");
    }
    return false;
  }

  // Health Conditions
  static Future<List<dynamic>?> getHealthConditions() async {
    try {
      final response = await get("/health-profile/conditions");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print("Error getting health conditions: $e");
    }
    return null;
  }

  static Future<bool> addHealthCondition(String conditionName, String notes) async {
    try {
      final response = await post("/health-profile/conditions", {
        "conditionName": conditionName,
        "notes": notes,
      });
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error adding condition: $e");
    }
    return false;
  }

  static Future<bool> deleteHealthCondition(int conditionId) async {
    try {
      final response = await delete("/health-profile/conditions/$conditionId");
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Error deleting condition: $e");
    }
    return false;
  }

  // === AI NUTRITION COACH ===
  static const String _openRouterApiKeyDefine = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  static String _loadedApiKey = '';

  static Future<String> getOpenRouterApiKey() async {
    if (_openRouterApiKeyDefine.isNotEmpty) {
      return _openRouterApiKeyDefine;
    }
    if (_loadedApiKey.isNotEmpty) {
      return _loadedApiKey;
    }
    try {
      final envString = await rootBundle.loadString('env.txt');
      final lines = const LineSplitter().convert(envString);
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('OPENROUTER_API_KEY=')) {
          _loadedApiKey = trimmed.substring('OPENROUTER_API_KEY='.length).trim();
          return _loadedApiKey;
        }
      }
    } catch (_) {
      // Ignore
    }
    return '';
  }

  static const String _openRouterBaseUrl = "https://openrouter.ai/api/v1";

  static Future<Map<String, dynamic>?> sendAiNutritionMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? userContext,
  }) async {
    const models = [
      "google/gemma-4-26b-a4b-it:free",
      "google/gemini-2.0-flash-exp",
      "google/gemini-2.0-flash-lite:free",
      "meta-llama/llama-3.3-70b-instruct:free",
      "anthropic/claude-3.5-haiku",
    ];

    try {
      final systemPrompt = """You are NutriAI, a professional AI nutrition coach and dietitian. 
You help users with:
- Personalized nutrition advice based on their health data
- Meal planning and food recommendations
- Understanding macronutrients (protein, carbs, fat) and micronutrients
- Calorie management and weight goals
- Interpreting their nutrition tracking data
- Healthy eating habits and dietary tips

${userContext != null ? '''
Current user data:
- Calories today: ${userContext['calories'] ?? 'N/A'} / ${userContext['calorieTarget'] ?? 'N/A'} kcal
- Protein: ${userContext['protein'] ?? 'N/A'}g / ${userContext['proteinTarget'] ?? 'N/A'}g
- Carbs: ${userContext['carbs'] ?? 'N/A'}g / ${userContext['carbTarget'] ?? 'N/A'}g
- Fat: ${userContext['fat'] ?? 'N/A'}g / ${userContext['fatTarget'] ?? 'N/A'}g
- Weight: ${userContext['weight'] ?? 'N/A'} kg
''' : ''}

Respond in the same language as the user. Be concise, friendly, and practical. 
If the user writes in Vietnamese, respond in Vietnamese. If in English, respond in English.
Keep responses under 200 words unless detailed analysis is requested.""";

      final messages = [
        {"role": "system", "content": systemPrompt},
        ...conversationHistory,
        {"role": "user", "content": userMessage},
      ];

      final apiKey = await getOpenRouterApiKey();
      if (apiKey.isEmpty) {
        if (kDebugMode) print("Error: OpenRouter API Key is empty");
        return null;
      }

      for (final model in models) {
        try {
          if (kDebugMode) print("Trying AI model: $model...");
          final isReasoningModel = model.contains("gemma-4");

          final body = {
            "model": model,
            "messages": messages,
            "max_tokens": 800,
            "temperature": 0.7,
          };

          if (isReasoningModel) {
            body["reasoning"] = {"enabled": true};
          }

          final response = await http.post(
            Uri.parse("$_openRouterBaseUrl/chat/completions"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
              "HTTP-Referer": "https://ainutritiontracking.onrender.com",
              "X-Title": "NutriAI",
            },
            body: jsonEncode(body),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final choices = data['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final message = choices[0]['message'] as Map<String, dynamic>;
              return {
                "content": message['content'] as String?,
                "reasoning_details": message['reasoning_details'],
              };
            }
          } else {
            if (kDebugMode) {
              print("AI API Error for model $model: ${response.statusCode} ${response.body}");
            }
          }
        } catch (innerError) {
          if (kDebugMode) print("Error calling model $model: $innerError");
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error sending AI message: $e");
    }
    return null;
  }

  static Future<String?> analyzeFoodImage({
    required String imageBase64,
    required String mimeType,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final contextNote = userContext != null
          ? "User's current nutrition today: ${userContext['calories']}/${userContext['calorieTarget']} kcal, "
              "Protein: ${userContext['protein']}g/${userContext['proteinTarget']}g, "
              "Carbs: ${userContext['carbs']}g/${userContext['carbTarget']}g, "
              "Fat: ${userContext['fat']}g/${userContext['fatTarget']}g."
          : "No context available.";

      final prompt = """
You are a professional nutritionist and food recognition expert. Analyze food images and return ONLY a valid JSON object. Identify all food items visible in the image and estimate portion size based on visual cues such as plate size, hand reference, and utensils. Use standard Vietnamese and Asian food database when applicable. If uncertain about a dish, provide the closest match with a confidence score. Never return explanatory text outside the JSON structure.

USER PROMPT — Scan món ăn:
Analyze this food image and return the dish name in both Vietnamese and English, a confidence score from 0 to 1, estimated portion size, and per-serving nutrition including calories, protein in grams, carbohydrates in grams, fat in grams, fiber in grams, and sodium in milligrams. Also return a list of detected ingredients, dietary flags for vegetarian, vegan, gluten-free, and high-protein, and up to 2 alternative dish guesses with their confidence scores if uncertain.

USER PROMPT — Nhiều món trong 1 ảnh:
This image contains multiple food items. Analyze each item separately and return the name, portion, calories, protein, carbs, and fat for each. Also return the total calories across all items and a meal type suggestion — breakfast, lunch, dinner, or snack.

USER PROMPT — Ước lượng khẩu phần:
Based on the image, compare the plate or bowl size to a standard reference, account for visible density and stacking, and estimate the actual portion as a multiplier — for example 0.5 for half a serving or 1.5 for one and a half servings. Return the multiplier, estimated weight in grams, and a brief note.

USER PROMPT — Ảnh không rõ / fallback:
If the image does not clearly show food or the confidence is below 0.4, return an error response indicating low confidence, a message in Vietnamese saying the dish could not be recognized, and a suggestion to retake the photo with better lighting or from a top-down angle.

Context information about the user:
$contextNote

Your response MUST be a single, valid JSON object following this exact schema:
{
  "success": true / false,
  "confidence": 0.0 to 1.0,
  "message": "Vietnamese description of result or scan note",
  "meal_type": "breakfast" / "lunch" / "dinner" / "snack",
  "total_nutrition": {
    "calories": integer,
    "protein": double (g),
    "carbs": double (g),
    "fat": double (g),
    "fiber": double (g),
    "sodium": double (mg)
  },
  "items": [
    {
      "name_vi": "Vietnamese Name",
      "name_en": "English Name",
      "portion_size": "1 plate/1 bowl etc",
      "portion_multiplier": double (e.g. 1.0, 0.5, 1.2),
      "weight_grams": double,
      "nutrition": {
        "calories": integer,
        "protein": double,
        "carbs": double,
        "fat": double,
        "fiber": double,
        "sodium": double
      },
      "ingredients": ["ingredient 1", "ingredient 2"],
      "dietary_flags": {
        "vegetarian": true/false,
        "vegan": true/false,
        "gluten_free": true/false,
        "high_protein": true/false
      }
    }
  ],
  "alternatives": [
    {
      "name": "Alternative dish name",
      "confidence": double
    }
  ],
  "health_rating": "Tốt" / "Trung bình" / "Hạn chế",
  "advice": "Vietnamese advice tailored to user's daily goals"
}
""";

      final apiKey = await getOpenRouterApiKey();
      final response = await http.post(
        Uri.parse("$_openRouterBaseUrl/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
          "HTTP-Referer": "https://ainutritiontracking.onrender.com",
          "X-Title": "NutriAI",
        },
        body: jsonEncode({
          "model": "google/gemini-2.0-flash-exp:free",
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:$mimeType;base64,$imageBase64",
                  },
                },
                {
                  "type": "text",
                  "text": prompt,
                },
              ],
            }
          ],
          "max_tokens": 800,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] as String?;
        }
      } else {
        if (kDebugMode) print("Vision API Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) print("Error analyzing food image: $e");
    }
    return null;
  }
}
