import '../../domain/entities/water_reminder.dart';

class WaterReminderModel extends WaterReminder {
  const WaterReminderModel({
    required super.reminderId,
    required super.reminderTime,
    required super.isEnabled,
  });

  factory WaterReminderModel.fromJson(Map<String, dynamic> json, {bool isEnabled = true}) {
    return WaterReminderModel(
      reminderId: json['reminderId'] as int,
      reminderTime: json['reminderTime'] as String,
      isEnabled: isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'reminderTime': reminderTime,
      'isEnabled': isEnabled,
    };
  }
}
