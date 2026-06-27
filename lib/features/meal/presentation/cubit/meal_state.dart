import 'package:equatable/equatable.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/daily_calories_summary.dart';

abstract class MealState extends Equatable {
  const MealState();

  @override
  List<Object?> get props => [];
}

class MealInitial extends MealState {}

class MealLoading extends MealState {}

class MealLoaded extends MealState {
  final DailyCaloriesSummary summary;
  final List<Meal> meals;
  final DateTime selectedDate;
  final bool isOperationLoading;
  final String? toastMessage;

  const MealLoaded({
    required this.summary,
    required this.meals,
    required this.selectedDate,
    this.isOperationLoading = false,
    this.toastMessage,
  });

  MealLoaded copyWith({
    DailyCaloriesSummary? summary,
    List<Meal>? meals,
    DateTime? selectedDate,
    bool? isOperationLoading,
    String? toastMessage,
  }) {
    return MealLoaded(
      summary: summary ?? this.summary,
      meals: meals ?? this.meals,
      selectedDate: selectedDate ?? this.selectedDate,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      toastMessage: toastMessage,
    );
  }

  @override
  List<Object?> get props => [summary, meals, selectedDate, isOperationLoading, toastMessage];
}

class MealError extends MealState {
  final String message;

  const MealError(this.message);

  @override
  List<Object?> get props => [message];
}
