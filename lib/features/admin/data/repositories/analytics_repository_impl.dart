import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_data_source.dart';
import '../models/analytics_overview.dart';

/// Hiện thực [AnalyticsRepository] — ủy quyền cho [AnalyticsRemoteDataSource].
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;

  AnalyticsRepositoryImpl(this.remoteDataSource);

  @override
  Future<AnalyticsOverview> getOverview() => remoteDataSource.fetchOverview();
}
