import '../models/moderation_item.dart';

/// Hợp đồng nguồn dữ liệu cho Moderation. Mock và Remote cùng implement.
abstract class ModerationDataSource {
  Future<List<ModerationItem>> getQueue();
  Future<List<ModerationItem>> getResolved();
  Future<void> updateStatus(String id, ModerationStatus status);
}

/// Nguồn dữ liệu GIẢ (mock) cho màn hình kiểm duyệt.
///
/// =====================  XÓA KHI CÓ API  =====================
/// Khi backend có dữ liệu report thật:
///   1. Đổi đăng ký trong `dependency_injection.dart` sang remote.
///   2. Xóa file này.
/// ============================================================
class ModerationMockDataSource implements ModerationDataSource {
  ModerationMockDataSource();

  static const _fakeDelay = Duration(milliseconds: 600);

  // Giữ trong bộ nhớ để Approve/Reject/Escalate chuyển item sang Resolved.
  List<ModerationItem>? _queue;
  List<ModerationItem>? _resolved;

  @override
  Future<List<ModerationItem>> getQueue() async {
    _queue ??= await _seedQueue();
    return List.unmodifiable(_queue!);
  }

  @override
  Future<List<ModerationItem>> getResolved() async {
    _resolved ??= await _seedResolved();
    return List.unmodifiable(_resolved!);
  }

  @override
  Future<void> updateStatus(String id, ModerationStatus status) async {
    await getQueue();
    await getResolved();
    final index = _queue!.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final updated = _queue!.removeAt(index).copyWith(status: status);
    _resolved!.insert(0, updated);
  }

  Future<List<ModerationItem>> _seedQueue() async {
    await Future.delayed(_fakeDelay);
    final now = DateTime.now();
    return [
      ModerationItem(
        id: "m1",
        flagType: ModerationFlagType.inaccurateDetection,
        reportedAt: now.subtract(const Duration(minutes: 2)),
        imageUrl: null,
        title: "Spaghetti dish",
        userHandle: "@HealthyEats99",
        content: "This is chicken, not salmon...",
      ),
      ModerationItem(
        id: "m2",
        flagType: ModerationFlagType.inappropriateAdvice,
        reportedAt: now.subtract(const Duration(minutes: 15)),
        title: "AI Coach reply",
        userHandle: "@FitnessJourney",
        content: "Feeling dizzy after 800 calories...",
      ),
      ModerationItem(
        id: "m3",
        flagType: ModerationFlagType.spam,
        reportedAt: now.subtract(const Duration(minutes: 42)),
        title: "Comment on meal log",
        userHandle: "@DealsBot",
        content: "Buy cheap supplements at this link...",
      ),
      ModerationItem(
        id: "m4",
        flagType: ModerationFlagType.inaccurateDetection,
        reportedAt: now.subtract(const Duration(hours: 1, minutes: 10)),
        title: "Fried rice bowl",
        userHandle: "@MealPrepKing",
        content: "Portion size looks way off, this is 2 servings...",
      ),
    ];
  }

  Future<List<ModerationItem>> _seedResolved() async {
    await Future.delayed(_fakeDelay);
    final now = DateTime.now();
    return [
      ModerationItem(
        id: "r1",
        flagType: ModerationFlagType.inappropriateAdvice,
        reportedAt: now.subtract(const Duration(hours: 3)),
        title: "AI Coach reply",
        userHandle: "@RunnerGirl",
        content: "Skipping meals to lose weight fast...",
        status: ModerationStatus.rejected,
      ),
      ModerationItem(
        id: "r2",
        flagType: ModerationFlagType.inaccurateDetection,
        reportedAt: now.subtract(const Duration(hours: 5)),
        title: "Pho bowl",
        userHandle: "@StreetFoodFan",
        content: "Detected as ramen but it's pho...",
        status: ModerationStatus.approved,
      ),
      ModerationItem(
        id: "r3",
        flagType: ModerationFlagType.spam,
        reportedAt: now.subtract(const Duration(days: 1)),
        title: "Profile bio",
        userHandle: "@PromoUser",
        content: "Promo codes spam...",
        status: ModerationStatus.escalated,
      ),
    ];
  }
}
