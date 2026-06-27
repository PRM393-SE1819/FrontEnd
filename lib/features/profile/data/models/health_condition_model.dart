import '../../domain/entities/health_condition.dart';

class HealthConditionModel extends HealthCondition {
  const HealthConditionModel({
    required super.healthConditionId,
    required super.conditionName,
    super.notes,
  });

  factory HealthConditionModel.fromJson(Map<String, dynamic> json) {
    return HealthConditionModel(
      healthConditionId: json['healthConditionId'] ?? json['id'] ?? 0,
      conditionName: json['conditionName'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'healthConditionId': healthConditionId,
      'conditionName': conditionName,
      'notes': notes,
    };
  }
}
