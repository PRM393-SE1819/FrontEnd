import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_config.dart';

class AiCoachRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage storage;

  const AiCoachRemoteDataSource({
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

  Future<Map<String, dynamic>?> getHealthProfile() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/health-profile"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<dynamic>?> getHealthConditions() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/conditions"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<List<dynamic>?> getAllergies() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/health-profile/allergies"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<List<dynamic>?> getMealHistory(String date) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/meals/history?date=$date"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      } else if (decoded is Map<String, dynamic>) {
        return decoded['items'] as List<dynamic>?;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendAiNutritionMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? userContext,
  }) async {
    final headers = await _getHeaders(hasBody: true);
    final url = Uri.parse("${ApiConfig.baseUrl}/ai/chat");

    String finalMessage = userMessage;
    if (userContext != null && userContext.isNotEmpty) {
      finalMessage = """
[BỐI CẢNH DINH DƯỠNG & SỨC KHỎE CỦA TÔI]
- Giới tính: ${userContext['gender'] ?? 'N/A'}
- Ngày sinh: ${userContext['dateOfBirth'] ?? 'N/A'} (Tuổi: ${userContext['age'] ?? 'N/A'})
- Chiều cao: ${userContext['height'] ?? 'N/A'} cm
- Cân nặng: ${userContext['weight'] ?? 'N/A'} kg
- Mức độ hoạt động: ${userContext['activityLevel'] ?? 'N/A'}
- Mục tiêu: ${userContext['goal'] ?? 'N/A'} (Cân nặng đích: ${userContext['targetWeight'] ?? 'N/A'} kg)
- Chỉ số BMI: ${userContext['bmi'] ?? 'N/A'} | Tỷ lệ mỡ: ${userContext['bodyFat'] ?? 'N/A'}%
- Bệnh lý nền: ${userContext['conditions'] ?? 'Không có'}
- Dị ứng thức ăn: ${userContext['allergies'] ?? 'Không có'}

[NHẬT KÝ HÔM NAY - Ngày ${userContext['todayDate'] ?? ''}]
- Nước uống: ${userContext['waterConsumed'] ?? 0} ml / ${userContext['waterGoal'] ?? 2000} ml
- Calo tiêu thụ: ${userContext['calories'] ?? 0} kcal / ${userContext['calorieTarget'] ?? 2000} kcal
- Macro nạp/Mục tiêu: Đạm: ${userContext['protein'] ?? 0}g / ${userContext['proteinTarget'] ?? 150}g | Tinh bột: ${userContext['carbs'] ?? 0}g / ${userContext['carbTarget'] ?? 250}g | Chất béo: ${userContext['fat'] ?? 0}g / ${userContext['fatTarget'] ?? 70}g
- Các món đã ăn hôm nay:
${userContext['mealsList'] ?? 'Chưa ghi nhận bữa ăn nào.'}

[HƯỚNG DẪN DÀNH CHO AI]
- Bạn là một Trợ lý Dinh dưỡng AI chuyên nghiệp.
- Hãy dựa vào [BỐI CẢNH DINH DƯỠNG & SỨC KHỎE CỦA TÔI] và [NHẬT KÝ HÔM NAY] ở trên để tư vấn, phân tích và đưa ra kế hoạch ăn uống/uống nước cá nhân hóa cho tôi.
- Trả lời bằng tiếng Việt một cách tự nhiên, chuyên nghiệp và thân thiện.
- Nếu tôi hỏi về kế hoạch hoặc gợi ý thực đơn, hãy thiết kế các bữa ăn cụ thể phù hợp với mục tiêu, chiều cao, cân nặng, cấp độ hoạt động và tránh các thực phẩm tôi bị dị ứng hoặc không tốt cho bệnh nền của tôi.

[CÂU HỎI CỦA NGƯỜI DÙNG]
$userMessage
""";
    }

    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({"message": finalMessage}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        "content": decoded['answer'] ?? decoded['content'] ?? "Không thể nhận phản hồi từ AI.",
        "reasoning_details": decoded['reasoning_details'] ?? decoded['reasoningDetails'],
      };
    } else {
      return {
        "content": "Lỗi kết nối máy chủ AI (Code ${response.statusCode}). Vui lòng thử lại sau.",
        "reasoning_details": null,
      };
    }
  }

  Future<String> _translateToVietnamese(String text) async {
    if (text.isEmpty) return text;
    try {
      final headers = await _getHeaders(hasBody: true);
      final url = Uri.parse("${ApiConfig.baseUrl}/ai/chat");
      final response = await client.post(
        url,
        headers: headers,
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
    } catch (_) {}
    return text;
  }

  Future<String?> analyzeFoodImage({
    required String imageBase64,
    required String mimeType,
    Map<String, dynamic>? userContext,
  }) async {
    final token = await storage.read(key: 'jwt_token');
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      
      final rawFoodName = decoded['foodName'] ?? "Món ăn";
      final rawDescription = decoded['description'] ?? "";

      if (rawFoodName.toString().toLowerCase() == 'unknown') {
        String translatedError = "Không thể phân tích dữ liệu hình ảnh. Vui lòng chụp hoặc chọn ảnh rõ nét hơn và thử lại.";
        if (rawDescription.isNotEmpty) {
          final lowerDesc = rawDescription.toString().toLowerCase();
          if (lowerDesc.contains("could not analyze") || lowerDesc.contains("clearer image") || lowerDesc.contains("ensure the image is clear")) {
            translatedError = "Không thể phân tích hình ảnh này. Vui lòng đảm bảo hình ảnh chụp món ăn rõ nét và thử lại.";
          } else {
            try {
              final translated = await _translateToVietnamese(rawDescription);
              if (translated.isNotEmpty && 
                  !translated.toLowerCase().contains("couldn't process") && 
                  !translated.toLowerCase().contains("sorry")) {
                translatedError = translated;
              }
            } catch (_) {}
          }
        }
        return jsonEncode({
          "success": false,
          "message": translatedError,
        });
      }

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
      return jsonEncode({
        "success": false,
        "message": "Có lỗi từ máy chủ phân tích ảnh: Code ${response.statusCode}"
      });
    }
  }

  Future<Map<String, dynamic>?> searchFoods(String query) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse("${ApiConfig.baseUrl}/foods?Query=$query&Page=1&PageSize=10"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> addMeal(Map<String, dynamic> mealData) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/meals"),
      headers: headers,
      body: jsonEncode(mealData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> estimateCalories(String foodDescription) async {
    final headers = await _getHeaders(hasBody: true);
    final response = await client.post(
      Uri.parse("${ApiConfig.baseUrl}/ai/calorie-estimate"),
      headers: headers,
      body: jsonEncode({"foodDescription": foodDescription}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> deleteAllChatHistory() async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse("${ApiConfig.baseUrl}/ai/chat/history"),
      headers: headers,
    );
    return response.statusCode == 200;
  }
}
