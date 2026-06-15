import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_mock_data_source.dart';
import '../models/analytics_overview.dart';

/// Hiện thực [AnalyticsRepository] — ủy quyền cho [AnalyticsDataSource]
/// (mock hoặc remote, chọn ở DI).
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsDataSource dataSource;

  AnalyticsRepositoryImpl(this.dataSource);

  @override
  Future<AnalyticsOverview> getOverview() => dataSource.fetchOverview();
}
