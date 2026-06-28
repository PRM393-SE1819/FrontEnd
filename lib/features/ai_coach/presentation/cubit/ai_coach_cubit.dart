import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../di/dependency_injection.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../domain/repositories/ai_coach_repository.dart';
import '../../domain/entities/chat_message.dart';
import 'ai_coach_state.dart';

class AiCoachCubit extends Cubit<AiCoachState> {
  final AiCoachRepository repository;
  final FlutterSecureStorage storage;

  AiCoachCubit({required this.repository, required this.storage}) : super(AiCoachInitial());

  Future<void> loadInitialData() async {
    emit(AiCoachLoading());
    try {
      // 1. Load recent scans from storage
      List<Map<String, dynamic>> recentScans = [];
      try {
        final jsonStr = await storage.read(key: 'recent_scans');
        if (jsonStr != null) {
          final List<dynamic> list = jsonDecode(jsonStr);
          recentScans = list
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['id'] != 'demo1' && item['id'] != 'demo2')
              .toList();
        }
      } catch (_) {}

      // 2. Fetch all user context metrics in parallel
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await Future.wait([
        repository.getDailyNutritionSummary(today),
        repository.getWeightSummary(),
        repository.getHealthProfile(),
        repository.getHealthConditions(),
        repository.getAllergies(),
        repository.getDailyWaterSummary(today),
        repository.getMealHistory(today),
      ]);

      final nutrition = results[0] as Map<String, dynamic>?;
      final weight = results[1] as Map<String, dynamic>?;
      final profile = results[2] as Map<String, dynamic>?;
      final conditions = results[3] as List<dynamic>? ?? [];
      final allergies = results[4] as List<dynamic>? ?? [];
      final waterSummary = results[5] as Map<String, dynamic>?;
      final mealHistory = results[6] as List<dynamic>?;

      String conditionsStr = conditions.isEmpty
          ? "Không có"
          : conditions.map((c) {
              final name = c['conditionName'] ?? '';
              final notes = c['notes'] ?? '';
              return notes.toString().isNotEmpty ? "$name ($notes)" : name;
            }).join(", ");

      String allergiesStr = allergies.isEmpty
          ? "Không có"
          : allergies.map((a) => a['allergyName'] ?? '').join(", ");

      String mealsListStr = "Chưa có bữa ăn nào được ghi nhận hôm nay.";
      if (mealHistory != null && mealHistory.isNotEmpty) {
        final List<String> mealStrings = [];
        for (var m in mealHistory) {
          final type = m['mealType'] ?? 'Bữa ăn';
          final totalCal = (m['totalCalories'] as num?)?.round() ?? 0;
          final List<dynamic> foodItems = m['items'] ?? [];
          final foodDetails = foodItems.map((f) => "${f['foodName']} (${(f['quantity'] as num).round()}g)").join(", ");
          mealStrings.add("- $type ($totalCal kcal): $foodDetails");
        }
        mealsListStr = mealStrings.join("\n");
      }

      final userContext = {
        'calories': (nutrition?['caloriesConsumed'] as num?)?.round() ?? 0,
        'calorieTarget': (nutrition?['caloriesTarget'] as num?)?.round() ?? 2000,
        'protein': (nutrition?['proteinConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
        'proteinTarget': (nutrition?['proteinTarget'] as num?)?.round() ?? 150,
        'carbs': (nutrition?['carbConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
        'carbTarget': (nutrition?['carbTarget'] as num?)?.round() ?? 250,
        'fat': (nutrition?['fatConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
        'fatTarget': (nutrition?['fatTarget'] as num?)?.round() ?? 70,
        'weight': (weight?['currentWeight'] as num?)?.toString() ?? 'N/A',
        
        'gender': profile?['gender'] ?? 'N/A',
        'dateOfBirth': profile?['dateOfBirth'] ?? 'N/A',
        'age': profile?['dateOfBirth'] != null 
            ? (DateTime.now().year - DateTime.parse(profile!['dateOfBirth']).year).toString()
            : 'N/A',
        'height': profile?['height']?.toString() ?? 'N/A',
        'activityLevel': profile?['activityLevel'] ?? 'N/A',
        'goal': profile?['goal'] ?? 'N/A',
        'targetWeight': profile?['targetWeight']?.toString() ?? 'N/A',
        'bmi': profile?['bmi']?.toStringAsFixed(1) ?? 'N/A',
        'bodyFat': profile?['bodyFat']?.toStringAsFixed(1) ?? 'N/A',
        'conditions': conditionsStr,
        'allergies': allergiesStr,
        'waterConsumed': (waterSummary?['consumedML'] as num?)?.round() ?? 0,
        'waterGoal': (waterSummary?['goalML'] as num?)?.round() ?? 2000,
        'mealsList': mealsListStr,
        'todayDate': today,
      };

      // 3. Emit loaded state with welcome message if empty
      final List<ChatMessage> messages = [
        ChatMessage(
          text: "Xin chào! Tôi là NutriAI, trợ lý dinh dưỡng AI của bạn 🥗\n\nTôi có thể giúp bạn:\n• Tư vấn chế độ ăn uống cá nhân\n• Phân tích dữ liệu dinh dưỡng hôm nay\n• Gợi ý thực đơn và món ăn lành mạnh\n• Giải thích về protein, carbs, fat\n• Hỗ trợ đạt mục tiêu cân nặng\n\nHỏi tôi bất cứ điều gì về dinh dưỡng của bạn!",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];

      emit(AiCoachLoaded(
        userContext: userContext,
        messages: messages,
        conversationHistory: const [],
        recentScans: recentScans,
      ));
    } catch (e) {
      emit(AiCoachError("Lỗi tải dữ liệu AI Coach: $e"));
    }
  }

  Future<void> reloadUserContext() async {
    final currentState = state;
    if (currentState is AiCoachLoaded) {
      try {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final results = await Future.wait([
          repository.getDailyNutritionSummary(today),
          repository.getWeightSummary(),
          repository.getHealthProfile(),
          repository.getHealthConditions(),
          repository.getAllergies(),
          repository.getDailyWaterSummary(today),
          repository.getMealHistory(today),
        ]);

        final nutrition = results[0] as Map<String, dynamic>?;
        final weight = results[1] as Map<String, dynamic>?;
        final profile = results[2] as Map<String, dynamic>?;
        final conditions = results[3] as List<dynamic>? ?? [];
        final allergies = results[4] as List<dynamic>? ?? [];
        final waterSummary = results[5] as Map<String, dynamic>?;
        final mealHistory = results[6] as List<dynamic>?;

        String conditionsStr = conditions.isEmpty
            ? "Không có"
            : conditions.map((c) {
                final name = c['conditionName'] ?? '';
                final notes = c['notes'] ?? '';
                return notes.toString().isNotEmpty ? "$name ($notes)" : name;
              }).join(", ");

        String allergiesStr = allergies.isEmpty
            ? "Không có"
            : allergies.map((a) => a['allergyName'] ?? '').join(", ");

        String mealsListStr = "Chưa có bữa ăn nào được ghi nhận hôm nay.";
        if (mealHistory != null && mealHistory.isNotEmpty) {
          final List<String> mealStrings = [];
          for (var m in mealHistory) {
            final type = m['mealType'] ?? 'Bữa ăn';
            final totalCal = (m['totalCalories'] as num?)?.round() ?? 0;
            final List<dynamic> foodItems = m['items'] ?? [];
            final foodDetails = foodItems.map((f) => "${f['foodName']} (${(f['quantity'] as num).round()}g)").join(", ");
            mealStrings.add("- $type ($totalCal kcal): $foodDetails");
          }
          mealsListStr = mealStrings.join("\n");
        }

        final userContext = {
          'calories': (nutrition?['caloriesConsumed'] as num?)?.round() ?? 0,
          'calorieTarget': (nutrition?['caloriesTarget'] as num?)?.round() ?? 2000,
          'protein': (nutrition?['proteinConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
          'proteinTarget': (nutrition?['proteinTarget'] as num?)?.round() ?? 150,
          'carbs': (nutrition?['carbConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
          'carbTarget': (nutrition?['carbTarget'] as num?)?.round() ?? 250,
          'fat': (nutrition?['fatConsumed'] as num?)?.toStringAsFixed(1) ?? '0',
          'fatTarget': (nutrition?['fatTarget'] as num?)?.round() ?? 70,
          'weight': (weight?['currentWeight'] as num?)?.toString() ?? 'N/A',
          
          'gender': profile?['gender'] ?? 'N/A',
          'dateOfBirth': profile?['dateOfBirth'] ?? 'N/A',
          'age': profile?['dateOfBirth'] != null 
              ? (DateTime.now().year - DateTime.parse(profile!['dateOfBirth']).year).toString()
              : 'N/A',
          'height': profile?['height']?.toString() ?? 'N/A',
          'activityLevel': profile?['activityLevel'] ?? 'N/A',
          'goal': profile?['goal'] ?? 'N/A',
          'targetWeight': profile?['targetWeight']?.toString() ?? 'N/A',
          'bmi': profile?['bmi']?.toStringAsFixed(1) ?? 'N/A',
          'bodyFat': profile?['bodyFat']?.toStringAsFixed(1) ?? 'N/A',
          'conditions': conditionsStr,
          'allergies': allergiesStr,
          'waterConsumed': (waterSummary?['consumedML'] as num?)?.round() ?? 0,
          'waterGoal': (waterSummary?['goalML'] as num?)?.round() ?? 2000,
          'mealsList': mealsListStr,
          'todayDate': today,
        };

        emit(currentState.copyWith(userContext: userContext));
      } catch (_) {}
    }
  }

  Future<void> sendMessage(String text) async {
    final currentState = state;
    if (currentState is AiCoachLoaded && !currentState.isChatLoading) {
      final updatedMessages = List<ChatMessage>.from(currentState.messages);
      final updatedHistory = List<Map<String, dynamic>>.from(currentState.conversationHistory);

      updatedMessages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      updatedHistory.add({"role": "user", "content": text});

      emit(currentState.copyWith(
        messages: updatedMessages,
        conversationHistory: updatedHistory,
        isChatLoading: true,
      ));

      try {
        final reply = await repository.sendAiNutritionMessage(
          userMessage: text,
          conversationHistory: updatedHistory,
          userContext: currentState.userContext,
        );

        final latestState = state;
        if (latestState is AiCoachLoaded) {
          final newMessages = List<ChatMessage>.from(latestState.messages);
          final newHistory = List<Map<String, dynamic>>.from(latestState.conversationHistory);

          if (reply != null) {
            final content = reply['content'] as String? ?? '';
            final reasoning = reply['reasoning_details'] as String?;

            newHistory.add({
              "role": "assistant",
              "content": content,
              if (reasoning != null) "reasoning_details": reasoning,
            });

            newMessages.add(ChatMessage(
              text: content,
              isUser: false,
              timestamp: DateTime.now(),
              reasoning: reasoning,
            ));

            emit(latestState.copyWith(
              messages: newMessages,
              conversationHistory: newHistory,
              isChatLoading: false,
            ));
          } else {
            newMessages.add(ChatMessage(
              text: "Xin lỗi, tôi không thể kết nối được lúc này. Vui lòng thử lại sau.",
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ));
            emit(latestState.copyWith(
              messages: newMessages,
              isChatLoading: false,
            ));
          }
        }
      } catch (e) {
        final latestState = state;
        if (latestState is AiCoachLoaded) {
          final newMessages = List<ChatMessage>.from(latestState.messages);
          newMessages.add(ChatMessage(
            text: "Có lỗi xảy ra: $e",
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
          emit(latestState.copyWith(
            messages: newMessages,
            isChatLoading: false,
          ));
        }
      }
    }
  }

  Future<void> scanFoodImage(String imageBase64, String mimeType, Uint8List imageBytes) async {
    final currentState = state;
    if (currentState is AiCoachLoaded) {
      final updatedMessages = List<ChatMessage>.from(currentState.messages);
      final updatedHistory = List<Map<String, dynamic>>.from(currentState.conversationHistory);

      updatedMessages.add(ChatMessage(
        text: "[Hình ảnh món ăn]",
        isUser: true,
        timestamp: DateTime.now(),
        imageBytes: imageBytes,
      ));

      emit(currentState.copyWith(
        messages: updatedMessages,
        isOperationLoading: true,
      ));

      try {
        final replyStr = await repository.analyzeFoodImage(
          imageBase64: imageBase64,
          mimeType: mimeType,
          userContext: currentState.userContext,
        );

        if (replyStr != null) {
          Map<String, dynamic>? parsedJson;
          try {
            String cleaned = replyStr.trim();
            if (cleaned.startsWith("```")) {
              final lines = cleaned.split("\n");
              if (lines.first.startsWith("```json") || lines.first.startsWith("```")) {
                lines.removeAt(0);
              }
              if (lines.isNotEmpty && lines.last.startsWith("```")) {
                lines.removeLast();
              }
              cleaned = lines.join("\n").trim();
            }
            parsedJson = jsonDecode(cleaned) as Map<String, dynamic>;
          } catch (_) {}

          if (parsedJson != null && parsedJson['success'] == true) {
            final items = parsedJson['items'] as List<dynamic>? ?? [];
            String foodName = "Món ăn";
            if (items.isNotEmpty) {
              foodName = items[0]['name_vi'] ?? items[0]['name'] ?? 'Món ăn';
            }

            // Save recent scan locally
            await saveRecentScan(foodName, parsedJson, imageBase64: imageBase64);

            parsedJson['imageBase64'] = imageBase64;

            final latestState = state;
            if (latestState is AiCoachLoaded) {
              final newMessages = List<ChatMessage>.from(latestState.messages);
              newMessages.add(ChatMessage(
                text: parsedJson['message'] ?? "Đã quét thành công",
                isUser: false,
                timestamp: DateTime.now(),
                foodScanResult: parsedJson,
              ));

              final newHistory = List<Map<String, dynamic>>.from(latestState.conversationHistory);
              newHistory.add({"role": "user", "content": "[User uploaded a food image for analysis]"});
              newHistory.add({"role": "assistant", "content": replyStr});

              emit(latestState.copyWith(
                messages: newMessages,
                conversationHistory: newHistory,
                isOperationLoading: false,
                toastMessage: "SCAN_SUCCESS:${jsonEncode(parsedJson)}",
              ));
            }
          } else {
            final errorMsg = parsedJson?['message'] ?? "Không thể phân tích dữ liệu hình ảnh. Vui lòng thử lại với ảnh rõ nét hơn.";
            final latestState = state;
            if (latestState is AiCoachLoaded) {
              final newMessages = List<ChatMessage>.from(latestState.messages);
              newMessages.add(ChatMessage(
                text: errorMsg,
                isUser: false,
                timestamp: DateTime.now(),
                isError: true,
              ));
              emit(latestState.copyWith(
                messages: newMessages,
                isOperationLoading: false,
                toastMessage: "SCAN_ERROR:$errorMsg",
              ));
            }
          }
        } else {
          const errorMsg = "Có lỗi kết nối khi phân tích ảnh thức ăn.";
          final latestState = state;
          if (latestState is AiCoachLoaded) {
            final newMessages = List<ChatMessage>.from(latestState.messages);
            newMessages.add(ChatMessage(
              text: errorMsg,
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ));
            emit(latestState.copyWith(
              messages: newMessages,
              isOperationLoading: false,
              toastMessage: "SCAN_ERROR:$errorMsg",
            ));
          }
        }
      } catch (e) {
        final errorMsg = "Có lỗi xảy ra: $e";
        final latestState = state;
        if (latestState is AiCoachLoaded) {
          final newMessages = List<ChatMessage>.from(latestState.messages);
          newMessages.add(ChatMessage(
            text: errorMsg,
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
          emit(latestState.copyWith(
            messages: newMessages,
            isOperationLoading: false,
            toastMessage: "SCAN_ERROR:$errorMsg",
          ));
        }
      }
    }
  }

  Future<void> addScannedMeal(Map<String, dynamic> mealData) async {
    final currentState = state;
    if (currentState is AiCoachLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final res = await repository.addMeal(mealData);
        final latestState = state;
        if (latestState is AiCoachLoaded) {
          if (res != null) {
            emit(latestState.copyWith(
              isOperationLoading: false,
              toastMessage: "Ghi nhận bữa ăn thành công!",
            ));
            await reloadUserContext();
            try {
              getIt<DashboardCubit>().loadDashboardData(showLoading: false);
            } catch (_) {}
          } else {
            emit(latestState.copyWith(
              isOperationLoading: false,
              toastMessage: "Không thể thêm bữa ăn. Vui lòng thử lại.",
            ));
          }
        }
      } catch (e) {
        final latestState = state;
        if (latestState is AiCoachLoaded) {
          emit(latestState.copyWith(
            isOperationLoading: false,
            toastMessage: "Lỗi: $e",
          ));
        }
      }
    }
  }

  Future<void> saveRecentScan(String foodName, Map<String, dynamic> fullResult, {String? imageBase64}) async {
    final currentState = state;
    if (currentState is AiCoachLoaded) {
      final nutrition = fullResult['total_nutrition'] ?? {};
      final calories = (nutrition['calories'] as num?)?.toInt() ?? 0;
      final protein = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;
      final carbs = (nutrition['carbs'] as num?)?.toDouble() ?? 0.0;
      final fat = (nutrition['fat'] as num?)?.toDouble() ?? 0.0;

      String imageName = 'fallback';
      final lowerName = foodName.toLowerCase();
      if (lowerName.contains('salmon') || lowerName.contains('cá hồi')) imageName = 'salmon';
      else if (lowerName.contains('salad') || lowerName.contains('bơ') || lowerName.contains('avocado')) imageName = 'salad';
      else if (lowerName.contains('pho') || lowerName.contains('phở') || lowerName.contains('noodle')) imageName = 'pho';
      else if (lowerName.contains('banh mi') || lowerName.contains('bánh mì') || lowerName.contains('sandwich')) imageName = 'banh_mi';
      else if (lowerName.contains('pizza')) imageName = 'pizza';
      else if (lowerName.contains('burger')) imageName = 'burger';
      else if (lowerName.contains('chicken') || lowerName.contains('gà')) imageName = 'chicken';
      else if (lowerName.contains('rice') || lowerName.contains('cơm')) imageName = 'com_tam';
      else if (lowerName.contains('beef') || lowerName.contains('bò') || lowerName.contains('steak')) imageName = 'beef';

      final newScan = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "foodName": foodName,
        "calories": calories,
        "protein": protein,
        "carbs": carbs,
        "fat": fat,
        "time": "Hôm nay, ${DateFormat('h:mm a').format(DateTime.now())}",
        "date": DateTime.now().toIso8601String(),
        "imageName": imageName,
        if (imageBase64 != null) "imageBase64": imageBase64,
        "fullResult": fullResult
      };

      final updatedScans = List<Map<String, dynamic>>.from(currentState.recentScans);
      updatedScans.insert(0, newScan);
      if (updatedScans.length > 10) {
        updatedScans.removeRange(10, updatedScans.length);
      }

      await storage.write(key: 'recent_scans', value: jsonEncode(updatedScans));
      emit(currentState.copyWith(recentScans: updatedScans));
    }
  }
}
