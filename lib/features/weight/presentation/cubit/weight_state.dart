import 'package:equatable/equatable.dart';
import '../../domain/entities/weight_log.dart';
import '../../domain/entities/weight_summary.dart';
import '../../domain/entities/weight_progress.dart';

abstract class WeightState extends Equatable {
  const WeightState();

  @override
  List<Object?> get props => [];
}

class WeightInitial extends WeightState {}

class WeightLoading extends WeightState {}

class WeightLoaded extends WeightState {
  final WeightSummary? summary;
  final List<WeightLog> logs;
  final WeightProgress? progress;
  final List<dynamic> bodyFatHistory;
  final bool isOperationLoading;
  final String? toastMessage;

  const WeightLoaded({
    this.summary,
    required this.logs,
    this.progress,
    required this.bodyFatHistory,
    this.isOperationLoading = false,
    this.toastMessage,
  });

  WeightLoaded copyWith({
    WeightSummary? summary,
    List<WeightLog>? logs,
    WeightProgress? progress,
    List<dynamic>? bodyFatHistory,
    bool? isOperationLoading,
    String? toastMessage,
  }) {
    return WeightLoaded(
      summary: summary ?? this.summary,
      logs: logs ?? this.logs,
      progress: progress ?? this.progress,
      bodyFatHistory: bodyFatHistory ?? this.bodyFatHistory,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      toastMessage: toastMessage,
    );
  }

  @override
  List<Object?> get props => [summary, logs, progress, bodyFatHistory, isOperationLoading, toastMessage];
}

class WeightError extends WeightState {
  final String message;

  const WeightError(this.message);

  @override
  List<Object?> get props => [message];
}
