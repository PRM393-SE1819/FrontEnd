import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  static Future<List<dynamic>?> getFavoriteFoods() async {
    try {
      final response = await get("/favorite-foods");
      if (response.statusCode == 200) {
        final rawList = jsonDecode(response.body) as List<dynamic>;
        return rawList.map((item) {
          if (item is Map && item.containsKey('food') && item['food'] != null) {
            return item['food'];
          }
          return item;
        }).toList();
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
  static Future<void> saveReminderEnabledState(int reminderId, bool isEnabled) async {
    await _storage.write(key: 'reminder_${reminderId}_enabled', value: isEnabled.toString());
  }

  static Future<bool> getReminderEnabledState(int reminderId) async {
    final val = await _storage.read(key: 'reminder_${reminderId}_enabled');
    return val != 'false'; // Defaults to true if not found/set
  }

  static Future<List<dynamic>?> getWaterReminders() async {
    try {
      final response = await get("/water/reminders");
      if (response.statusCode == 200) {
        final rawList = jsonDecode(response.body) as List<dynamic>;
        final updatedList = <dynamic>[];
        for (var item in rawList) {
          if (item is Map) {
            final copy = Map<String, dynamic>.from(item);
            final remId = copy['reminderId'] as int?;
            if (remId != null) {
              copy['isEnabled'] = await getReminderEnabledState(remId);
            } else {
              copy['isEnabled'] = true;
            }
            updatedList.add(copy);
          } else {
            updatedList.add(item);
          }
        }
        return updatedList;
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
    try {
      final token = await getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/ai/chat");

      if (kDebugMode) print("Sending Chat Request to Backend: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "message": userMessage,
        }),
      );

      if (kDebugMode) {
        print("Backend Chat Response status: ${response.statusCode}");
        print("Backend Chat Response body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          "content": decoded['answer'] ?? decoded['content'] ?? "Không thể nhận phản hồi từ AI.",
          "reasoning_details": decoded['reasoning_details'] ?? decoded['reasoningDetails'],
        };
      } else {
        if (kDebugMode) print("Backend Chat Error: ${response.statusCode} ${response.body}");
        return {
          "content": "Lỗi kết nối máy chủ AI (Code ${response.statusCode}). Vui lòng thử lại sau.",
          "reasoning_details": null,
        };
      }
    } catch (e) {
      if (kDebugMode) print("Error in sendAiNutritionMessage: $e");
      return {
        "content": "Không thể kết nối đến máy chủ AI: $e",
        "reasoning_details": null,
      };
    }
  }

  static Future<String> _translateToVietnamese(String text) async {
    if (text.isEmpty) return text;
    try {
      final token = await getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/ai/chat");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "message": "Dịch cụm từ hoặc câu này sang tiếng Việt (chỉ trả về bản dịch tiếng Việt duy nhất, không thêm bất kỳ bình luận hay văn bản giải thích nào khác): \"$text\"",
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final answer = (decoded['answer'] ?? decoded['content'] ?? "").toString().trim();
        if (answer.startsWith('"') && answer.endsWith('"')) {
          return answer.substring(1, answer.length - 1);
        }
        return answer.isNotEmpty ? answer : text;
      }
    } catch (_) {
      // Fallback
    }
    return text;
  }

  static Future<String?> analyzeFoodImage({
    required String imageBase64,
    required String mimeType,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final token = await getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/ai/analyze-image");

      final request = http.MultipartRequest("POST", url);

      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }

      final bytes = base64Decode(imageBase64);
      final multipartFile = http.MultipartFile.fromBytes(
        'Image',
        bytes,
        filename: 'meal_image.jpg',
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      if (kDebugMode) print("Sending multipart request to: $url");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print("Backend Response: ${response.statusCode} - ${response.body}");
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        
        final rawFoodName = decoded['foodName'] ?? "Món ăn";
        final rawDescription = decoded['description'] ?? "";

        // Run translations in parallel for speed!
        final translations = await Future.wait([
          _translateToVietnamese(rawFoodName),
          _translateToVietnamese(rawDescription),
        ]);

        final foodNameVi = translations[0];
        final descriptionVi = translations[1];

        final rawWarnings = decoded['warnings'] as List? ?? [];
        final translatedWarnings = rawWarnings.map((w) {
          final str = w.toString();
          if (str.contains("HIGH CALORIES")) {
            return str
                .replaceAll("⚠️ HIGH CALORIES:", "⚠️ CALO CAO:")
                .replaceAll("exceeds", "vượt quá")
                .replaceAll("kcal per meal.", "kcal mỗi bữa ăn.");
          } else if (str.contains("HIGH PROTEIN")) {
            return str
                .replaceAll("⚠️ HIGH PROTEIN:", "⚠️ ĐẠM CAO:")
                .replaceAll("per meal may strain kidneys.", "mỗi bữa ăn có thể gây áp lực cho thận.");
          } else if (str.contains("HIGH CARBS")) {
            return str
                .replaceAll("⚠️ HIGH CARBS:", "⚠️ CARB CAO:")
                .replaceAll("per meal may spike blood sugar.", "mỗi bữa ăn có thể làm tăng đường huyết nhanh.");
          } else if (str.contains("HIGH FAT")) {
            return str
                .replaceAll("⚠️ HIGH FAT:", "⚠️ CHẤT BÉO CAO:")
                .replaceAll("per meal increases cardiovascular risk.", "mỗi bữa ăn làm tăng nguy cơ tim mạch.");
          }
          return str;
        }).toList();

        // Map backend's FoodImageAnalysisResponseDto to the frontend's expected schema
        final mappedJson = {
          "success": true,
          "confidence": 0.95,
          "message": "Phát hiện món: $foodNameVi",
          "meal_type": "lunch",
          "total_nutrition": {
            "calories": (decoded['estimatedCalories'] as num?)?.round() ?? 0,
            "protein": (decoded['protein'] as num?)?.toDouble() ?? 0.0,
            "carbs": (decoded['carbs'] as num?)?.toDouble() ?? 0.0,
            "fat": (decoded['fat'] as num?)?.toDouble() ?? 0.0,
            "fiber": 0.0,
            "sodium": 0.0
          },
          "items": [
            {
              "name_vi": foodNameVi,
              "name_en": rawFoodName,
              "portion_size": "1 phần",
              "portion_multiplier": 1.0,
              "weight_grams": 100.0,
              "nutrition": {
                "calories": (decoded['estimatedCalories'] as num?)?.round() ?? 0,
                "protein": (decoded['protein'] as num?)?.toDouble() ?? 0.0,
                "carbs": (decoded['carbs'] as num?)?.toDouble() ?? 0.0,
                "fat": (decoded['fat'] as num?)?.toDouble() ?? 0.0,
                "fiber": 0.0,
                "sodium": 0.0
              },
              "ingredients": [],
              "dietary_flags": {
                "vegetarian": false,
                "vegan": false,
                "gluten_free": false,
                "high_protein": ((decoded['protein'] as num?)?.toDouble() ?? 0.0) >= 20.0
              }
            }
          ],
          "alternatives": [],
          "health_rating": translatedWarnings.isNotEmpty ? "Hạn chế" : "Tốt",
          "advice": "$descriptionVi${translatedWarnings.isNotEmpty ? '\nCảnh báo:\n' + translatedWarnings.join('\n') : ''}"
        };

        return jsonEncode(mappedJson);
      } else {
        if (kDebugMode) print("Backend Image Analysis Error: ${response.statusCode} ${response.body}");
        return jsonEncode({
          "success": false,
          "message": "Có lỗi từ máy chủ phân tích ảnh: Code ${response.statusCode}"
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error analyzing food image: $e");
      return jsonEncode({
        "success": false,
        "message": "Không thể kết nối đến máy chủ: $e"
      });
    }
  }
}
