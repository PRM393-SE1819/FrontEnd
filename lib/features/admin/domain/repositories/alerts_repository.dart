import '../../data/models/system_alert.dart';

/// Hợp đồng (interface) cho dữ liệu System Alerts.
///
/// Hiện được hiện thực bằng mock data. Khi có API thật, tạo remote data source
/// mới và đổi trong DI — phần UI không phải sửa.
abstract class AlertsRepository {
  Future<List<SystemAlert>> getAlerts();

  /// Bỏ qua một cảnh báo (xóa khỏi danh sách).
  Future<void> dismissAlert(String id);
}
