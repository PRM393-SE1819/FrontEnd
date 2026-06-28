import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/water_log.dart';
import '../../domain/entities/water_reminder.dart';
import '../../domain/entities/water_summary.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/water_remote_data_source.dart';
import '../models/water_log_model.dart';
import '../models/water_reminder_model.dart';
import '../models/water_summary_model.dart';

class WaterRepositoryImpl implements WaterRepository {
  final WaterRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  WaterRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  Future<WaterSummary> getDailyWaterSummary(String date) async {
    // 1. Fetch the server daily summary to get the correct goalML
    final serverSummary = await remoteDataSource.getDailyWaterSummary(date);
    
    // 2. Fetch the locally filtered logs to calculate correct consumedML
    final logs = await getWaterLogHistory(date);
    final consumedML = logs.fold<double>(0.0, (sum, log) => sum + log.amountML);

    return WaterSummaryModel(
      consumedML: consumedML,
      goalML: serverSummary.goalML,
    );
  }

  @override
  Future<List<WaterLog>> getWaterLogHistory(String date) async {
    final selectedDate = DateTime.parse(date);
    final yesterdayDate = selectedDate.subtract(const Duration(days: 1));
    final tomorrowDate = selectedDate.add(const Duration(days: 1));

    final dateStr = selectedDate.toIso8601String().substring(0, 10);
    final yesterdayStr = yesterdayDate.toIso8601String().substring(0, 10);
    final tomorrowStr = tomorrowDate.toIso8601String().substring(0, 10);

    List<WaterLogModel> logsToday = [];
    List<WaterLogModel> logsYesterday = [];
    List<WaterLogModel> logsTomorrow = [];
    List<WaterLogModel> logsAll = [];

    try {
      logsToday = await remoteDataSource.getWaterLogHistory(dateStr);
    } catch (_) {}
    try {
      logsYesterday = await remoteDataSource.getWaterLogHistory(yesterdayStr);
    } catch (_) {}
    try {
      logsTomorrow = await remoteDataSource.getWaterLogHistory(tomorrowStr);
    } catch (_) {}
    try {
      logsAll = await remoteDataSource.getWaterLogHistory("");
    } catch (_) {}

    final Map<int, WaterLog> uniqueLogs = {};

    void addMatchingLogs(List<WaterLogModel> logs) {
      for (final log in logs) {
        final localTime = log.loggedAt;
        if (localTime.year == selectedDate.year &&
            localTime.month == selectedDate.month &&
            localTime.day == selectedDate.day) {
          uniqueLogs[log.waterLogId] = log;
        }
      }
    }

    addMatchingLogs(logsToday);
    addMatchingLogs(logsYesterday);
    addMatchingLogs(logsTomorrow);
    addMatchingLogs(logsAll);

    final sortedLogs = uniqueLogs.values.toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return sortedLogs;
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
