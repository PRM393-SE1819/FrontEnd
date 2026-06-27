import '../../domain/entities/weight_progress.dart';
import 'weight_log_model.dart';

class WeightProgressModel extends WeightProgress {
  const WeightProgressModel({
    super.startWeight,
    super.currentWeight,
    super.weightChanged,
    super.startBodyFat,
    super.currentBodyFat,
    super.bodyFatChanged,
    required super.history,
  });

  factory WeightProgressModel.fromJson(Map<String, dynamic> json) {
    final list = json['history'] as List? ?? [];
    final parsedHistory = list.map((e) => WeightLogModel.fromJson(Map<String, dynamic>.from(e))).toList();

    return WeightProgressModel(
      startWeight: json['startWeight'] != null ? (json['startWeight'] as num).toDouble() : null,
      currentWeight: json['currentWeight'] != null ? (json['currentWeight'] as num).toDouble() : null,
      weightChanged: json['weightChanged'] != null ? (json['weightChanged'] as num).toDouble() : null,
      startBodyFat: json['startBodyFat'] != null ? (json['startBodyFat'] as num).toDouble() : null,
      currentBodyFat: json['currentBodyFat'] != null ? (json['currentBodyFat'] as num).toDouble() : null,
      bodyFatChanged: json['bodyFatChanged'] != null ? (json['bodyFatChanged'] as num).toDouble() : null,
      history: parsedHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startWeight': startWeight,
      'currentWeight': currentWeight,
      'weightChanged': weightChanged,
      'startBodyFat': startBodyFat,
      'currentBodyFat': currentBodyFat,
      'bodyFatChanged': bodyFatChanged,
      'history': history.map((e) => (e as WeightLogModel).toJson()).toList(),
    };
  }
}
