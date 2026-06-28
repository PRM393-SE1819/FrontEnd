import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/water_log_model.dart';
import '../models/water_summary_model.dart';

class WaterRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const WaterRemoteDataSource({
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

  Future<WaterSummaryModel> getDailyWaterSummary(String date) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/water/daily-summary?date=$date"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return WaterSummaryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load daily water summary: ${response.statusCode}");
    }
  }

  Future<List<WaterLogModel>> getWaterLogHistory(String date) async {
    final headers = await _getHeaders();
    var url = "${ApiConfig.baseUrl}/water/logs?page=1&pageSize=100";
    if (date.isNotEmpty) {
      url += "&date=$date";
    }
    final response = await client.get(
      Uri.parse(url),
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
      return items.map((item) => WaterLogModel.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load water log history: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> getWaterRemindersRaw() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/water/reminders"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } else {
      throw Exception("Failed to load water reminders: ${response.statusCode}");
    }
  }

  Future<WaterLogModel?> addWaterLog(double amountML) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/water/logs"),
      headers: headers,
      body: jsonEncode({"amountML": amountML}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return WaterLogModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteWaterLog(int logId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/water/logs/$logId"),
      headers: headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<WaterSummaryModel?> updateWaterGoal(double targetML) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/water/goal"),
      headers: headers,
      body: jsonEncode({"dailyTargetML": targetML}),
    );
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      // If 204 No Content, return a dummy summary or fetch current summary
      if (response.statusCode == 204 || response.body.isEmpty) {
        return WaterSummaryModel(consumedML: 0, goalML: targetML);
      }
      return WaterSummaryModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Map<String, dynamic>?> createWaterReminder(String timeOnlyStr) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/water/reminders"),
      headers: headers,
      body: jsonEncode({"reminderTime": timeOnlyStr}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> deleteWaterReminder(int reminderId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/water/reminders/$reminderId"),
      headers: headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
