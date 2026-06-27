class HealthCondition {
  final int healthConditionId;
  final String conditionName;
  final String? notes;

  const HealthCondition({
    required this.healthConditionId,
    required this.conditionName,
    this.notes,
  });
}
