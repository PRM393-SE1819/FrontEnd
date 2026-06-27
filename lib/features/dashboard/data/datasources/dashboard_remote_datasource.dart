import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class DashboardRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const DashboardRemoteDataSource({
    required this.client,
    required this.storage,
  });

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: 'jwt_token');
    final headers = <String, String>{};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Future<Map<String, dynamic>?> getDailyNutritionSummary(String date) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/nutrition/daily-summary?date=$date"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getDailyWaterSummary(String date) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/water/daily-summary?date=$date"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeightSummary() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/Weight/summary"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}
