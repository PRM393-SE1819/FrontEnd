import '../../data/models/analytics_overview.dart';

/// Hợp đồng (interface) cho dữ liệu Analytics Overview.
///
/// Hiện được hiện thực bằng mock data. Khi có API thật, tạo remote data source
/// mới và đổi trong DI — phần UI không phải sửa.
abstract class AnalyticsRepository {
  Future<AnalyticsOverview> getOverview();
}
