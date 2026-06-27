import 'weight_log.dart';

class WeightProgress {
  final double? startWeight;
  final double? currentWeight;
  final double? weightChanged;
  final double? startBodyFat;
  final double? currentBodyFat;
  final double? bodyFatChanged;
  final List<WeightLog> history;

  const WeightProgress({
    this.startWeight,
    this.currentWeight,
    this.weightChanged,
    this.startBodyFat,
    this.currentBodyFat,
    this.bodyFatChanged,
    required this.history,
  });
}
