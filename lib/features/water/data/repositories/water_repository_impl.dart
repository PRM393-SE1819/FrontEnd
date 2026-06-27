import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/water_log.dart';
import '../../domain/entities/water_reminder.dart';
import '../../domain/entities/water_summary.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/water_remote_data_source.dart';
import '../models/water_reminder_model.dart';

class WaterRepositoryImpl implements WaterRepository {
  final WaterRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  WaterRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  Future<WaterSummary> getDailyWaterSummary(String date) async {
    return await remoteDataSource.getDailyWaterSummary(date);
  }

  @override
  Future<List<WaterLog>> getWaterLogHistory(String date) async {
    return await remoteDataSource.getWaterLogHistory(date);
  }

  @override
  Future<List<WaterReminder>> getWaterReminders() async {
    final rawReminders = await remoteDataSource.getWaterRemindersRaw();
    final List<WaterReminder> reminders = [];
    for (var item in rawReminders) {
      final remId = item['reminderId'] as int;
      final isEnabled = await getReminderEnabledState(remId);
      reminders.add(WaterReminderModel.fromJson(item, isEnabled: isEnabled));
    }
    return reminders;
  }

  @override
  Future<WaterLog?> addWaterLog(double amountML) async {
    return await remoteDataSource.addWaterLog(amountML);
  }

  @override
  Future<bool> deleteWaterLog(int logId) async {
    return await remoteDataSource.deleteWaterLog(logId);
  }

  @override
  Future<WaterSummary?> updateWaterGoal(double targetML) async {
    return await remoteDataSource.updateWaterGoal(targetML);
  }

  @override
  Future<WaterReminder?> createWaterReminder(String timeOnlyStr) async {
    final res = await remoteDataSource.createWaterReminder(timeOnlyStr);
    if (res != null) {
      final remId = res['reminderId'] as int;
      await saveReminderEnabledState(remId, true);
      return WaterReminderModel.fromJson(res, isEnabled: true);
    }
    return null;
  }

  @override
  Future<bool> deleteWaterReminder(int reminderId) async {
    return await remoteDataSource.deleteWaterReminder(reminderId);
  }

  @override
  Future<void> saveReminderEnabledState(int reminderId, bool isEnabled) async {
    await storage.write(key: 'reminder_${reminderId}_enabled', value: isEnabled.toString());
  }

  Future<bool> getReminderEnabledState(int reminderId) async {
    final val = await storage.read(key: 'reminder_${reminderId}_enabled');
    return val != 'false'; // Default to true if not found/set
  }
}
