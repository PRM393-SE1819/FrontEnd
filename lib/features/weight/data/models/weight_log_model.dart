import '../../domain/entities/weight_log.dart';

class WeightLogModel extends WeightLog {
  const WeightLogModel({
    required super.weightLogId,
    required super.weight,
    super.bodyFat,
    required super.loggedAt,
  });

  factory WeightLogModel.fromJson(Map<String, dynamic> json) {
    return WeightLogModel(
      weightLogId: json['weightLogId'] ?? json['id'] ?? 0,
      weight: (json['weight'] as num).toDouble(),
      bodyFat: json['bodyFat'] != null ? (json['bodyFat'] as num).toDouble() : null,
      loggedAt: DateTime.parse(json['loggedAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightLogId': weightLogId,
      'weight': weight,
      'bodyFat': bodyFat,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }
}
