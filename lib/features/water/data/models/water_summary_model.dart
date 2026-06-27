import '../../domain/entities/water_summary.dart';

class WaterSummaryModel extends WaterSummary {
  const WaterSummaryModel({
    required super.consumedML,
    required super.goalML,
  });

  factory WaterSummaryModel.fromJson(Map<String, dynamic> json) {
    return WaterSummaryModel(
      consumedML: (json['consumedML'] as num?)?.toDouble() ?? 0.0,
      goalML: (json['goalML'] as num?)?.toDouble() ?? 2000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consumedML': consumedML,
      'goalML': goalML,
    };
  }
}
