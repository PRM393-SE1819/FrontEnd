import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../di/dependency_injection.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
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
          try {
            getIt<DashboardCubit>().loadDashboardData(showLoading: false);
          } catch (_) {}
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
          try {
            getIt<DashboardCubit>().loadDashboardData(showLoading: false);
          } catch (_) {}
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
          try {
            getIt<DashboardCubit>().loadDashboardData(showLoading: false);
          } catch (_) {}
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
    try {
      double bodyFatPercent = 0.0;
      bool isMale = gender.toLowerCase() == 'male';

      if (isMale) {
        if (waist <= neck) return null;
        double logWaistNeck = math.log(waist - neck) / math.ln10;
        double logHeight = math.log(height) / math.ln10;
        double density = 1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight;
        bodyFatPercent = (495 / density) - 450;
      } else {
        double actualHip = hip ?? 90.0;
        if ((waist + actualHip) <= neck) return null;
        double logWaistHipNeck = math.log(waist + actualHip - neck) / math.ln10;
        double logHeight = math.log(height) / math.ln10;
        double density = 1.29579 - 0.35004 * logWaistHipNeck + 0.22100 * logHeight;
        bodyFatPercent = (495 / density) - 450;
      }

      if (bodyFatPercent.isNaN || bodyFatPercent.isInfinite || bodyFatPercent < 0) {
        bodyFatPercent = 0.0;
      } else if (bodyFatPercent > 60.0) {
        bodyFatPercent = 60.0;
      }

      String category = '';
      String healthAssessment = '';
      String recommendation = '';

      if (isMale) {
        if (bodyFatPercent < 2) {
          category = 'Under Essential Fat';
          healthAssessment = 'Cảnh báo: Tỷ lệ mỡ quá thấp, dưới mức tối thiểu cần thiết cho sức khỏe sinh lý.';
          recommendation = 'Nên tăng cường dinh dưỡng, bổ sung chất béo lành mạnh và tham khảo ý kiến chuyên gia y tế.';
        } else if (bodyFatPercent <= 5.9) {
          category = 'Essential Fat';
          healthAssessment = 'Lượng mỡ tối thiểu để duy trì các chức năng sinh lý cơ bản của cơ thể.';
          recommendation = 'Cẩn thận không để tỷ lệ mỡ giảm thêm vì có thể gây ảnh hưởng xấu tới hệ miễn dịch và nội tiết.';
        } else if (bodyFatPercent <= 13.9) {
          category = 'Athletes';
          healthAssessment = 'Tỷ lệ mỡ rất thấp, tương đương với mức độ của vận động viên chuyên nghiệp.';
          recommendation = 'Đảm bảo nạp đủ năng lượng và chất béo lành mạnh để tránh suy nhược và giữ phong độ thi đấu.';
        } else if (bodyFatPercent <= 17.9) {
          category = 'Fitness';
          healthAssessment = 'Tỷ lệ mỡ lý tưởng, cơ thể săn chắc, cân đối và khỏe mạnh.';
          recommendation = 'Tiếp tục duy trì chế độ dinh dưỡng giàu protein và tập luyện kháng lực để giữ khối lượng cơ.';
        } else if (bodyFatPercent <= 24.9) {
          category = 'Average';
          healthAssessment = 'Tỷ lệ mỡ ở mức trung bình, bình thường đối với sức khỏe chung.';
          recommendation = 'Duy trì chế độ ăn cân bằng và tập luyện thể thao để duy trì vóc dáng và sức khỏe ổn định.';
        } else {
          category = 'Obese';
          healthAssessment = 'Tỷ lệ mỡ cơ thể cao, có nguy cơ ảnh hưởng xấu đến sức khỏe tim mạch và chuyển hóa.';
          recommendation = 'Nên tập trung giảm mỡ thông qua thâm hụt calo lành mạnh, tăng cường vận động cơ bắp và cardio đều đặn.';
        }
      } else {
        if (bodyFatPercent < 10) {
          category = 'Under Essential Fat';
          healthAssessment = 'Cảnh báo: Tỷ lệ mỡ quá thấp, dưới mức tối thiểu cần thiết cho sức khỏe sinh lý.';
          recommendation = 'Nên tăng cường dinh dưỡng, bổ sung chất béo lành mạnh và tham khảo ý kiến chuyên gia y tế.';
        } else if (bodyFatPercent <= 13.9) {
          category = 'Essential Fat';
          healthAssessment = 'Lượng mỡ tối thiểu để duy trì các chức năng sinh lý cơ bản của cơ thể.';
          recommendation = 'Cẩn thận không để tỷ lệ mỡ giảm thêm vì có thể gây ảnh hưởng xấu tới hệ miễn dịch và nội tiết.';
        } else if (bodyFatPercent <= 20.9) {
          category = 'Athletes';
          healthAssessment = 'Tỷ lệ mỡ rất thấp, tương đương với mức độ của vận động viên chuyên nghiệp.';
          recommendation = 'Đảm bảo nạp đủ năng lượng và chất béo lành mạnh để tránh suy nhược và giữ phong độ thi đấu.';
        } else if (bodyFatPercent <= 24.9) {
          category = 'Fitness';
          healthAssessment = 'Tỷ lệ mỡ lý tưởng, cơ thể săn chắc, cân đối và khỏe mạnh.';
          recommendation = 'Tiếp tục duy trì chế độ dinh dưỡng giàu protein và tập luyện kháng lực để giữ khối lượng cơ.';
        } else if (bodyFatPercent <= 31.9) {
          category = 'Average';
          healthAssessment = 'Tỷ lệ mỡ ở mức trung bình, bình thường đối với sức khỏe chung.';
          recommendation = 'Duy trì chế độ ăn cân bằng và tập luyện thể thao để duy trì vóc dáng và sức khỏe ổn định.';
        } else {
          category = 'Obese';
          healthAssessment = 'Tỷ lệ mỡ cơ thể cao, có nguy cơ ảnh hưởng xấu đến sức khỏe tim mạch và chuyển hóa.';
          recommendation = 'Nên tập trung giảm mỡ thông qua thâm hụt calo lành mạnh, tăng cường vận động cơ bắp và cardio đều đặn.';
        }
      }

      double targetBf = isMale ? 15.0 : 22.0;
      double leanBodyMass = weight * (1.0 - (bodyFatPercent / 100.0));
      double targetWeight = leanBodyMass / (1.0 - (targetBf / 100.0));

      return {
        "estimatedBodyFat": bodyFatPercent,
        "category": category,
        "healthAssessment": healthAssessment,
        "recommendation": recommendation,
        "targetWeight": targetWeight,
      };
    } catch (_) {
      return null;
    }
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
