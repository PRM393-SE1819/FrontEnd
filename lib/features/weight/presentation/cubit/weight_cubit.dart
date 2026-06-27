import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/weight_repository.dart';
import 'weight_state.dart';

class WeightCubit extends Cubit<WeightState> {
  final WeightRepository repository;

  WeightCubit({required this.repository}) : super(WeightInitial());

  Future<void> loadWeightData() async {
    emit(WeightLoading());
    try {
      final summary = await repository.getWeightSummary();
      final logs = await repository.getWeightLogs(page: 1, pageSize: 20) ?? [];
      
      final endStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final startStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
      final progress = await repository.getProgressStatistics(startStr, endStr);
      
      final bodyFatHistory = await repository.getBodyFatHistory() ?? [];

      emit(WeightLoaded(
        summary: summary,
        logs: logs,
        progress: progress,
        bodyFatHistory: bodyFatHistory,
      ));
    } catch (e) {
      emit(WeightError("Không thể tải thông tin cân nặng: $e"));
    }
  }

  Future<void> addWeightLog(double weight, double? bodyFat) async {
    final currentState = state;
    if (currentState is WeightLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final result = await repository.createWeightLog(weight, bodyFat);
        if (result != null) {
          // Reload all data
          final summary = await repository.getWeightSummary();
          final logs = await repository.getWeightLogs(page: 1, pageSize: 20) ?? [];
          final endStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final startStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
          final progress = await repository.getProgressStatistics(startStr, endStr);
          final bodyFatHistory = await repository.getBodyFatHistory() ?? [];

          emit(WeightLoaded(
            summary: summary,
            logs: logs,
            progress: progress,
            bodyFatHistory: bodyFatHistory,
            toastMessage: "Đã ghi nhận cân nặng thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Ghi nhận cân nặng thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> updateWeightLog(int logId, double weight, double? bodyFat) async {
    final currentState = state;
    if (currentState is WeightLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final result = await repository.updateWeightLog(logId, weight, bodyFat);
        if (result != null) {
          final summary = await repository.getWeightSummary();
          final logs = await repository.getWeightLogs(page: 1, pageSize: 20) ?? [];
          final endStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final startStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
          final progress = await repository.getProgressStatistics(startStr, endStr);
          final bodyFatHistory = await repository.getBodyFatHistory() ?? [];

          emit(WeightLoaded(
            summary: summary,
            logs: logs,
            progress: progress,
            bodyFatHistory: bodyFatHistory,
            toastMessage: "Đã cập nhật thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Cập nhật thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> deleteWeightLog(int logId) async {
    final currentState = state;
    if (currentState is WeightLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.deleteWeightLog(logId);
        if (success) {
          final summary = await repository.getWeightSummary();
          final logs = await repository.getWeightLogs(page: 1, pageSize: 20) ?? [];
          final endStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final startStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
          final progress = await repository.getProgressStatistics(startStr, endStr);
          final bodyFatHistory = await repository.getBodyFatHistory() ?? [];

          emit(WeightLoaded(
            summary: summary,
            logs: logs,
            progress: progress,
            bodyFatHistory: bodyFatHistory,
            toastMessage: "Đã xóa cân nặng thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Xóa thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<Map<String, dynamic>?> calculateBodyFat({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double waist,
    required double neck,
    double? hip,
  }) async {
    final currentState = state;
    if (currentState is WeightLoaded) {
      try {
        final result = await repository.analyzeBodyFatFromMeasurements(
          gender: gender,
          age: age,
          height: height,
          weight: weight,
          waist: waist,
          neck: neck,
          hip: hip,
        );
        return result;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteBodyFatRecord(int id) async {
    final currentState = state;
    if (currentState is WeightLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.deleteBodyFatHistory(id);
        if (success) {
          final summary = await repository.getWeightSummary();
          final logs = await repository.getWeightLogs(page: 1, pageSize: 20) ?? [];
          final endStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final startStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
          final progress = await repository.getProgressStatistics(startStr, endStr);
          final bodyFatHistory = await repository.getBodyFatHistory() ?? [];

          emit(WeightLoaded(
            summary: summary,
            logs: logs,
            progress: progress,
            bodyFatHistory: bodyFatHistory,
            toastMessage: "Đã xóa phân tích mỡ cơ thể thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Xóa thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }
}
