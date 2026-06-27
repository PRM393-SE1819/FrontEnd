import '../entities/water_log.dart';
import '../entities/water_reminder.dart';
import '../entities/water_summary.dart';

abstract class WaterRepository {
  Future<WaterSummary> getDailyWaterSummary(String date);
  Future<List<WaterLog>> getWaterLogHistory(String date);
  Future<List<WaterReminder>> getWaterReminders();
  Future<WaterLog?> addWaterLog(double amountML);
  Future<bool> deleteWaterLog(int logId);
  Future<WaterSummary?> updateWaterGoal(double targetML);
  Future<WaterReminder?> createWaterReminder(String timeOnlyStr);
  Future<bool> deleteWaterReminder(int reminderId);
  Future<void> saveReminderEnabledState(int reminderId, bool isEnabled);
}
