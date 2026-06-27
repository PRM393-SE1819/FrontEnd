import 'package:equatable/equatable.dart';

class WaterSummary extends Equatable {
  final double consumedML;
  final double goalML;

  const WaterSummary({
    required this.consumedML,
    required this.goalML,
  });

  @override
  List<Object?> get props => [consumedML, goalML];
}
