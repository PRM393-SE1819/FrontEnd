import 'package:equatable/equatable.dart';

class WaterLog extends Equatable {
  final int waterLogId;
  final double amountML;
  final DateTime loggedAt;

  const WaterLog({
    required this.waterLogId,
    required this.amountML,
    required this.loggedAt,
  });

  @override
  List<Object?> get props => [waterLogId, amountML, loggedAt];
}
