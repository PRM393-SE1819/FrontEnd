import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/weight_log_model.dart';
import '../models/weight_summary_model.dart';
import '../models/weight_progress_model.dart';

class WeightRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const WeightRemoteDataSource({
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

  Future<WeightSummaryModel> getWeightSummary() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/Weight/summary"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return WeightSummaryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load weight summary: ${response.statusCode}");
    }
  }

  Future<List<WeightLogModel>> getWeightLogs({int page = 1, int pageSize = 10}) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/Weight/logs?page=$page&pageSize=$pageSize"),
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
      return items.map((item) => WeightLogModel.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load weight logs: ${response.statusCode}");
    }
  }

  Future<WeightProgressModel> getProgressStatistics(String startDate, String endDate) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/Weight/progress-statistics?startDate=$startDate&endDate=$endDate"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return WeightProgressModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load progress statistics: ${response.statusCode}");
    }
  }

  Future<WeightLogModel?> createWeightLog(double weight, double? bodyFat) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/Weight/logs"),
      headers: headers,
      body: jsonEncode({
        "weight": weight,
        "bodyFat": bodyFat,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return WeightLogModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<WeightLogModel?> updateWeightLog(int logId, double weight, double? bodyFat) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/Weight/logs/$logId"),
      headers: headers,
      body: jsonEncode({
        "weight": weight,
        "bodyFat": bodyFat,
      }),
    );
    if (response.statusCode == 200) {
      return WeightLogModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteWeightLog(int logId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/Weight/logs/$logId"),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> analyzeBodyFatFromMeasurements({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double waist,
    required double neck,
    double? hip,
  }) async {
    final headers = await _getHeaders(hasBody: true);
    final body = {
      "gender": gender,
      "age": age,
      "height": height,
      "weight": weight,
      "waist": waist,
      "neck": neck,
      if (hip != null) "hip": hip,
    };
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/ai/analyze-body-fat"),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<dynamic>?> getBodyFatHistory() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/ai/history"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded.containsKey('data')) return decoded['data'] as List;
    }
    return null;
  }

  Future<bool> deleteBodyFatHistory(int id) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/ai/history/$id"),
      headers: headers,
    );
    return response.statusCode == 200;
  }
}
