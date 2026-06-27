import '../entities/weight_log.dart';
import '../entities/weight_summary.dart';
import '../entities/weight_progress.dart';

abstract class WeightRepository {
  Future<WeightSummary?> getWeightSummary();
  Future<List<WeightLog>?> getWeightLogs({int page = 1, int pageSize = 10});
  Future<WeightProgress?> getProgressStatistics(String startDate, String endDate);
  Future<WeightLog?> createWeightLog(double weight, double? bodyFat);
  Future<WeightLog?> updateWeightLog(int logId, double weight, double? bodyFat);
  Future<bool> deleteWeightLog(int logId);
  Future<Map<String, dynamic>?> analyzeBodyFatFromMeasurements({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double waist,
    required double neck,
    double? hip,
  });
  Future<List<dynamic>?> getBodyFatHistory();
  Future<bool> deleteBodyFatHistory(int id);
}
