import 'package:equatable/equatable.dart';
import '../../domain/entities/water_log.dart';
import '../../domain/entities/water_reminder.dart';
import '../../domain/entities/water_summary.dart';

abstract class WaterState extends Equatable {
  const WaterState();

  @override
  List<Object?> get props => [];
}

class WaterInitial extends WaterState {}

class WaterLoading extends WaterState {}

class WaterLoaded extends WaterState {
  final WaterSummary summary;
  final List<WaterLog> logs;
  final List<WaterReminder> reminders;
  final DateTime selectedDate;
  final String? toastMessage; // Optional toast/snackbar notification message
  final bool isOperationLoading; // True if an async operation (like adding/deleting) is in progress

  const WaterLoaded({
    required this.summary,
    required this.logs,
    required this.reminders,
    required this.selectedDate,
    this.toastMessage,
    this.isOperationLoading = false,
  });

  WaterLoaded copyWith({
    WaterSummary? summary,
    List<WaterLog>? logs,
    List<WaterReminder>? reminders,
    DateTime? selectedDate,
    String? toastMessage,
    bool? isOperationLoading,
  }) {
    return WaterLoaded(
      summary: summary ?? this.summary,
      logs: logs ?? this.logs,
      reminders: reminders ?? this.reminders,
      selectedDate: selectedDate ?? this.selectedDate,
      toastMessage: toastMessage,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
    );
  }

  @override
  List<Object?> get props => [summary, logs, reminders, selectedDate, toastMessage, isOperationLoading];
}

class WaterError extends WaterState {
  final String message;

  const WaterError(this.message);

  @override
  List<Object?> get props => [message];
}
