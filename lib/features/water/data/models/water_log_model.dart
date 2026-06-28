import '../../domain/entities/water_log.dart';

class WaterLogModel extends WaterLog {
  const WaterLogModel({
    required super.waterLogId,
    required super.amountML,
    required super.loggedAt,
  });

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    var loggedAtStr = json['loggedAt'] as String;
    // Only append 'Z' if the string has no timezone info.
    // We check for '-' AFTER the 'T' (time portion) to detect negative offsets
    // like "2026-06-28T10:00:00-05:00". The '-' in the date portion "2026-06-28"
    // must NOT be mistaken as a timezone indicator.
    final tIndex = loggedAtStr.indexOf('T');
    final hasTimezoneOffset = loggedAtStr.endsWith('Z') ||
        loggedAtStr.contains('+') ||
        (tIndex != -1 && loggedAtStr.contains('-', tIndex + 1));
    if (!hasTimezoneOffset) {
      loggedAtStr = '${loggedAtStr}Z';
    }
    return WaterLogModel(
      waterLogId: json['waterLogId'] as int,
      amountML: (json['amountML'] as num).toDouble(),
      loggedAt: DateTime.parse(loggedAtStr).toLocal(),
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
