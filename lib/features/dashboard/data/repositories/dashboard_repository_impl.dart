import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../../../water/domain/repositories/water_repository.dart';
import '../../../../di/dependency_injection.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  const DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardSummary?> getDashboardSummary(String dateStr) async {
    try {
      final futures = await Future.wait([
        remoteDataSource.getDailyNutritionSummary(dateStr),
        remoteDataSource.getDailyWaterSummary(dateStr),
        remoteDataSource.getWeightSummary(),
      ]);

      final nutritionSummary = futures[0];
      final weightSummary = futures[2];

      double caloriesConsumed = 0.0;
      double caloriesTarget = 2000.0;
      double proteinConsumed = 0.0;
      double proteinTarget = 150.0;
      double carbConsumed = 0.0;
      double carbTarget = 250.0;
      double fatConsumed = 0.0;
      double fatTarget = 70.0;

      if (nutritionSummary != null) {
        caloriesConsumed = (nutritionSummary['caloriesConsumed'] as num?)?.toDouble() ?? 0.0;
        caloriesTarget = (nutritionSummary['caloriesTarget'] as num?)?.toDouble() ?? 2000.0;
        proteinConsumed = (nutritionSummary['proteinConsumed'] as num?)?.toDouble() ?? 0.0;
        proteinTarget = (nutritionSummary['proteinTarget'] as num?)?.toDouble() ?? 150.0;
        carbConsumed = (nutritionSummary['carbConsumed'] as num?)?.toDouble() ?? 0.0;
        carbTarget = (nutritionSummary['carbTarget'] as num?)?.toDouble() ?? 250.0;
        fatConsumed = (nutritionSummary['fatConsumed'] as num?)?.toDouble() ?? 0.0;
        fatTarget = (nutritionSummary['fatTarget'] as num?)?.toDouble() ?? 70.0;
      }

      double waterConsumed = 0.0;
      double waterGoal = 2000.0;
      try {
        final waterSummary = await getIt<WaterRepository>().getDailyWaterSummary(dateStr);
        waterConsumed = waterSummary.consumedML;
        waterGoal = waterSummary.goalML;
      } catch (_) {
        final fallbackSummary = futures[1];
        if (fallbackSummary != null) {
          waterConsumed = (fallbackSummary['consumedML'] as num?)?.toDouble() ?? 0.0;
          waterGoal = (fallbackSummary['goalML'] as num?)?.toDouble() ?? 2000.0;
        }
      }

      double currentWeight = 0.0;
      double targetWeight = 0.0;
      if (weightSummary != null) {
        currentWeight = (weightSummary['currentWeight'] as num?)?.toDouble() ?? 0.0;
        targetWeight = (weightSummary['targetWeight'] as num?)?.toDouble() ?? 0.0;
      }

      return DashboardSummary(
        caloriesConsumed: caloriesConsumed,
        caloriesTarget: caloriesTarget,
        proteinConsumed: proteinConsumed,
        proteinTarget: proteinTarget,
        carbConsumed: carbConsumed,
        carbTarget: carbTarget,
        fatConsumed: fatConsumed,
        fatTarget: fatTarget,
        waterConsumed: waterConsumed,
        waterGoal: waterGoal,
        currentWeight: currentWeight,
        targetWeight: targetWeight,
      );
    } catch (_) {
      return null;
    }
  }
}
