import '../../domain/entities/weight_log.dart';
import '../../domain/entities/weight_summary.dart';
import '../../domain/entities/weight_progress.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/weight_remote_datasource.dart';

class WeightRepositoryImpl implements WeightRepository {
  final WeightRemoteDataSource remoteDataSource;

  const WeightRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WeightSummary?> getWeightSummary() async {
    try {
      return await remoteDataSource.getWeightSummary();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WeightLog>?> getWeightLogs({int page = 1, int pageSize = 10}) async {
    try {
      return await remoteDataSource.getWeightLogs(page: page, pageSize: pageSize);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WeightProgress?> getProgressStatistics(String startDate, String endDate) async {
    try {
      return await remoteDataSource.getProgressStatistics(startDate, endDate);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WeightLog?> createWeightLog(double weight, double? bodyFat) async {
    try {
      return await remoteDataSource.createWeightLog(weight, bodyFat);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WeightLog?> updateWeightLog(int logId, double weight, double? bodyFat) async {
    try {
      return await remoteDataSource.updateWeightLog(logId, weight, bodyFat);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> deleteWeightLog(int logId) async {
    try {
      return await remoteDataSource.deleteWeightLog(logId);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> analyzeBodyFatFromMeasurements({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double waist,
    required double neck,
    double? hip,
  }) async {
    try {
      return await remoteDataSource.analyzeBodyFatFromMeasurements(
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        waist: waist,
        neck: neck,
        hip: hip,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<dynamic>?> getBodyFatHistory() async {
    try {
      return await remoteDataSource.getBodyFatHistory();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> deleteBodyFatHistory(int id) async {
    try {
      return await remoteDataSource.deleteBodyFatHistory(id);
    } catch (_) {
      return false;
    }
  }
}
