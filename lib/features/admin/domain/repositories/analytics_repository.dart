import '../../data/models/analytics_overview.dart';

/// Hợp đồng (interface) cho dữ liệu Analytics Overview.
///
/// Được hiện thực bởi [AnalyticsRepositoryImpl] (gọi API thật).
abstract class AnalyticsRepository {
  Future<AnalyticsOverview> getOverview();
}
