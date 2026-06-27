import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/meal_model.dart';
import '../models/daily_calories_summary_model.dart';
import '../models/food_model.dart';

class MealRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const MealRemoteDataSource({
    required this.client,
    required this.storage,
  });

  Future<Map<String, String>> _getHeaders({bool hasBody = false}) async {
    final token = await storage.read(key: 'jwt_token');
    final headers = <String, String>{};
    if (hasBody) {
      headers["Content-Type"] = "application/json";
    }
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Future<DailyCaloriesSummaryModel> getDailyCaloriesSummary(String date) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/meals/daily-summary?date=$date"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return DailyCaloriesSummaryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load daily calories summary: ${response.statusCode}");
    }
  }

  Future<List<MealModel>> getMealHistory({
    int page = 1,
    int pageSize = 10,
    String? date,
    String? mealType,
  }) async {
    final headers = await _getHeaders();
    String queryParams = "?page=$page&pageSize=$pageSize";
    if (date != null) queryParams += "&date=$date";
    if (mealType != null) queryParams += "&mealType=$mealType";

    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/meals/history$queryParams"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> items = [];
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        items = decoded['items'] ?? [];
      }
      return items.map((e) => MealModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load meal history: ${response.statusCode}");
    }
  }

  Future<MealModel?> addMeal(Map<String, dynamic> mealData) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/meals"),
      headers: headers,
      body: jsonEncode(mealData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return MealModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<MealModel?> updateMeal(int mealId, Map<String, dynamic> mealData) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/meals/$mealId"),
      headers: headers,
      body: jsonEncode(mealData),
    );
    if (response.statusCode == 200) {
      return MealModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteMeal(int mealId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/meals/$mealId"),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  Future<List<FoodModel>> searchFoods(String query, {int page = 1, int pageSize = 100}) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/foods?Query=$query&Page=$page&PageSize=$pageSize"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> items = [];
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        items = decoded['items'] ?? [];
      }
      
      // Filter custom foods hidden locally if any
      final hiddenStr = await storage.read(key: 'hidden_custom_food_ids') ?? '';
      final hiddenIds = hiddenStr.split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();
      if (hiddenIds.isNotEmpty) {
        items.removeWhere((item) => item is Map && hiddenIds.contains(item['foodId']));
      }

      return items.map((e) => FoodModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to search foods: ${response.statusCode}");
    }
  }

  Future<List<FoodModel>> getFavoriteFoods() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/favorite-foods"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body) as List<dynamic>;
      final hiddenStr = await storage.read(key: 'hidden_custom_food_ids') ?? '';
      final hiddenIds = hiddenStr.split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();

      final mappedList = rawList.map((item) {
        if (item is Map && item.containsKey('food') && item['food'] != null) {
          return item['food'];
        }
        return item;
      }).toList();

      if (hiddenIds.isNotEmpty) {
        mappedList.removeWhere((item) => item is Map && hiddenIds.contains(item['foodId']));
      }

      return mappedList.map((e) => FoodModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load favorite foods: ${response.statusCode}");
    }
  }
}
