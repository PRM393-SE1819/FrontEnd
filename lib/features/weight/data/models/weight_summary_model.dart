import '../../domain/entities/weight_summary.dart';

class WeightSummaryModel extends WeightSummary {
  const WeightSummaryModel({
    super.currentWeight,
    super.targetWeight,
    super.currentBodyFat,
  });

  factory WeightSummaryModel.fromJson(Map<String, dynamic> json) {
    return WeightSummaryModel(
      currentWeight: json['currentWeight'] != null ? (json['currentWeight'] as num).toDouble() : null,
      targetWeight: json['targetWeight'] != null ? (json['targetWeight'] as num).toDouble() : null,
      currentBodyFat: json['currentBodyFat'] != null ? (json['currentBodyFat'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'currentBodyFat': currentBodyFat,
    };
  }
}
