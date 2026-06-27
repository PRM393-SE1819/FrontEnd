import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/user_profile_model.dart';
import '../models/allergy_model.dart';
import '../models/health_condition_model.dart';

class ProfileRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const ProfileRemoteDataSource({
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

  Future<UserProfileModel?> getHealthProfile() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/health-profile"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return UserProfileModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> updateHealthProfile(Map<String, dynamic> profileData) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/health-profile"),
      headers: headers,
      body: jsonEncode(profileData),
    );
    return response.statusCode == 200;
  }

  Future<List<AllergyModel>> getAllergies() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/allergies"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => AllergyModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> addAllergy(String allergyName, String notes) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/allergies"),
      headers: headers,
      body: jsonEncode({
        "allergyName": allergyName,
        "notes": notes,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateAllergy(int allergyId, String allergyName) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/allergies/$allergyId"),
      headers: headers,
      body: jsonEncode({"allergyName": allergyName}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteAllergy(int allergyId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/allergies/$allergyId"),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  Future<List<HealthConditionModel>> getHealthConditions() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/conditions"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => HealthConditionModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> addHealthCondition(String conditionName, String notes) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/conditions"),
      headers: headers,
      body: jsonEncode({
        "conditionName": conditionName,
        "notes": notes,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateHealthCondition(int conditionId, String conditionName, String notes) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.put(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/conditions/$conditionId"),
      headers: headers,
      body: jsonEncode({
        "conditionName": conditionName,
        "notes": notes,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteHealthCondition(int conditionId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/conditions/$conditionId"),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  Future<bool> logout() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        final headers = await _getHeaders();
        await client.post(
          Uri.parse("${ApiConfig.baseUrl}/Auth/logout"),
          headers: headers,
          body: null,
        );
      }
    } catch (_) {}
    await storage.deleteAll();
    return true;
  }
}
