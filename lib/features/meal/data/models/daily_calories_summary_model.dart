import '../../domain/entities/daily_calories_summary.dart';

class DailyCaloriesSummaryModel extends DailyCaloriesSummary {
  const DailyCaloriesSummaryModel({
    required super.caloriesConsumed,
    required super.caloriesTarget,
    required super.protein,
    required super.carbs,
    required super.fat,
    required super.remainingCalories,
  });

  factory DailyCaloriesSummaryModel.fromJson(Map<String, dynamic> json) {
    return DailyCaloriesSummaryModel(
      caloriesConsumed: (json['caloriesConsumed'] as num?)?.toDouble() ?? 0.0,
      caloriesTarget: (json['caloriesTarget'] as num?)?.toDouble() ?? 2000.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      remainingCalories: (json['remainingCalories'] as num?)?.toDouble() ?? 2000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caloriesConsumed': caloriesConsumed,
      'caloriesTarget': caloriesTarget,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'remainingCalories': remainingCalories,
    };
  }
}
