import '../../domain/entities/water_log.dart';

class WaterLogModel extends WaterLog {
  const WaterLogModel({
    required super.waterLogId,
    required super.amountML,
    required super.loggedAt,
  });

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    return WaterLogModel(
      waterLogId: json['waterLogId'] as int,
      amountML: (json['amountML'] as num).toDouble(),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'waterLogId': waterLogId,
      'amountML': amountML,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }
}
