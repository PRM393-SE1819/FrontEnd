class WeightLog {
  final int weightLogId;
  final double weight;
  final double? bodyFat;
  final DateTime loggedAt;

  const WeightLog({
    required this.weightLogId,
    required this.weight,
    this.bodyFat,
    required this.loggedAt,
  });
}
