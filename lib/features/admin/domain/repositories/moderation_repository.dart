import '../../data/models/moderation_item.dart';

/// Hợp đồng (interface) cho dữ liệu kiểm duyệt.
///
/// Hiện tại được hiện thực bằng mock data ([ModerationRepositoryImpl] dùng
/// mock data source). Khi có API thật, chỉ cần tạo một remote data source mới
/// và đổi trong DI — phần UI không phải sửa gì.
abstract class ModerationRepository {
  /// Các mục đang chờ xử lý (tab "Action Queue").
  Future<List<ModerationItem>> getQueue();

  /// Các mục đã xử lý xong (tab "Resolved").
  Future<List<ModerationItem>> getResolved();

  /// Cập nhật trạng thái một mục (Approve / Reject / Escalate).
  Future<void> updateStatus(String id, ModerationStatus status);
}
