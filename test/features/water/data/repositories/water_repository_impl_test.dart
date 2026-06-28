import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project_fe/features/water/data/datasources/water_remote_data_source.dart';
import 'package:project_fe/features/water/data/models/water_log_model.dart';
import 'package:project_fe/features/water/data/models/water_summary_model.dart';
import 'package:project_fe/features/water/data/repositories/water_repository_impl.dart';

class MockWaterRemoteDataSource extends Mock implements WaterRemoteDataSource {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late WaterRepositoryImpl repository;
  late MockWaterRemoteDataSource mockRemoteDataSource;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockRemoteDataSource = MockWaterRemoteDataSource();
    mockSecureStorage = MockFlutterSecureStorage();
    repository = WaterRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      storage: mockSecureStorage,
    );
  });

  group('getWaterLogHistory', () {
    test('filters logs locally by selected date matching local timezone', () async {
      // Arrange - Construct local times explicitly (no Z suffix) so they parse to host local timezone
      final logs = [
        WaterLogModel(waterLogId: 1, amountML: 250, loggedAt: DateTime.parse("2026-06-29 00:43:19.761")),
        WaterLogModel(waterLogId: 2, amountML: 500, loggedAt: DateTime.parse("2026-06-28 23:00:00.000")),
      ];
      
      when(() => mockRemoteDataSource.getWaterLogHistory("")).thenAnswer((_) async => logs);

      // Act
      final result = await repository.getWaterLogHistory("2026-06-29");

      // Assert
      expect(result.length, 1);
      expect(result.first.waterLogId, 1);
      expect(result.first.amountML, 250);
    });
  });

  group('getDailyWaterSummary', () {
    test('calculates consumedML locally based on filtered logs', () async {
      // Arrange
      final logs = [
        WaterLogModel(waterLogId: 1, amountML: 250, loggedAt: DateTime.parse("2026-06-29 00:43:19.761")),
        WaterLogModel(waterLogId: 2, amountML: 500, loggedAt: DateTime.parse("2026-06-28 23:00:00.000")),
      ];
      
      when(() => mockRemoteDataSource.getWaterLogHistory("")).thenAnswer((_) async => logs);
      when(() => mockRemoteDataSource.getDailyWaterSummary("2026-06-29"))
          .thenAnswer((_) async => const WaterSummaryModel(consumedML: 0, goalML: 2000));

      // Act
      final result = await repository.getDailyWaterSummary("2026-06-29");

      // Assert
      expect(result.consumedML, 250); // locally calculated
      expect(result.goalML, 2000); // from server
    });
  });
}
