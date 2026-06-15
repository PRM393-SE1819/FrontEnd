import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_mock_data_source.dart';
import '../models/system_alert.dart';

/// Hiện thực [AlertsRepository] bằng mock data source.
///
/// Khi nối API: thay [AlertsMockDataSource] bằng remote data source.
class AlertsRepositoryImpl implements AlertsRepository {
  final AlertsMockDataSource mockDataSource;

  AlertsRepositoryImpl(this.mockDataSource);

  @override
  Future<List<SystemAlert>> getAlerts() => mockDataSource.fetchAlerts();

  @override
  Future<void> dismissAlert(String id) => mockDataSource.dismiss(id);
}
