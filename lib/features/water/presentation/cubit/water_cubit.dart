import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../di/dependency_injection.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../domain/repositories/water_repository.dart';
import 'water_state.dart';

class WaterCubit extends Cubit<WaterState> {
  final WaterRepository repository;

  WaterCubit({required this.repository}) : super(WaterInitial());

  /// Load all water data (summary, logs, reminders) for a specific date
  Future<void> loadWaterData(DateTime date, {String? successMessage}) async {
    final bool isRefreshing = state is WaterLoaded;
    final DateTime currentDate = date;
    
    if (!isRefreshing) {
      emit(WaterLoading());
    } else {
      // Keep showing previous data but set operation loading flag
      final currentState = state as WaterLoaded;
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

      // Fetch all three sources of water data concurrently
      final summaryFuture = repository.getDailyWaterSummary(dateStr);
      final logsFuture = repository.getWaterLogHistory(dateStr);
      final remindersFuture = repository.getWaterReminders();

      final results = await Future.wait([summaryFuture, logsFuture, remindersFuture]);

      final summary = results[0] as dynamic;
      final logs = results[1] as List<dynamic>;
      final reminders = results[2] as List<dynamic>;

      emit(WaterLoaded(
        summary: summary,
        logs: List.from(logs),
        reminders: List.from(reminders),
        selectedDate: currentDate,
        toastMessage: successMessage,
        isOperationLoading: false,
      ));
    } catch (e) {
      emit(WaterError("Lỗi tải dữ liệu: $e"));
    }
  }

  /// Add a new water consumption entry
  Future<void> addWater(double amountML) async {
    if (state is! WaterLoaded) return;
    final currentState = state as WaterLoaded;
    
    emit(currentState.copyWith(isOperationLoading: true));
    try {
      final result = await repository.addWaterLog(amountML);
      if (result != null) {
        await loadWaterData(
          currentState.selectedDate,
          successMessage: "Đã ghi nhận +${amountML.round()} ml nước!",
        );
        try {
          getIt<DashboardCubit>().loadDashboardData(showLoading: false);
        } catch (_) {}
      } else {
        emit(currentState.copyWith(
          isOperationLoading: false,
          toastMessage: "Lỗi: Không thể ghi nhận lượng nước",
        ));
      }
    } catch (e) {
      emit(WaterError("Không thể thêm lượng nước: $e"));
    }
  }

  /// Delete a water log entry
  Future<void> deleteWaterLog(int logId) async {
    if (state is! WaterLoaded) return;
    final currentState = state as WaterLoaded;
    
    emit(currentState.copyWith(isOperationLoading: true));
    try {
      final success = await repository.deleteWaterLog(logId);
      if (success) {
        await loadWaterData(
          currentState.selectedDate,
          successMessage: "Đã xóa nhật ký uống nước thành công",
        );
        try {
          getIt<DashboardCubit>().loadDashboardData(showLoading: false);
        } catch (_) {}
      } else {
        emit(currentState.copyWith(
          isOperationLoading: false,
          toastMessage: "Lỗi: Không thể xóa nhật ký",
        ));
      }
    } catch (e) {
      emit(WaterError("Không thể xóa nhật ký: $e"));
    }
  }

  /// Update daily water consumption goal
  Future<void> updateGoal(double targetML) async {
    if (state is! WaterLoaded) return;
    final currentState = state as WaterLoaded;
    
    emit(currentState.copyWith(isOperationLoading: true));
    try {
      final summary = await repository.updateWaterGoal(targetML);
      if (summary != null) {
        await loadWaterData(
          currentState.selectedDate,
          successMessage: "Đã cập nhật mục tiêu thành công!",
        );
        try {
          getIt<DashboardCubit>().loadDashboardData(showLoading: false);
        } catch (_) {}
      } else {
        emit(currentState.copyWith(
          isOperationLoading: false,
          toastMessage: "Lỗi: Không thể cập nhật mục tiêu",
        ));
      }
    } catch (e) {
      emit(WaterError("Không thể cập nhật mục tiêu: $e"));
    }
  }

  /// Add a water reminder alarm
  Future<void> addReminder(String timeStr) async {
    if (state is! WaterLoaded) return;
    final currentState = state as WaterLoaded;
    
    emit(currentState.copyWith(isOperationLoading: true));
    try {
      final reminder = await repository.createWaterReminder(timeStr);
      if (reminder != null) {
        await loadWaterData(
          currentState.selectedDate,
          successMessage: "Đã thêm nhắc nhở uống nước!",
        );
      } else {
        emit(currentState.copyWith(
          isOperationLoading: false,
          toastMessage: "Lỗi: Không thể thêm nhắc nhở",
        ));
      }
    } catch (e) {
      emit(WaterError("Không thể thêm nhắc nhở: $e"));
    }
  }

  /// Delete a water reminder alarm
  Future<void> deleteReminder(int reminderId) async {
    if (state is! WaterLoaded) return;
    final currentState = state as WaterLoaded;
    
    emit(currentState.copyWith(isOperationLoading: true));
    try {
      final success = await repository.deleteWaterReminder(reminderId);
      if (success) {
        await loadWaterData(
          currentState.selectedDate,
          successMessage: "Đã xóa nhắc nhở thành công",
        );
      } else {
        emit(currentState.copyWith(
          isOperationLoading: false,
          toastMessage: "Lỗi: Không thể xóa nhắc nhở",
        ));
      }
    } catch (e) {
      emit(WaterError("Không thể xóa nhắc nhở: $e"));
    }
  }

  /// Toggle reminder enabled state locally
  Future<void> toggleReminder(int reminderId, bool isEnabled) async {
    if (state is! WaterLoaded) return;
    final currentState = state as WaterLoaded;
    
    // Update locally in repository
    await repository.saveReminderEnabledState(reminderId, isEnabled);
    
    // Quick local state update to keep UI highly responsive
    final updatedReminders = currentState.reminders.map((reminder) {
      if (reminder.reminderId == reminderId) {
        return reminder.copyWith(isEnabled: isEnabled);
      }
      return reminder;
    }).toList();

    emit(currentState.copyWith(reminders: updatedReminders));
    
    // Background refresh to sync completely
    await loadWaterData(currentState.selectedDate);
  }

  /// Shift the selected date (e.g. going to yesterday or tomorrow)
  void changeSelectedDate(DateTime date) {
    loadWaterData(date);
  }
}
