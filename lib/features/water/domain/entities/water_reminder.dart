import 'package:equatable/equatable.dart';

class WaterReminder extends Equatable {
  final int reminderId;
  final String reminderTime;
  final bool isEnabled;

  const WaterReminder({
    required this.reminderId,
    required this.reminderTime,
    required this.isEnabled,
  });

  @override
  List<Object?> get props => [reminderId, reminderTime, isEnabled];

  WaterReminder copyWith({
    int? reminderId,
    String? reminderTime,
    bool? isEnabled,
  }) {
    return WaterReminder(
      reminderId: reminderId ?? this.reminderId,
      reminderTime: reminderTime ?? this.reminderTime,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
