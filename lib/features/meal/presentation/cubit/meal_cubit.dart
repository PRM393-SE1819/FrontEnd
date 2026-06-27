import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/entities/daily_calories_summary.dart';
import '../../domain/entities/food.dart';
import 'meal_state.dart';

class MealCubit extends Cubit<MealState> {
  final MealRepository repository;

  MealCubit({required this.repository}) : super(MealInitial());

  Future<void> loadMealLogs(DateTime date) async {
    emit(MealLoading());
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final summary = await repository.getDailyCaloriesSummary(dateStr) ?? const DailyCaloriesSummary(
        caloriesConsumed: 0.0,
        caloriesTarget: 2000.0,
        protein: 0.0,
        carbs: 0.0,
        fat: 0.0,
        remainingCalories: 2000.0,
      );
      final meals = await repository.getMealHistory(date: dateStr) ?? [];

      emit(MealLoaded(
        summary: summary,
        meals: meals,
        selectedDate: date,
      ));
    } catch (e) {
      emit(MealError("Không thể tải thông tin bữa ăn: $e"));
    }
  }

  Future<void> changeDate(int days) async {
    final currentState = state;
    if (currentState is MealLoaded) {
      final newDate = currentState.selectedDate.add(Duration(days: days));
      await loadMealLogs(newDate);
    }
  }

  Future<void> selectDate(DateTime picked) async {
    await loadMealLogs(picked);
  }

  Future<void> addMeal(Map<String, dynamic> mealData) async {
    final currentState = state;
    if (currentState is MealLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final result = await repository.addMeal(mealData);
        if (result != null) {
          final dateStr = DateFormat('yyyy-MM-dd').format(currentState.selectedDate);
          final summary = await repository.getDailyCaloriesSummary(dateStr) ?? currentState.summary;
          final meals = await repository.getMealHistory(date: dateStr) ?? [];

          emit(MealLoaded(
            summary: summary,
            meals: meals,
            selectedDate: currentState.selectedDate,
            toastMessage: "Đã thêm bữa ăn thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Thêm bữa ăn thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> updateMeal(int mealId, Map<String, dynamic> mealData) async {
    final currentState = state;
    if (currentState is MealLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final result = await repository.updateMeal(mealId, mealData);
        if (result != null) {
          final dateStr = DateFormat('yyyy-MM-dd').format(currentState.selectedDate);
          final summary = await repository.getDailyCaloriesSummary(dateStr) ?? currentState.summary;
          final meals = await repository.getMealHistory(date: dateStr) ?? [];

          emit(MealLoaded(
            summary: summary,
            meals: meals,
            selectedDate: currentState.selectedDate,
            toastMessage: "Đã cập nhật bữa ăn thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Cập nhật thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> deleteMeal(int mealId) async {
    final currentState = state;
    if (currentState is MealLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.deleteMeal(mealId);
        if (success) {
          final dateStr = DateFormat('yyyy-MM-dd').format(currentState.selectedDate);
          final summary = await repository.getDailyCaloriesSummary(dateStr) ?? currentState.summary;
          final meals = await repository.getMealHistory(date: dateStr) ?? [];

          emit(MealLoaded(
            summary: summary,
            meals: meals,
            selectedDate: currentState.selectedDate,
            toastMessage: "Đã xóa bữa ăn thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Xóa thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<List<Food>> searchFoods(String query) async {
    try {
      return await repository.searchFoods(query) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Food>> getFavoriteFoods() async {
    try {
      return await repository.getFavoriteFoods() ?? [];
    } catch (_) {
      return [];
    }
  }
}
