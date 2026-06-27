import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:project_fe/features/water/domain/entities/water_log.dart';
import 'package:project_fe/features/water/domain/entities/water_reminder.dart';
import 'package:project_fe/features/water/domain/entities/water_summary.dart';
import 'package:project_fe/features/water/domain/repositories/water_repository.dart';
import 'package:project_fe/features/water/presentation/cubit/water_cubit.dart';
import 'package:project_fe/features/water/presentation/cubit/water_state.dart';

class MockWaterRepository extends Mock implements WaterRepository {}

void main() {
  late MockWaterRepository mockWaterRepository;
  late WaterCubit waterCubit;

  setUp(() {
    mockWaterRepository = MockWaterRepository();
    waterCubit = WaterCubit(repository: mockWaterRepository);
  });

  tearDown(() {
    waterCubit.close();
  });

  group('WaterCubit Tests', () {
    final tDate = DateTime(2026, 6, 22);
    const tSummary = WaterSummary(consumedML: 1000.0, goalML: 2000.0);
    final tLogs = [
      WaterLog(waterLogId: 1, amountML: 250.0, loggedAt: DateTime(2026, 6, 22, 10, 0)),
    ];
    final tReminders = [
      const WaterReminder(reminderId: 1, reminderTime: '08:00', isEnabled: true),
    ];

    test('initial state is WaterInitial', () {
      expect(waterCubit.state, equals(WaterInitial()));
    });

    blocTest<WaterCubit, WaterState>(
      'emits [WaterLoading, WaterLoaded] when loadWaterData is successful',
      build: () {
        when(() => mockWaterRepository.getDailyWaterSummary(any()))
            .thenAnswer((_) async => tSummary);
        when(() => mockWaterRepository.getWaterLogHistory(any()))
            .thenAnswer((_) async => tLogs);
        when(() => mockWaterRepository.getWaterReminders())
            .thenAnswer((_) async => tReminders);
        return waterCubit;
      },
      act: (cubit) => cubit.loadWaterData(tDate),
      expect: () => [
        WaterLoading(),
        WaterLoaded(
          summary: tSummary,
          logs: tLogs,
          reminders: tReminders,
          selectedDate: tDate,
        ),
      ],
      verify: (_) {
        verify(() => mockWaterRepository.getDailyWaterSummary('2026-06-22')).called(1);
        verify(() => mockWaterRepository.getWaterLogHistory('2026-06-22')).called(1);
        verify(() => mockWaterRepository.getWaterReminders()).called(1);
      },
    );

    blocTest<WaterCubit, WaterState>(
      'emits [WaterLoading, WaterError] when loadWaterData fails',
      build: () {
        when(() => mockWaterRepository.getDailyWaterSummary(any()))
            .thenThrow(Exception('Database error'));
        when(() => mockWaterRepository.getWaterLogHistory(any()))
            .thenAnswer((_) async => tLogs);
        when(() => mockWaterRepository.getWaterReminders())
            .thenAnswer((_) async => tReminders);
        return waterCubit;
      },
      act: (cubit) => cubit.loadWaterData(tDate),
      expect: () => [
        WaterLoading(),
        isA<WaterError>(),
      ],
    );
  });
}
