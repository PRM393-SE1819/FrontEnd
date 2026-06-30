import '../../data/models/moderation_item.dart';

/// Hợp đồng (interface) cho dữ liệu kiểm duyệt.
///
/// Được hiện thực bởi [ModerationRepositoryImpl] (gọi API qua remote data
/// source). Phần UI chỉ phụ thuộc vào interface này.
abstract class ModerationRepository {
  /// Các mục đang chờ xử lý (tab "Action Queue").
  Future<List<ModerationItem>> getQueue();

  /// Các mục đã xử lý xong (tab "Resolved").
  Future<List<ModerationItem>> getResolved();

  /// Cập nhật trạng thái một mục (Approve / Reject / Escalate).
  Future<void> updateStatus(String id, ModerationStatus status);
}
