import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../../meal/data/models/food_model.dart';

class FoodRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const FoodRemoteDataSource({
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

  Future<List<FoodModel>?> getFavoriteFoods() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/favorite-foods"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final rawList = jsonDecode(response.body) as List<dynamic>;
      final mappedList = rawList.map((item) {
        if (item is Map && item.containsKey('food') && item['food'] != null) {
          return item['food'];
        }
        return item;
      }).toList();
      return mappedList.map((item) => FoodModel.fromJson(item)).toList();
    }
    return null;
  }

  Future<bool> addFavoriteFood(int foodId) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/favorite-foods"),
      headers: headers,
      body: jsonEncode({"foodId": foodId}),
    );
    return response.statusCode == 200;
  }

  Future<bool> removeFavoriteFood(int foodId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/favorite-foods/$foodId"),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> searchFoods(String query, {int page = 1, int pageSize = 100}) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/foods?Query=$query&Page=$page&PageSize=$pageSize"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('items') && data['items'] is List) {
        final List<dynamic> items = data['items'];
        data['items'] = items.map((item) => FoodModel.fromJson(item)).toList();
      }
      return data;
    }
    return null;
  }

  Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/foods/barcode/$barcode"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey('food') && decoded['food'] != null) {
        decoded['food'] = FoodModel.fromJson(decoded['food']);
      }
      return decoded;
    }
    return null;
  }

  Future<FoodModel?> createCustomFood(Map<String, dynamic> foodData) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/foods/custom"),
      headers: headers,
      body: jsonEncode(foodData),
    );
    if (response.statusCode == 200) {
      return FoodModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<FoodModel?> updateCustomFood(int id, Map<String, dynamic> foodData) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/foods/custom/$id"),
      headers: headers,
      body: jsonEncode(foodData),
    );
    if (response.statusCode == 200) {
      return FoodModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteCustomFood(int id) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/foods/custom/$id"),
      headers: headers,
    );
    return response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404;
  }
}
